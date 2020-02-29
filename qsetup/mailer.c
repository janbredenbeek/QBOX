#include "qsetup_h"

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
   sprintf(buf, "%d:%d/%d.%d", addr->zone, addr->net, addr->node, addr->point);
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

static void pn_to_asc(char *buf, short int *pn)
{
   *buf = '\0';
   if (*pn) sprintf(buf, "%d", *pn);
}

static int asc_to_pn(short int *pn, char *buf)
{
   *pn = atoi(buf);
   if (*pn <= 0) *pn = 0;
   return 0;
}

static char *mailer_opt[] = {"         Addresses > ",
                             "Mail-only start time ",
                             "  Mail-only end time ",
                             "     Mail processing "};

static char *mailer_hlp[] = {"Network addresses",
                             "Start of mail-only (no BBS access) period",
                             "End of mail-only (no BBS access) period",
                             "Program executed after received mail"};

static char *addr_opt[] = {"  Main ",
                           "AKA #1 ",
                           "AKA #2 ",
                           "AKA #3 ",
                           "AKA #4 ",
                           "AKA #5 ",
                           "AKA #6 ",
                           "AKA #7 ",
                           "AKA #8 ",
                           "AKA #9 "};

void act_addr(struct _wdef *w, int item, int flag)
{
   char buf[25];

   sd_pos(w->chid, -1, 1, 2 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->sink);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->sstrip);
   fputs(addr_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   if (flag == I_ACTION) 
   {
      w_edit(w, 9, 2 + item, 23, &setup.myaddress[item], 
         (void (*)(char *, void *))addr_to_asc,
         (int (*)(void *, char *))asc_to_addr);
      w_edit(w, 33, 2 + item, 5, &setup.pointnet[item], 
         (void (*)(char *, void *))pn_to_asc,
         (int (*)(void *, char *))asc_to_pn);
   }
   else 
   {
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
   sd_setin(w->chid, -1, w->sstrip);
   sd_setul(w->chid, -1, 1);
   fputs("Address                      Pointnet", w->fp);
   sd_setul(w->chid, -1, 0);
   w_select(w, NULL, "\x1B");
   w_close(w);
}

void act_mailer(struct _wdef *w, int item, int flag)
{
   char buf[25];

   if (flag > 0) 
   {
      sd_pos(w->chid, -1, 1, 6);
      sd_setpa(w->chid, -1, w->estrip);
      sd_setst(w->chid, -1, w->estrip);
      sd_setin(w->chid, -1, w->eink);
      sd_clrln(w->chid, -1);
      fputs(mailer_hlp[item], w->fp);
   }
   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->sink);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->sstrip);
   fputs(mailer_opt[item], w->fp);
   sd_setst(w->chid, -1, w->strip);
   sd_setin(w->chid, -1, w->ink);
   fputc(' ', w->fp);
   switch (item) {
   case 0:
      if (flag == I_ACTION) do_addr();
      break;
   case 1: case 2:
      if (flag == I_ACTION)
         w_edit(w, 23, 1 + item, 5, (item == 1) ? &setup.mail_start : &setup.mail_end,
            (void (*)(char *, void *))time_to_asc,
            (int (*)(void *, char *))asc_to_time);
      else {
         time_to_asc(buf, (item == 1) ? &setup.mail_start : &setup.mail_end);
         fputs(buf, w->fp);
      }
      break;
   case 3:
      if (flag == I_ACTION)
         w_edstr(w, 23, 1 + item, MAXFNAME - 1, setup.mailprog);
      else 
         fputs(setup.mailprog, w->fp);
      break;
   }
}

void do_mailer(void)
{
   struct _wdef *w;

   w = w_open(418, 82, 46, 84, W_ETRAP);
   w->paper = w->strip = 0;
   w->action = act_mailer;
   w->n_items = w->w_items = 4;
   w_setup(w, 116, 2, 7, " Mailer ");
   w_select(w, NULL, "\x1B");
   w_close(w);
}

