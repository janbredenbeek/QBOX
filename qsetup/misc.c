#include "qsetup_h"

static char *misc_opt[] = {
   "               System name ",
   "                SysOp name ",
   "              Session mode ",
   "           Local mode only ",
   "              'Yell' alarm ",
   "                Start time ",
   "                  End time ",
   "Area for messages to SysOp ",
   "    SEAlink receive buffer ",
   "Transmit SEAlink Overdrive ",
   " Receive SEAlink Overdrive "
};

static char *misc_hlp[] = {
   "Name of your Bulletin Board System",
   "Name of System Operator",
   "Whether QBOX allows mail calls, BBS calls or both",
   "If 'YES', QBOX starts up as if '-L' switch was given",
   "If 'YES', QBOX sounds alarm during [Y]ell command",
   "Start time for Yell alarm if enabled",
   "End time for Yell alarm if enabled",
   "Number of area for leaving comments etc. (0 = disabled)",
   "Buffer for 'slow' storage media (e.g. flp)",
   "Use 'ACKless' SEAlink when sending files",
   "Use 'ACKless' SEAlink when receiving files"
};

static char *mmodes[] = {"Mail and BBS", "Mail Only", "BBS Only"};
static char *bufsizes[] = {"None", "8K  ", "32K "};

void act_misc(struct _wdef *w, int item, int flag)
{
   struct QLSTR *qs;
   char temp[50];
   unsigned char *ptr;

   if (flag == I_SELECT) {
      sd_pos(w->chid, -1, 1, 13);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs(misc_hlp[item], w->fp);
   }
   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->sink);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->sstrip);
   fputs(misc_opt[item], w->fp);
   if (flag == I_DESEL) return;
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item) {
   case 0:
      qs = (struct QLSTR *) setup.sysname;
      goto misc_names;
   case 1:
      qs = (struct QLSTR *) setup.sysop;
misc_names:
      if (flag == I_ACTION) {
         qlstr_to_c(temp, qs);
         w_edstr(w, 29, 1 + item, 35, temp);
         cstr_to_ql(qs, temp);
      }
      else io_sstrg(w->chid, -1, qs->qs_str, qs->qs_strlen);
      break;
   case 2:
      if (flag == I_ACTION) 
      {
         if (++setup.mailmode > BBS_ONLY) setup.mailmode = 0;
         sd_setpa(w->chid, -1, w->strip);
         sd_clrrt(w->chid, -1);
      }
      fputs(mmodes[setup.mailmode], w->fp);
      break;
   case 3:
      ptr = &setup.local_only;
      goto misc_flags;
   case 4:
      ptr = &setup.yellflag;
misc_flags:
      if (flag == I_ACTION)
         *ptr = !*ptr;
      fputs(*ptr ? "Yes" : "No ", w->fp);
      break;
   case 5: case 6:
      if (flag == I_ACTION)
         w_edit(w, 29, 1 + item, 5, (item == 5) ? &setup.yell_start : &setup.yell_end,
            (void (*)(char *, void *))time_to_asc,
            (int (*)(void *, char *))asc_to_time);
      else {
         time_to_asc(temp, (item == 5) ? &setup.yell_start : &setup.yell_end);
         fputs(temp, w->fp);
      }
      break;
   case 7:
      if (flag == I_ACTION) {
         do {
            sprintf(temp, "%hu", setup.sysopmsg);
            w_edstr(w, 29, 1 + item, 5, temp);
            setup.sysopmsg = atoi(temp);
         } while (setup.sysopmsg > 255);
      }
      else fprintf(w->fp, "%hu", setup.sysopmsg);
      break;
   case 8:
      if (flag == I_ACTION)
         setup.s_bufsize = (setup.s_bufsize == 1) ? -1 : ++setup.s_bufsize;
      fputs(bufsizes[setup.s_bufsize + 1], w->fp);
      break;
   case 9: case 10:
      ptr = (item == 9) ? &setup.s_txslo : &setup.s_rxslo;
      if (flag == I_ACTION)
         *ptr = !*ptr;
      fputs(*ptr ? "Enabled " : "Disabled", w->fp);
      break;
   }
}

void do_misc(void)
{
   struct _wdef *w;

   w = w_open(394, 152, 58, 44, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_misc;
   w->n_items = w->w_items = 11;
   w_setup(w, 116, 2, 7, " Miscellaneous ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

