/* QSPHAYES Setup program */

#include "qsetup_h"
#include "qspsetup_h"

static struct _qspdata qspdata;

static int fd;

static int getqspdata(void)
{
   int i;
   char *p;
   struct _wdef *w;
   char qspilf[38];

   qlstr_to_c(qspilf, (struct QLSTR *)setup.sysdir);
   qlstr_to_c(&qspilf[strlen(qspilf)], (struct QLSTR *)setup.qspil);
   if ((fd = open(qspilf, O_RDWR)) < 0)
   {
      error("QSPIL driver not found (check 'Filenames' menu)");
      return -1;
   }
   if (read(fd, &qspdata, sizeof(qspdata)) < 0)
   {
      error("Error reading QSPIL configuration data!");
      close(fd);
      return -1;
   }
   if (qspdata.id != QSP_ID || qspdata.cfglvl != REVLVL)
   {
      error("Incorrect version of QSPHAYES!");
      return -1;
   }
   return 0;
}

static struct simple_item i_savechanges[] = 
{
   1, 2, "      Yes     ",
   1, 3, "      No      ",
   1, 4, " Return (ESC) "
};

static void putqspdata(void)
{
   lseek(fd, 0L, SEEK_START);
   if (write(fd, &qspdata, sizeof(qspdata)) != sizeof(qspdata))
      error("Writing new QSPHAYES setup failed!");
}

static char *qsp_opt[] =
{
   "                Port ",
   "           Baud Rate ",
   "         Baud Locked ",
   "     Character delay ",
   " Modem response time ",
   " Rings before answer ",
   "   Modem Commands  > ",
   "   Modem Responses > ",
   "        Quit         "
};

static char *qsp_hlp[] =
{
   "Name of serial device",
   "QL-to-modem communication speed",
   "Use 'YES' for high-speed buffered modems",
   "Delay (1/50s) between modem command characters",
   "Wait time for dial/answer response from modem",
   "Number of RINGs before modem answers phone",
   "Define commands sent to modem",
   "Define modem response strings",
   ""
};

static char *command_opt[] =
{
   "       Init-1 ",
   "       Init-2 ",
   "       Init-3 ",
   "       Answer ",
   "       Hangup ",
   "      Offline ",
   "     Dial 300 ",
   " Dial 1200/75 ",
   "    Dial 1200 ",
   "    Dial 2400 ",
   "    Dial 4800 ",
   "    Dial 9600 ",
   "   Dial 19200 ",
   "   Dial 38400 ",
   "    Dial 7200 ",
   "   Dial 12000 ",
   "   Dial 14400 ",
   "   Dial 16800 ",
   "   Dial 21600 ",
   "   Dial 24000 ",
   "   Dial 26400 ",
   "   Dial 28800 ",
   "  Dial prefix ",
   "  Dial suffix "
};

static char *connect_opt[] =
{
   "              OK ",
   "      No Carrier ",
   "            Busy ",
   "     No Dialtone ",
   "            Ring ",
   "         Ringing ",
   "     Connect 300 ",
   " Connect 1200/75 ",
   "    Connect 1200 ",
   "    Connect 2400 ",
   "    Connect 4800 ",
   "    Connect 9600 ",
   "   Connect 19200 ",
   "   Connect 38400 ",
   "    Connect 7200 ",
   "   Connect 12000 ",
   "   Connect 14400 ",
   "   Connect 16800 ",
   "   Connect 21600 ",
   "   Connect 24000 ",
   "   Connect 26400 ",
   "   Connect 28800 ",
   "     Connect Fax ",
   "   Error Control ",
};

static void act_mdmcmd(struct _wdef *w, int item, int flag)
{
   char *p;

   sd_pos(w->chid, -1, 1, item - w->t_item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : 4);
   fputs(command_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   p = qspdata.init[0] + 50 * item;
   if (flag == I_ACTION)
      w_edstr(w, 16, item - w->t_item, 49, p);
   else
      fputs(p, w->fp);
}

static void act_mdmresp(struct _wdef *w, int item, int flag)
{
   char *p;
   int maxlen;

   sd_pos(w->chid, -1, 1, item - w->t_item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : 4);
   fputs(connect_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   p = qspdata.okmsg + 32 * item;
   maxlen = (item == 23) ? 15 : 31;
   if (flag == I_ACTION)
      w_edstr(w, 19, item - w->t_item, maxlen, p);
   else
      fputs(p, w->fp);
}

static void clear_arrow_up(struct _wdef *w)
{
   sd_pos(w->chid, -1, 0, 0);
   io_sbyte(w->chid, -1, ' ');
}

static void clear_arrow_down(struct _wdef *w)
{
   sd_pos(w->chid, -1, 0, 13);
   io_sbyte(w->chid, -1, ' ');
}

static void browse(struct _wdef *w)
{
   char c;

   while (1)
   {
      if (w->t_item)
      {
         sd_pos(w->chid, -1, 0, 0);
         io_sbyte(w->chid, -1, '¾');
      }
      if (w->t_item + w->w_items < w->n_items)
      {
         sd_pos(w->chid, -1, 0, 13);
         io_sbyte(w->chid, -1, '¿');
      }
      io_fbyte(w->chid, -1, &c);
      switch (c)
      {
      case '\x1B': return;
      case '\n': case ' ':
         (*w->action)(w, w->c_item, I_ACTION);
         break;
      case UP:
         clear_arrow_up(w);
         w_up(w); 
         break;
      case DOWN:
         clear_arrow_down(w);
         w_down(w); 
         break;
/*
      case ALT|UP: case SHIFT|UP:
         clear_arrow_up(w);
         w_pgup(w); 
         break;
      case ALT|DOWN: case SHIFT|DOWN:
         clear_arrow_down(w);
         w_pgdn(w); 
         break;
*/
      case ALT|LEFT: w_home(w); break;
      case ALT|RIGHT: w_end(w); break;
      }
   }
}

static void do_mdmcmd(void)
{
   struct _wdef *w;

   w = w_open(400, 152, 56, 44, W_ETRAP);
   w->action = act_mdmcmd;
   w->n_items = 24;
   w->w_items = 14;
   w_setup(w, 116, 2, 7, " Modem Commands ");
   browse(w);
   w_close(w);
}

static void do_mdmresp(void)
{
   struct _wdef *w;

   w = w_open(310, 152, 100, 44, W_ETRAP);
   w->action = act_mdmresp;
   w->n_items = 24;
   w->w_items = 14;
   w_setup(w, 116, 2, 7, " Modem Responses ");
   browse(w);
   w_close(w);
}

static char select[] = {'\n', 0x1B, 0x20, UP, DOWN, ALT|LEFT, ALT|RIGHT, NULL};

static void timeout_pre(char *buf, short *p)
{
   sprintf(buf, "%hd", *p / 50);
}

static void ushort_pre(char *buf, unsigned short *p)
{
   sprintf(buf, "%hu", *p);
}

static int timeout_post(short *p, char *buf)
{
   *p = (short) atoi(buf) * 50;
   if (*p < 0) *p = -1;
   return 0;
}

static int ushort_post(unsigned short *p, char *buf)
{
   *p = (unsigned short) atoi(buf);
   return 0;
}

static void act_modem(struct _wdef *w, int item, int flag)
{
   char temp[32];
   unsigned short int *i;

   if (flag > I_DRAW)
   {
      sd_pos(w->chid, -1, 1, 11);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs(qsp_hlp[item], w->fp);
   }
   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : 4);
   fputs(qsp_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item)
   {
   case 0: /* Port */
      qlstr_to_c(temp, (struct QLSTR *)qspdata.port);
      if (flag == I_ACTION)
      {
         w_edstr(w, 23, 1 + item, 30, temp);
         cstr_to_ql((struct QLSTR *)qspdata.port, temp);
      }
      else 
         fputs(temp, w->fp);
      break;
   case 1: /* Baud rate */
      i = &qspdata.baud;
      goto do_int;
   case 3: /* character delay */
      i = &qspdata.delay;
      goto do_int;
   case 5: /* Rings */
      i = &qspdata.rings;
do_int:
      if (flag == I_ACTION)
         w_edit(w, 23, 1 + item, 5, i, 
         (void (*)(char *, void *))ushort_pre,
         (int (*)(void *, char *))ushort_post);
      else
         fprintf(w->fp, "%hu", (short) *i);
      break;
   case 2: /* Baud Locked */
      if (flag == I_ACTION)
         qspdata.locked = !qspdata.locked;
      fputs(qspdata.locked ? "YES" : "NO ", w->fp);
      break;
   case 4: /* Modem response timeout */
      if (flag == I_ACTION)
         w_edit(w, 23, 1 + item, 3, &qspdata.timeout, 
         (void (*)(char *, void *))timeout_pre,
         (int (*)(void *, char *))timeout_post);
      else
         fprintf(w->fp, "%d", (int) qspdata.timeout / 50);
      break;
   case 6: /* Modem Commands */
      if (flag == I_ACTION) 
         do_mdmcmd();
      break;
   case 7: /* Modem Responses */
      if (flag == I_ACTION)
         do_mdmresp();
      break;
   }
}

void do_modem(void)
{
   struct _wdef *w;
   char c;

   if (getqspdata() != 0) return;
   w = w_open(328, 132, 92, 54, W_ETRAP);
   w->action = act_modem;
   w->n_items = w->w_items = 9;
   w_setup(w, 116, 2, 7, " Modem ");
   while (1) 
   {
      io_fbyte(w->chid, -1, &c);
      if (!strchr(select, c)) continue;
      if (c == 0x1B || ((c == '\n' || c == ' ') && w->c_item == 8))
      {
         c = savechanges();
         if (c == 0x1B) continue;
         if (c == 'y') putqspdata();
         break;
      }
      switch (c)
      {
         case UP: w_prev(w); break;
         case DOWN: w_next(w); break;
         case ALT|LEFT: w_home(w); break;
         case ALT|RIGHT: w_end(w); break;
         case '\n': case ' ':
            act_modem(w, w->c_item, I_ACTION); break;
      }
   }
   w_close(w);
   close(fd);
}


