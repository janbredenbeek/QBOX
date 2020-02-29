#include "qsetup_h"

char _prog_name[] = "QSETUP";

char version[] = "1.19m";

void (*_consetup)() = NULL;
char *_endmsg = NULL;

struct _setup setup;

char path[17] = "\0";

static struct simple_item i_main[] = {
   1, 1, "   Filenames   ",
   1, 2, "Network Mailer ",
   1, 3, "     Users     ",
   1, 4, " Miscellaneous ",
   1, 5, "     Modem     ",
   1, 6, "     Quit      "};

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

static struct simple_item i_getsetup[] = {
   7, 2, " Yes ",
  14, 2, " No (abort) "};

int getsetup(void)
{
   char sfile[50], temp[50];
   char c;
   char *p;
   int i, fd, extra;
   struct _wdef *w;

   fd = -1;
   if (!*path && ((p = getenv("QBOX")) != NULL))
      strcpy(path, p);     /* Use cmdline path or env var if present */
   if (*path) {
      if (path[strlen(path) - 1] != '_')
         strcat(path, "_");
      if (isdevice(path, &extra)) {
         strcpy(sfile, path);
         strcat(sfile, SETUPFNAME);
         fd = open(sfile, O_RDONLY);
      }
   }
   else {
      if (getcpd(path, 24) && isdevice(path, &extra)) {
         strcpy(sfile, path);
         strcat(sfile, SETUPFNAME);
         fd = open(sfile, O_RDONLY);   /* next, try program dir */
      }
      if (fd < 0 && getcwd(path, 24) && isdevice(path, &extra)) {
         strcpy(sfile, path);
         strcat(sfile, SETUPFNAME);
         fd = open(sfile, O_RDONLY);   /* next, try data dir */
      }
      if (fd < 0) *path = '\0';
   }
   if (fd < 0 && !isdevice(path, &extra)) { /* still no luck so ask user about dir... */
      *path = '\0';
      w = w_open(322, 32, 94, 104, W_ETRAP);
      w->paper = w->strip = 210;
      w->estrip = 0;
      w_setup(w, 0, 0, 0, NULL);
      sd_pos(w->chid, -1, 1, 1);
      fputs("Enter SETUP_BBS directory: ", w->fp);
      while (1) {
         if ((i = w_edstr(w, 28, 1, 24, path)) < 0 || i == 0x1B) return -1;
         if (isdevice(path, &extra)) break;
         sd_pos(w->chid, -1, 1, 0);
         sd_clrln(w->chid, -1);
         fprintf(w->fp, "'%s' is not a valid directory", path);
      }
      w_close(w);
      strcpy(sfile, path);
      strcat(sfile, "SETUP_BBS");
      fd = open(sfile, O_RDONLY);
   }
   if (fd < 0) {
      if (_oserr != ERR_NF) {
         error("Unable to open setup file!");
         return -1;
      }
      w = w_open(202, 42, 154, 104, W_ETRAP);
      w->ilist = i_getsetup;
      w->n_items = w->w_items = 2;
      w_setup(w, 0, 0, 0, NULL);
      sd_pos(w->chid, -1, 1, 0);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs("SETUP_BBS not found, create it?", w->fp);
      i = w_select(w, "yn", "\n\x1B yn");
      if (i == 0x1B || i == 'n' || w->c_item == 1) {
         w_close(w);
         return -1;
      }
      w_close(w);
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
      cstr_to_ql((struct QLSTR *)setup.log2, "ram1_qboxl_log");
      strcpy(setup.editor, path);
      strcat(setup.editor, "QED %W");
      strcpy(setup.terminal, path);
      strcat(setup.terminal, "QLTERM");
      cstr_to_ql((struct QLSTR *)setup.sysop, "Sysop");
      strcpy(setup.afteruser, path);
      strcat(setup.afteruser, "LOOKMAIL");
      strcpy(setup.faxprog, path);
      strcat(setup.faxprog, "QFAX %< %>>log %> -v -x -G");
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

static struct simple_item i_savechanges[] = {
   1, 2, "      Yes     ",
   1, 3, "      No      ",
   1, 4, " Return (ESC) "};

int savechanges(void)
{
   struct _wdef *w;
   int ret;

   w = w_open(100, 62, 206, 94, W_ETRAP);
   w->ilist = i_savechanges;
   w->n_items = w->w_items = 3;
   w_setup(w, 0, 0, 0, NULL);
   sd_pos(w->chid, -1, 1, 0);
   sd_setpa(w->chid, -1, w->estrip);
   sd_setst(w->chid, -1, w->estrip);
   sd_setin(w->chid, -1, w->eink);
   sd_clrln(w->chid, -1);
   fputs("Save changes?", w->fp);
   ret = w_select(w, "ynr", "\n\x1B ynr");
   if (ret == 'r') ret = 0x1B;
   if (ret == '\n' || ret == ' ')
      ret = "yn\x1B"[w->c_item];
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
   sd_pos(w->chid, -1, 17, 3);
   printf("Copyright (C) 1992-94 by Jan Bredenbeek");
   if (getsetup() != 0) goto exit_setup;
   main_w = w_open(106, 92, 202, 94, W_ETRAP | W_NOSAV);
   main_w->ilist = i_main;
   main_w->n_items = main_w->w_items = 6;
   while (1) {
      w_save(main_w);
      w_setup(main_w, 116, 2, 7, " Main ");
      i = w_select(main_w, NULL, "\n\x1B ");
      w_restore(main_w);
      if (i == 0x1B || main_w->c_item == 5) {
         c = savechanges();
         if (c == 0x1B) continue;
         if (c == 'y') putsetup();
         break;
      }
      switch(main_w->c_item) {
      case 0: do_filenames(); break;
      case 1: do_mailer(); break;
      case 2: do_user(); break;
      case 3: do_misc(); break;
      case 4: do_modem(); break;
      }
   }

   w_close(main_w);
exit_setup:
   w_close(w);
   return 0;
}

