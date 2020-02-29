/* WAMM - Window And Menu Manager */

#include <stdio_h>
#include <stdlib_h>
#include <string_h>
#include <ctype_h>
#include <qdos_h>
#include "wamm_h"

#define W_TIMO -1

int w_paper = 0;
int w_strip = 0;
int w_ink = 7;
int w_sstrip = 4;
int w_sink = 0;
int w_estrip = 2;
int w_eink = 7;
int w_bcolour = 4;
int w_bwidth = 1;
int w_xshad = 8;
int w_yshad = 6;

int w_pinf(struct _wdef *w)
{
   struct REGS regs;

   regs.D0 = 0x70;   /* IOP.PINF */
   regs.D3 = W_TIMO;
   regs.A0 = (char *) w->chid;
   return (qdos3(&regs, &regs) == 0) ? 1 : 0;
}

int w_outln(struct _wdef *w, int xshad, int yshad, int move)
{
   struct REGS regs;

   regs.D0 = 0x7A;   /* IOP.OUTL */
   regs.D1 = xshad << 16 | yshad;
   regs.D2 = move;
   regs.D3 = W_TIMO;
   regs.A0 = (char *) w->chid;
   regs.A1 = (char *) &w->width;
   return qdos3(&regs, &regs);
}

char *w_save(struct _wdef *w)
{
   if (w_pinf(w))
      w->savbuff = (w_outln(w, w_xshad, w_yshad, 0) == 0) ? (char *) 1 : NULL;
   else w->savbuff = _wsave(w->chid, W_TIMO, (struct QLRECT *)&w->width);
   w->flags |= W_NOSAV;
   if (w->savbuff) w->flags ^= W_NOSAV;
   return w->savbuff;
}

struct _wdef *w_open(int width, int height, int xorg, int yorg, 
                     int flags)
{
   char chname[25];
   FILE *fp;
   struct _wdef *w;

   sprintf(chname, "CON_%dX%dA%dX%d", width, height, xorg, yorg);
   if (!(fp = fopen(chname, "r+"))) {
      if (flags & W_ETRAP)
         exit(_oserr);
      else
         return NULL;
   }
   if ((w = _wopen(fp, width, height, xorg, yorg, flags)) != NULL)
      return w;
   else {
      fclose(fp);
      return NULL;
   }
}

struct _wdef *w_make(FILE *fp, int width, int height, int xorg, int yorg,
                     int flags)
{
   struct _wdef *w;
   struct QLRECT coords;

   coords.q_width = width;
   coords.q_height = height;
   coords.q_x = xorg;
   coords.q_y = yorg;
   if (sd_wdef(fgetchid(fp), W_TIMO, 0, 0, &coords) != 0) {
      if (flags & W_ETRAP)
         exit(ERR_OR);
      else
         return NULL;
   }
   if (!(w = _wopen(fp, width, height, xorg, yorg, flags))) return NULL;
   w->flags |= W_NOCLOSE;
   return w;
}

struct _wdef *_wopen(FILE *fp, int width, int height, int xorg, int yorg,
                     int flags)
{
   struct _wdef *w;
   short mode, display;

   if (!(w = calloc(1, sizeof(struct _wdef)))) {
      if (flags & W_ETRAP)
         exit(_oserr);
      else
         return NULL;
   }
   w->fp = fp;
   w->chid = fgetchid(fp);
   w->flags = flags;
   w->width = width;
   w->height = height;
   w->xorg = xorg;
   w->yorg = yorg;
   if (!(flags & W_NOSAV) && !w_save(w)) {
      free(w);
      if (flags & W_ETRAP) 
         exit(_oserr);
      else
         return NULL;
   }
   setbuf(w->fp, NULL);
   w->paper = w_paper;
   w->strip = w_strip;
   w->ink = w_ink;
   w->sstrip = w_sstrip;
   w->sink = w_sink;
   w->estrip = w_estrip;
   w->eink = w_eink;
   w->bcolour = w_bcolour;
   w->bwidth = w_bwidth;
   mode = display = -1;
   mt_dmode(&mode, &display);
   w->cwidth = (mode == 8) ? 12 : 6;
   w->cheight = 10;
   return w;
}

void w_setup(struct _wdef *w, int tp, int ts, int ti, char *title)
{
   short int tl, ll;
   struct QLRECT r;

   memcpy(&r, &w->width, sizeof(struct QLRECT));
   sd_wdef(w->chid, W_TIMO, w->bcolour, w->bwidth, &r);
   sd_pos(w->chid, W_TIMO, 0,0);
   if (title != NULL) {
      sd_setpa(w->chid, W_TIMO, tp);
      sd_setst(w->chid, W_TIMO, ts);
      sd_setin(w->chid, W_TIMO, ti);
      sd_clrln(w->chid, W_TIMO);
      ll = w->width / w->cwidth;
      if ((tl = strlen(title)) > ll) tl = ll;
      sd_tab(w->chid, W_TIMO, (int) (ll - tl) / 2);
      io_sstrg(w->chid, W_TIMO, title, tl);
      r.q_height -= w->cheight;
      r.q_y += w->cheight;
      sd_wdef(w->chid, W_TIMO, w->bcolour, w->bwidth, &r);
   }
   sd_setpa(w->chid, W_TIMO, w->paper);
   sd_setst(w->chid, W_TIMO, w->strip);
   sd_setin(w->chid, W_TIMO, w->ink);
   if (!w->action) w->action = w_asitem;
   w_draw(w);
}

void w_restore(struct _wdef *w)
{
   if (w->flags & W_NOSAV) return;
   if (w->savbuff == (char *) 1) {  /* used IOP.OUTL to save window */
      struct REGS regs;
      regs.D0 = 0x7F;               /* use IOP.WRST to restore */
      regs.D2 = 0;
      regs.D3 = W_TIMO;
      regs.A0 = (char *) w->chid;
      regs.A1 = (char *) NULL;
      qdos3(&regs, &regs);
   }
   else _wrest(w->chid, W_TIMO, w->savbuff);
   w->flags |= W_NOSAV;
}

void w_close(struct _wdef *w)
{
   w_restore(w);
   if (!(w->flags & W_NOCLOSE)) fclose(w->fp);
   free(w);
}

void w_draw(struct _wdef *w)
{
   int i, h_item;
   sd_clear(w->chid, W_TIMO);
   if (!w->n_items) return;
   h_item = (w->t_item + w->w_items > w->n_items) ? w->n_items : w->t_item + w->w_items;
   for (i = w->t_item; i < h_item; i++)
      (*w->action)(w, i, 0);     /* draw all visible items */
   if (w->c_item >= w->t_item && w->c_item < h_item)
      (*w->action)(w, w->c_item, 1);     /* draw current item */
}

void w_prev(struct _wdef *w)
{
   if (!w->n_items) return;
   (*w->action)(w, w->c_item, -1);    /* Unprint current item */
   if (--w->c_item < w->t_item) w->c_item = w->t_item + w->w_items - 1;
   (*w->action)(w, w->c_item, 1);
}

void w_next(struct _wdef *w)
{
   if (!w->n_items) return;
   (*w->action)(w, w->c_item, -1);
   if (++w->c_item >= w->t_item + w->w_items) w->c_item = w->t_item;
   (*w->action)(w, w->c_item, 1);
}

void w_up(struct _wdef *w)
{
   if (!w->n_items) return;
   (*w->action)(w, w->c_item, -1);
   if (--w->c_item < w->t_item) {
      if (--w->t_item < 0)
         w->c_item = w->t_item = 0;
      else
         sd_scrol(w->chid, W_TIMO, (int) w->cheight);
    }
   (*w->action)(w, w->c_item, 1);
}

void w_down(struct _wdef *w)
{
   if (!w->n_items) return;
   (*w->action)(w, w->c_item, -1);
   if (++w->c_item < w->n_items) {
      if (w->c_item - w->t_item >= w->w_items) {
         w->t_item++;
         sd_scrol(w->chid, W_TIMO, -w->cheight);
      }
   }
   else 
      w->c_item = w->n_items - 1;
   (*w->action)(w, w->c_item, 1);
}

void w_pgup(struct _wdef *w)
{
   int d;
   if (!w->n_items) return;
   if (w->c_item == w->t_item) {
      d = w->t_item >= w->w_items ? w->w_items - 1 : w->t_item;
      w->c_item -= d;
      w->t_item -= d;
      w_draw(w);
   }
   else {
      (*w->action)(w, w->c_item, -1);
      w->c_item = w->t_item;
      (*w->action)(w, w->c_item, 1);
   }
}

void w_pgdn(struct _wdef *w)
{
   if (!w->n_items) return;
   if (w->c_item == w->t_item + w->w_items - 1) {
      if (w->t_item + w->w_items < w->n_items) {
         w->t_item += w->w_items - 1;
         w->c_item += w->w_items - 1;
         if (w->c_item >= w->n_items) w->c_item = w->n_items - 1;
      }
      w_draw(w);
   }
   else {
      (*w->action)(w, w->c_item, -1);
      w->c_item = w->t_item + w->w_items - 1;
      (*w->action)(w, w->c_item, 1);
   }
}

void w_home(struct _wdef *w)
{
   w->c_item = w->t_item = 0;
   w_draw(w);
}

void w_end(struct _wdef *w)
{
   w->t_item = w->n_items - w->w_items;
   if (w->t_item < 0) w->t_item = 0;
   w->c_item = w->t_item + w->w_items - 1;
   if (w->c_item >= w->n_items) w->c_item = w->n_items - 1;
   w_draw(w);
}

void w_asitem(struct _wdef *w, int item, int flag)
{
   struct simple_item *i;

   i = w->ilist + item;
   sd_pos(w->chid, W_TIMO, i->xpos, i->ypos);
   sd_setst(w->chid, W_TIMO, (flag > 0) ? w->sstrip : w->strip);
   sd_setin(w->chid, W_TIMO, (flag > 0) ? w->sink : w->ink);
   io_sstrg(w->chid, W_TIMO, i->text, (short) strlen(i->text));
}

int w_select(struct _wdef *w, char *keys, char *esc)
{
   char c;
   char *p;

   while (1) {
      if (io_fbyte(w->chid, W_TIMO, &c) != 0) return -1;
      if (keys && c && (p = strchr(keys, tolower(c)))) {
         (*w->action)(w, w->c_item, I_DESEL);
         (*w->action)(w, w->c_item = p - keys, I_ACTION);
      }
      if (esc && c && strchr(esc, tolower(c))) return (int) c;
      switch (c) {
      case 0x0A:
      case 0x20: (*w->action)(w, w->c_item, I_ACTION); break;
      case LEFT:
      case UP  : w_prev(w); break;
      case RIGHT:
      case DOWN: w_next(w); break;
      case ALT | LEFT:
      case ALT | UP  : w_home(w); break;
      case ALT | RIGHT:
      case ALT | DOWN: w_end(w); break;
      }
   }
}

int w_edstr(struct _wdef *w, int xpos, int ypos, int maxlen, char *cptr)
{
   char buf[80];
   int ret;

   strcpy(buf, cptr);
   if ((ret = w_edlin(w, xpos, ypos, maxlen, NULL, buf)) >= 0 && ret != 0x1B)
      strcpy(cptr, buf);
   sd_setst(w->chid, W_TIMO, w->strip);
   sd_setin(w->chid, W_TIMO, w->ink);
   sd_pos(w->chid, W_TIMO, xpos, ypos);
   clearfield(w, xpos, ypos, maxlen, w->strip);
   io_sstrg(w->chid, W_TIMO, cptr, (short) strlen(cptr));
   return ret;
}

/**********************************************************************
 *                                                                    *
 *    Edit an object                                                  *
 *                                                                    *
 *    w: window def pointer            obj: pointer to object         *
 *    xpos, ypos: window position      maxlen: maxlen of input field  *
 *    preproc: preprocess function (puts ASCII value of obj into buf) *
 *    postproc: postprocess fn (parses ASCII in buf to obj value)     *
 *                                                                    *
 **********************************************************************/

int w_edit(struct _wdef *w, int xpos, int ypos, int maxlen, void *obj,
           void (*preproc)(char *, void *), int (*postproc)(void *, char *))
{
   char buf[80];
   int ret;

   do {
      (*preproc)(buf, obj);
   } while ((ret = w_edlin(w, xpos, ypos, maxlen, NULL, buf)) >= 0 
            && ret != 0x1B && (*postproc)(obj, buf) != 0);
   (*preproc)(buf, obj);
   sd_setst(w->chid, W_TIMO, w->strip);
   sd_setin(w->chid, W_TIMO, w->ink);
   sd_pos(w->chid, W_TIMO, xpos, ypos);
   clearfield(w, xpos, ypos, maxlen, w->strip);
   io_sstrg(w->chid, W_TIMO, buf, (short) strlen(buf));
   return ret;
}

int w_edlin(struct _wdef *w, int xpos, int ypos, int maxlen, int *curpos,
            char *buf)
{
   int ret, cur_len, cur_pos, i;
   int firstkey = 1;
   int ed_end = 0;
   char c;
   char *p, *q;

   sd_pos(w->chid, W_TIMO, xpos, ypos);
   sd_setst(w->chid, W_TIMO, w->estrip);
   sd_setin(w->chid, W_TIMO, w->eink);
   clearfield(w, xpos, ypos, maxlen, w->estrip);
   cur_len = strlen(buf);
   if (cur_len > maxlen) cur_len = maxlen;
   io_sstrg(w->chid, W_TIMO, buf, cur_len);
   cur_pos = (curpos != NULL && *curpos >= 0) ? *curpos : 0;
   if (cur_pos > cur_len) cur_pos = cur_len;
   p = buf + cur_pos;
   sd_tab(w->chid, W_TIMO, xpos);
   sd_cure(w->chid, W_TIMO);
   do {
      if ((ret = io_fbyte(w->chid, W_TIMO, &c)) < 0) break;
      switch ((unsigned char) c) {
      case LEFT:
         if (cur_pos > 0) {
            cur_pos--;
            p--;
            sd_pcol(w->chid, W_TIMO);
         }
         break;
      case ALT | LEFT:  /* cursor to start of input field */
         cur_pos = 0;
         p = buf;
         sd_tab(w->chid, W_TIMO, xpos);
         break;
      case CTRL | LEFT: /* delete left */
         if (cur_pos == 0) break;
         cur_pos--;
         p--;
         sd_pcol(w->chid, W_TIMO);
         /* fall through */
      case CTRL | RIGHT:      /* delete right */
         if (cur_len == cur_pos) break;
         q = p + 1;
         cur_len--;
         for (i = cur_pos; i < cur_len; i++) *p++ = *q++;
         p = buf + cur_pos;
         sd_curs(w->chid, W_TIMO);
         io_sstrg(w->chid, W_TIMO, p, (short) (cur_len - cur_pos));
         io_sbyte(w->chid, W_TIMO, ' ');
         sd_tab(w->chid, W_TIMO, xpos + cur_pos);
         sd_cure(w->chid, W_TIMO);
         break;
      case CTRL | ALT | LEFT:    /* clear field */
         cur_pos = cur_len = 0;
         p = buf;
         clearfield(w, xpos, ypos, maxlen, w->estrip);
         sd_tab(w->chid, W_TIMO, xpos);
         break;
      case RIGHT:
         if (cur_pos < cur_len) {
            cur_pos++;
            p++;
            sd_ncol(w->chid, W_TIMO);
         }
         break;
      case ALT | RIGHT:
         cur_pos = cur_len;
         p = buf + cur_pos;
         sd_tab(w->chid, W_TIMO, xpos + cur_pos);
         break;
      case CTRL | ALT | RIGHT:
         sd_curs(w->chid, W_TIMO);
         for (i = cur_pos; i < cur_len; i++) io_sbyte(w->chid, W_TIMO, ' ');
         cur_len = cur_pos;
         sd_tab(w->chid, W_TIMO, xpos + cur_pos);
         sd_cure(w->chid, W_TIMO);
         break;
      case 0x09:
      case 0x0A:
      case 0x1B:
         ed_end = 1;
         ret = (unsigned char) c;
         break;
      default:
         if ((unsigned char) c > 0xBF) {
            ed_end = 1;
            ret = (unsigned char) c;
         }
         else {
            if (firstkey && (curpos == NULL || *curpos < 0)) {
               clearfield(w, xpos, ypos, maxlen, w->estrip);
               cur_pos = cur_len = 0;
               p = buf;
               sd_tab(w->chid, W_TIMO, xpos);
            }
            if (cur_len >= maxlen) break;
            if ((i = cur_len - cur_pos) > 0) {
               p = buf + cur_len;
               q = p + 1;
               while (i--) *--q = *--p;
            }
            *p = c;
            sd_curs(w->chid, W_TIMO);
            io_sstrg(w->chid, W_TIMO, p, cur_len - cur_pos + 1);
            p++;
            cur_pos++;
            cur_len++;
            sd_tab(w->chid, W_TIMO, xpos + cur_pos);
            sd_cure(w->chid, W_TIMO);
         }
         break;
      }
      firstkey = 0;
   } while (!ed_end);
   sd_curs(w->chid, W_TIMO);
   buf[cur_len] = '\0';
   if (curpos != NULL) *curpos = cur_pos;
   return ret;
}

void clearfield(struct _wdef *w, int xpos, int ypos, int len, int colour)
{
   struct QLRECT field;

   field.q_width = (short) len * w->cwidth;
   field.q_height = w->cheight;
   field.q_x = (short) xpos * w->cwidth;
   field.q_y = (short) ypos * w->cheight;
   sd_fill(w->chid, W_TIMO, colour, &field);
}


