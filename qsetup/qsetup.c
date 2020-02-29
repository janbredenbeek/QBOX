#include "qsetup_h"

/* #define skipspc(p) while(isspace(*p)) p++; */

char _prog_name[] = "QSETUP";

void (*_consetup)() = NULL;
char *_endmsg = NULL;

struct _setup setup;

char path[17] = "\0";

struct simple_item i_main[] = {
   1, 1, "   Filenames   ",
   1, 2, "Network Mailer ",
   1, 3, "     Users     ",
   1, 4, " Miscellaneous ",
   1, 5, "     Quit      "};

void error(char *msg)
{
   int ww;
   struct _wdef *w;
   char c;

   ww = (strlen(msg) + 2) * 6 + 4;
   if (ww < 172) ww = 172;
   w = w_open(ww, 62, (512 - ww) / 2, 104, W_ETRAP);
   w->paper = w->strip = 210;
   w->bcolour = 2;
   w_setup(w, 2, 2, 7, "ERROR");
   sd_pos(w->chid, -1, 1, 1);
   fputs(msg, w->fp);
   sd_pos(w->chid, -1, 1, 3);
   fputs("Press any key to continue ", w->fp);
   sd_cure(w->chid, -1);
   io_fbyte(w->chid, -1, &c);
   sd_curs(w->chid, -1);
   w_close(w);
}

int getsetup(void)
{
   char sfile[50], temp[50];
   char c;
   char *p;
   int i, fd, extra;
   struct _wdef *w;

   if (!*path) {
      p = getenv("QBOX");
      if (p)
         strcpy(path, p);
      else
         getcwd(path, 24);
   }
   if (!isdevice(path, &extra)) {
      *path = '\0';
      w = w_open(286, 32, 113, 104, W_ETRAP);
      w->paper = w->strip = 210;
      w->estrip = 0;
      w_setup(w, 0, 0, 0, NULL);
      sd_pos(w->chid, -1, 1, 1);
      fputs("Enter QBOX system directory: ", w->fp);
      while (1) {
         if ((i = w_edstr(w, 30, 1, 16, path)) < 0 || i == 0x1B) return -1;
         if (isdevice(path, &extra)) break;
         sd_pos(w->chid, -1, 1, 0);
         sd_clrln(w->chid, -1);
         fprintf(w->fp, "'%s' is not a valid directory", path);
      }
      w_close(w);
   }
   strcpy(sfile, path);
   strcat(sfile, "SETUP_BBS");
   if ((fd = open(sfile, O_RDONLY)) < 0) {
      if (_oserr != ERR_NF) {
         error("Unable to open setup file!");
         return -1;
      }
      w = w_open(280, 32, 116, 104, W_ETRAP);
      w->paper = w->strip = 2;
      w_setup(w, 0, 0, 0, NULL);
      sd_pos(w->chid, -1, 1, 1);
      fputs("Setup file not found, create it? (Y/N/Esc) ", w->fp);
      sd_cure(w->chid, -1);
      do {
         io_fbyte(w->chid, -1, &c);
         c = tolower(c);
      } while (c != 0x1B && c != 'y' && c != 'n');
      sd_curs(w->chid, -1);
      w_close(w);
      if (c != 'y') return -1;
      if ((fd = creat(sfile, 0)) < 0) {
         error("Unable to create setup file!");
         return -1;
      }
      memset(&setup, 0, sizeof(setup));
      setup.fingerprint = SET_FPRINT;
      setup.thisrev = THISREV;
      setup.comprev = COMPREV;
      setup.totlen = sizeof(setup);
      cstr_to_ql((struct QLSTR *)setup.sysdir, path);
      strcpy(temp, path);
      strcat(temp, "IN_");
      cstr_to_ql((struct QLSTR *)setup.inbound, temp);
      strcpy(temp, path);
      strcat(temp, "OUT_");
      cstr_to_ql((struct QLSTR *)setup.outbound, temp);
      cstr_to_ql((struct QLSTR *)setup.msgtmp, "ram1_");
      cstr_to_ql((struct QLSTR *)setup.qspil, "QSPHAYES");
      cstr_to_ql((struct QLSTR *)setup.log1, "ram1_qbox_log");
      cstr_to_ql((struct QLSTR *)setup.log2, "ram1_qbox2_log");
      cstr_to_ql((struct QLSTR *)setup.editor, "flp1_QED");
      cstr_to_ql((struct QLSTR *)setup.terminal, "flp1_QLTERM");
      cstr_to_ql((struct QLSTR *)setup.sysop, "Sysop");
      setup.init_sec = DISGRACE;
      setup.init_mgroups = 0;
      setup.init_fgroups = 0;
      setup.logintime[0] = 10;
      setup.logintime[1] = 20;
      setup.logintime[2] = 30;
      for (i = 3; i < 10; i++) setup.logintime[i] = 60;
      setup.sysopmsg = 0;
      write(fd, &setup, sizeof(setup));
      close(fd);
   }
   else {
      if (read(fd, &setup, sizeof(setup)) < 0) {
         error("Error reading setup file!");
         close(fd);
         return -1;
      }
      close(fd);
      if (setup.fingerprint != SET_FPRINT) {
         error("Setup file is corrupted!");
         return -1;
      }
      if (setup.comprev != COMPREV) {
         error("Setup file version is incompatible!");
         return -1;
      }
   }
   return 0;
}

char savechanges(void)
{
   struct _wdef *w;
   char ret;

   w = w_open(166, 30, 173, 104, W_ETRAP);
   w->paper = w->strip = 2;
   w_setup(w, 0, 0, 0, NULL);
   sd_pos(w->chid, -1, 1, 1);
   fputs("Save changes? (Y/N/Esc) ", w->fp);
   sd_cure(w->chid, -1);
   do {
      io_fbyte(w->chid, -1, &ret);
      ret = tolower(ret);
   } while (ret != 'y' && ret != 'n' && ret != 0x1B);
   sd_curs(w->chid, -1);
   w_close(w);
   return ret;
}

void putsetup(void)
{
   int fd;
   char name[50], oldname[50];

   strcpy(name, path);
   strcat(name, "SETUP_BBS");
   strcpy(oldname, name);
   strcat(oldname, "_OLD");
   unlink(oldname);
   rename(name, oldname);
   if ((fd = creat(name, 0)) < 0) {
      error("Unable to save setup file!");
      return;
   }
   if (write(fd, &setup, sizeof(setup)) != sizeof(setup)) {
      error("Writing new setup file failed (disk full?)");
      close(fd);
      unlink(name);
      return;
   }
   close(fd);
}

char *fnam_opt[] = {"    System directory:",
                    "   Inbound directory:",
                    "  Outbound directory:",
                    " Temp. Msg directory:",
                    "   Remote server log:",
                    "    Local server log:",
                    "Local message editor:",
                    "   Terminal emulator:",
                    "   QSPIL driver name:"};

char *fnam_hlp[] = {"Where the system files are stored",
                    "Where incoming network files are stored",
                    "Where outgoing network files are stored",
                    "Used for external message editor workfile",
                    "Logfile for remote logons",
                    "Logfile for local logons",
                    "Full filename of text editor for local messages",
                    "Full filename of terminal emulator (local & chat)",
                    "Filename (NOT directory) of QSPIL driver"};

void act_filenames(struct _wdef *w, int item, int flag)
{
   struct QLSTR *qs;
   char temp[50];
   int maxlen, extra;

   if (flag > 0) {
      sd_pos(w->chid, -1, 1, 11);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs(fnam_hlp[item], w->fp);
   }
   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->ink);
   fputs(fnam_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item) {
   case 0: qs = (struct QLSTR *) setup.sysdir;
           maxlen = MAXPATH - 2;
           break;
   case 1: qs = (struct QLSTR *) setup.inbound;
           maxlen = MAXPATH - 2;
           break;
   case 2: qs = (struct QLSTR *) setup.outbound;
           maxlen = MAXPATH - 2;
           break;
   case 3: qs = (struct QLSTR *) setup.msgtmp;
           maxlen = MAXFNAME - 2;
           break;
   case 4: qs = (struct QLSTR *) setup.log1;
           maxlen = MAXFNAME - 2;
           break;
   case 5: qs = (struct QLSTR *) setup.log2;
           maxlen = MAXFNAME - 2;
           break;
   case 6: qs = (struct QLSTR *) setup.editor;
           maxlen = MAXFNAME - 2;
           break;
   case 7: qs = (struct QLSTR *) setup.terminal;
           maxlen = MAXFNAME - 2;
           break;
   case 8: qs = (struct QLSTR *) setup.qspil;
           maxlen = 20;
           break;
   }
   if (flag == I_ACTION) {
      qlstr_to_c(temp, qs);
      w_edstr(w, 23, item + 1, maxlen, temp);
      if (item != 8 && !isdevice(temp, &extra)) {
         sd_pos(w->chid, -1, 1, 11);
         sd_setpa(w->chid, -1, w->sstrip);
         sd_setst(w->chid, -1, w->sstrip);
         sd_setin(w->chid, -1, w->sink);
         sd_clrln(w->chid, -1);
         fputs("Unable to locate directory!", w->fp);
      }
      cstr_to_ql(qs, temp);
   }
   else io_sstrg(w->chid, -1, qs->qs_str, qs->qs_strlen);
}


void do_filenames(void)
{
   struct _wdef *w;

   w = w_open(412, 132, 50, 64, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_filenames;
   w->n_items = w->w_items = 9;
   w_setup(w, 116, 2, 7, " Filenames ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

void time_to_asc(char *buf, unsigned short *val)
{
   sprintf(buf, "%2d:%02d", *val / 60, *val % 60);
}

int asc_to_time(unsigned short *ret, char *buf)
{
   int h, m;

   if (strchr(buf, ':')) {
      if (sscanf(buf, "%d:%d", &h, &m) != 2) return -1;
   }
   else {
      m = atoi(buf);
      h = m / 100; m %= 100;
   }
   if (h < 0 || h > 23 || m < 0 || m > 59) return -1;
   *ret = h * 60 + m;
   return 0;
}

void addr_to_asc(char *buf, ADDRESS *addr)
{
   if (!addr->net) {
      *buf = '\0';
      return;
   }
   sprintf(buf, "%u:%u/%u.%u", addr->zone, addr->net, addr->node, addr->point);
}

int readnum(char **pp)
{
   int ret;
   char *p;

   p = *pp;
   ret = (int) strtoul(p, pp, 10);
   return (p == *pp) ? -1 : ret;
}

/* Read network address (may be incomplete)
   Returns 0 if OK, -1 if syntax error */

int asc_to_addr(ADDRESS *addr, char *p)
{
   int ret;

   skipspc(p);
   if (!*p) {
      memset(addr, 0, sizeof(ADDRESS));
      return 0;
   }
   if (*p == '.') goto readpoint; /* short point form */

   if ((ret = readnum(&p)) < 0) return ret;
   if (*p == ':') {  /* number was zone number */
      p++;
      addr->zone = ret;
      if ((ret = readnum(&p)) < 0) return ret;
      if (*p != '/') return -1;
   }
   if (*p == '/') {  /* number was net number */
      p++;
      addr->net = ret;
      if ((ret = readnum(&p)) < 0) return ret;
   }
   addr->node = ret;
   if (*p != '.') return 0;  /* Done if no point specified */

readpoint:
   p++;
   if ((ret = readnum(&p)) < 0) return ret;
   addr->point = ret;
   return 0;
}

void pn_to_asc(char *buf, short int *pn)
{
   *buf = '\0';
   if (*pn) sprintf(buf, "%d", *pn);
}

int asc_to_pn(short int *pn, char *buf)
{
   *pn = atoi(buf);
   if (*pn <= 0) *pn = 0;
   return 0;
}

char *mailer_opt[] = {"           Addresses ",
                      "Mail-only start time:",
                      "  Mail-only end time:"};

char *addr_opt[] = {"  Main:",
                    "AKA #1:",
                    "AKA #2:",
                    "AKA #3:",
                    "AKA #4:",
                    "AKA #5:",
                    "AKA #6:",
                    "AKA #7:",
                    "AKA #8:",
                    "AKA #9:"};

void act_addr(struct _wdef *w, int item, int flag)
{
   char buf[25];

   sd_pos(w->chid, -1, 1, 2 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->ink);
   fputs(addr_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   if (flag == I_ACTION) {
      w_edit(w, 9, 2 + item, 23, &setup.myaddress[item], addr_to_asc,
                asc_to_addr);
      w_edit(w, 33, 2 + item, 5, &setup.pointnet[item], pn_to_asc, asc_to_pn);
   }
   else {
      addr_to_asc(buf, &setup.myaddress[item]);
      fputs(buf, w->fp);
      pn_to_asc(buf, &setup.pointnet[item]);
      sd_tab(w->chid, -1, 33);
      fputs(buf, w->fp);
   }
}

void do_addr(void)
{
   struct _wdef *w;

   w = w_open(238, 142, 136, 54, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_addr;
   w->n_items = w->w_items = 10;
   w_setup(w, 116, 2, 7, " Addresses ");
   sd_pixp(w->chid, -1, 6, 5);
   sd_setin(w->chid, -1, 4);
   sd_setul(w->chid, -1, 1);
   fputs("Address                     Pointnet", w->fp);
   sd_setul(w->chid, -1, 0);
   w_select(w, NULL, "\x1B");
   w_close(w);
}

void act_mailer(struct _wdef *w, int item, int flag)
{
   char buf[25];

   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->ink);
   fputs(mailer_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   if (item == 0) {
      if (flag == I_ACTION) do_addr();
   }
   else {
      if (flag == I_ACTION)
         w_edit(w, 23, 1 + item, 5, (item == 1) ? &setup.mail_start :
                &setup.mail_end, time_to_asc, asc_to_time);
      else {
         time_to_asc(buf, (item == 1) ? &setup.mail_start : &setup.mail_end);
         fputs(buf, w->fp);
      }
   }
}

void do_mailer(void)
{
   struct _wdef *w;

   w = w_open(178, 62, 166, 94, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_mailer;
   w->n_items = w->w_items = 3;
   w_setup(w, 116, 2, 7, " Mailer ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

char *user_lvl[] = {"Twit", "Disgrace", "Normal", "Special", "Extra",
                    "", "", "", "CoSysOp", "SysOp"};

char *user_opt[] = {"       New user security level:",
                    "  New user message area groups:",
                    "     New user file area groups:",
                    "  Minutes per day for '  Twit':",
                    "Minutes per day for 'Disgrace':",
                    "  Minutes per day for 'Normal':",
                    " Minutes per day for 'Special':",
                    "   Minutes per day for 'Extra':",
                    " Minutes per day for 'CoSysOp':",
                    "   Minutes per day for 'SysOp':"};

void u_ttoa(char *buf, short *val)
{
   sprintf(buf, "%d", (int) *val);
}

int u_atot(short *val, char *buf)
{
   int i;

   i = atoi(buf);
   if (i < 0 || i > 1440) return -1;
   *val = i;
   return 0;
}

void u_gtoa(char *buf, unsigned long *val)
{
   char c = 'A';
   unsigned long mask = 1;

   while (c <= 'Z') {
      if (*val & mask) *buf++ = c;
      c++;
      mask <<= 1;
   }
   *buf = '\0';
}

int u_atog(unsigned long *val, char *buf)
{
   char c;
   unsigned long result = 0L;

   while ((c = *buf++) != '\0') {
      c = toupper(c);
      if (c < 'A' || c > 'Z') return -1;
      result |= 1 << (c - 'A');
   }
   *val = result;
   return 0;
}

void act_user(struct _wdef *w, int item, int flag)
{
   char buf[27];

   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->ink);
   fputs(user_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item) {
   case 0:
      if (flag == I_ACTION) {
         setup.init_sec++;
         if (setup.init_sec > MAXLEV) setup.init_sec = 0;
         while (!*user_lvl[setup.init_sec]) setup.init_sec++;
         sd_clrrt(w->chid, -1);
         fputs(user_lvl[setup.init_sec], w->fp);
      }
      else fputs(user_lvl[setup.init_sec], w->fp);
      break;
   case 1:
   case 2:
      if (flag == I_ACTION)
         w_edit(w, 33, 1 + item, 26, (item == 1) ? &setup.init_mgroups :
                &setup.init_fgroups, u_gtoa, u_atog);
      else {
         u_gtoa(buf, (item == 1) ? &setup.init_mgroups : &setup.init_fgroups);
         fputs(buf, w->fp);
      }
      break;
   case 3: case 4: case 5: case 6: case 7: case 8: case 9:
      if (flag == I_ACTION)
         w_edit(w, 33, 1 + item, 4, &setup.logintime[item - 3], u_ttoa, u_atot);
      else
         fprintf(w->fp, "%d", setup.logintime[item - 3]);
      break;
   }
}

void do_user(void)
{
   struct _wdef *w;

   w = w_open(364, 132, 74, 64, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_user;
   w->n_items = w->w_items = 10;
   w_setup(w, 116, 2, 7, " Users ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

char *misc_opt[] = {"                       System name:",
                    "                        SysOp name:",
                    "                   Local mode only:",
                    "                         Mail only:",
                    "                      'Yell' alarm:",
                    "                        Start time:",
                    "                          End time:",
                    "Message area for messages to SysOp:"};

char *misc_hlp[] = {"Name of your Bulletin Board System",
                    "Name of System Operator",
                    "If 'YES', QBOX starts up as if '-L' switch was given",
                    "If 'YES', QBOX only accepts Network Mail calls",
                    "If 'YES', QBOX sounds alarm during [Y]ell command",
                    "Start time for Yell alarm if enabled",
                    "End time for Yell alarm if enabled",
                    "Number of area for leaving comments etc. (0 = disabled)"};

int main(int argc, char *argv[], char *envp[])
{
   struct _wdef *w, *main_w;
   int i;
   char c;

   w_paper = w_strip = 0;
   w_ink = 7;
   w_sstrip = 4;
   w_sink = 0;
   w_estrip = 2;
   w_eink = 7;
   w_bcolour = 4;
   w_bwidth = 1;

   if (argc > 1)
      strcpy(path,argv[1]);
   w = w_make(stdout, 448, 182, 32, 24, W_ETRAP);
   w->paper = w->strip = 82;
   w->ink = 7;
   w->bcolour = 7;
   w->bwidth = 1;
   w_setup(w, 111, 7, 0, " QBOX SETUP ");
   sd_pos(w->chid, -1, 28, 1);
   printf("QBOX SETUP v%s", version);
   sd_pos(w->chid, -1, 19, 3);
   printf("Copyright (C) 1992 by Jan Bredenbeek");
   if (getsetup() != 0) goto exit_setup;
   main_w = w_open(106, 82, 202, 94, W_ETRAP | W_NOSAV);
   main_w->ilist = i_main;
   main_w->n_items = main_w->w_items = 5;
   while (1) {
      w_save(main_w);
      w_setup(main_w, 116, 2, 7, " Main ");
      i = w_select(main_w, "fnumq", "\n\x1B fnumq");
      w_restore(main_w);
      if (i == 0x1B || main_w->c_item == 4) {
         c = savechanges();
         if (c == 0x1B) continue;
         if (c == 'y') putsetup();
         break;
      }
      switch(main_w->c_item) {
      case 0: do_filenames(); break;
      case 1: do_mailer(); break;
      case 2: do_user(); break;
/*      case 3: do_misc(); break;     */
      }
   }

   w_close(main_w);
exit_setup:
   w_close(w);
   return 0;
}

