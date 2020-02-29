#include "qsetup_h"

static char *user_lvl[] = {"Twit", "Disgrace", "Normal", "Special", "Extra",
                           "", "", "", "CoSysOp", "SysOp"};

static char *user_opt[] = {
   "       New user security level ",
   "  New user message area groups ",
   "     New user file area groups ",
   "  Minutes per day for '  Twit' ",
   "Minutes per day for 'Disgrace' ",
   "  Minutes per day for 'Normal' ",
   " Minutes per day for 'Special' ",
   "   Minutes per day for 'Extra' ",
   " Minutes per day for 'CoSysOp' ",
   "   Minutes per day for 'SysOp' "
};

static void u_ttoa(char *buf, short *val)
{
   sprintf(buf, "%d", (int) *val);
}

static int u_atot(short *val, char *buf)
{
   int i;

   i = atoi(buf);
   if (i < 0 || i > 1440) return -1;
   *val = i;
   return 0;
}

static void u_gtoa(char *buf, unsigned long *val)
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

static int u_atog(unsigned long *val, char *buf)
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
   int lvl;

   sd_pos(w->chid, -1, 1, 1 + item);
   sd_setst(w->chid, -1, (flag > 0) ? w->sstrip : w->sink);
   sd_setin(w->chid, -1, (flag > 0) ? w->sink : w->sstrip);
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
         w_edit(w, 33, 1 + item, 26, (item == 1) ? &setup.init_mgroups : &setup.init_fgroups,
            (void (*)(char *, void *))u_gtoa,
            (int (*)(void *, char *))u_atog);
      else {
         u_gtoa(buf, (item == 1) ? &setup.init_mgroups : &setup.init_fgroups);
         fputs(buf, w->fp);
      }
      break;
   case 3: case 4: case 5: case 6: case 7: case 8: case 9:
      lvl = (item < 8) ? item - 3 : item;
      if (flag == I_ACTION)
         w_edit(w, 33, 1 + item, 4, &setup.logintime[lvl], 
            (void (*)(char *, void *))u_ttoa,
            (int (*)(void *, char *))u_atot);
      else
         fprintf(w->fp, "%d", setup.logintime[lvl]);
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

