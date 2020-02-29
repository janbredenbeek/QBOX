#include "qsetup_h"

static char *fnam_opt[] = {"    System directory ",
                           "   Inbound directory ",
                           "  Outbound directory ",
                           " Temp. Msg directory ",
                           "   Remote server log ",
                           "    Local server log ",
                           "   QSPIL driver name ",
                           "Local message editor ",
                           "   Terminal emulator ",
                           "      Fax processing ",
                           "          After user "};

static char *fnam_hlp[] = {"Where the system files are stored",
                           "Where incoming network files are stored",
                           "Where outgoing network files are stored",
                           "Used for external message editor workfile",
                           "Logfile for remote logons",
                           "Logfile for local logons",
                           "Filename (NOT directory) of QSPIL driver",
                           "Local message editor ('%W' inserts filename)",
                           "Terminal emulator for local logon or chat",
                           "Program for processing of incoming FAX calls",
                           "Program executed after user logoff"};

void act_filenames(struct _wdef *w, int item, int flag)
{
   void *p;
   int maxlen, extra;

   if (flag > 0) 
   {
      sd_pos(w->chid, -1, 1, 13);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs(fnam_hlp[item], w->fp);
   }
   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->sink);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->sstrip);
   fputs(fnam_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item) {
   case 0: p = (struct QLSTR *) setup.sysdir;
           maxlen = MAXPATH - 2;
           break;
   case 1: p = (struct QLSTR *) setup.inbound;
           maxlen = MAXPATH - 2;
           break;
   case 2: p = (struct QLSTR *) setup.outbound;
           maxlen = MAXPATH - 2;
           break;
   case 3: p = (struct QLSTR *) setup.msgtmp;
           maxlen = MAXFNAME - 2;
           break;
   case 4: p = (struct QLSTR *) setup.log1;
           maxlen = MAXFNAME - 2;
           break;
   case 5: p = (struct QLSTR *) setup.log2;
           maxlen = MAXFNAME - 2;
           break;
   case 6: p = (struct QLSTR *) setup.qspil;
           maxlen = 20;
           break;
   case 7: p = (char *)setup.editor;
           maxlen = MAXFNAME - 1;
           break;
   case 8: p = (char *)setup.terminal;
           maxlen = MAXFNAME - 1;
           break;
   case 9: p = (char *)setup.faxprog;
           maxlen = MAXFNAME - 1;
           break;
   case 10: p = (char *)setup.afteruser;
            maxlen = MAXFNAME - 1;
            break;
   }
   if (flag == I_ACTION) 
   {
      if (item <= 6)
         qlstr_to_c(p, p);
      w_edstr(w, 23, item + 1, maxlen, p);
      if (item != 6 && !isdevice(p, &extra)) {
         sd_pos(w->chid, -1, 1, 13);
         sd_setpa(w->chid, -1, w->sstrip);
         sd_setst(w->chid, -1, w->sstrip);
         sd_setin(w->chid, -1, w->sink);
         sd_clrln(w->chid, -1);
         fputs("Unable to locate directory!", w->fp);
      }
      if (item <= 6)
         cstr_to_ql(p, p);
   }
   else 
      if (item <= 6)
         io_sstrg(w->chid, -1, ((struct QLSTR *)p)->qs_str, 
            ((struct QLSTR *)p)->qs_strlen);
      else
         fputs(p, w->fp);
}


void do_filenames(void)
{
   struct _wdef *w;

   w = w_open(418, 152, 46, 44, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_filenames;
   w->n_items = w->w_items = 11;
   w_setup(w, 116, 2, 7, " Filenames ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

