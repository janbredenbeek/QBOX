/* WAMM QL window and menu toolkit */

/* Simple (plain text) menu items definition */

struct simple_item {
   int   xpos, ypos;    /* position in window */
   char  *text;        /* item text */
};

#define W_NOSAV 1
#define W_NOCLOSE 2
#define W_ETRAP 4

#define ALT   1
#define CTRL  2
#define SHIFT 4
#define LEFT  0xC0
#define RIGHT 0xC8
#define UP    0xD0
#define DOWN  0xD8
#define CAPSLOCK 0xE0
#define F_CTRL  1
#define F_SHIFT 2
#define F1    0xE8
#define F2    0xEC
#define F3    0xF0
#define F4    0xF4
#define F5    0xF8

#define I_DRAW    0
#define I_SELECT  1
#define I_DESEL   -1
#define I_ACTION  2

#define WS_ESC -1

struct _wdef {
   short width,        /* window width in pixels */
         height,       /* window height */
         xorg,         /* x origin */
         yorg,         /* y origin */
         cwidth,       /* character width */
         cheight;      /* character height */
   int   bwidth,       /* border width */
         bcolour,      /* border colour */
         paper,        /* paper/strip colour (normal) */
         strip,        /* strip colour (normal) */
         ink,          /* ink colour (normal) */
         sstrip,       /* strip colour (sel. item) */
         sink,         /* ink colour (sel. item) */
         estrip,       /* strip colour (edit field) */
         eink,         /* ink colour (edit field) */
         c_item,       /* number of current item */
         n_items,      /* total number of items */
         t_item,       /* first item in window */
         w_items,      /* number of possible items in window */
         flags;        /* bit flags */
    void (*action)(struct _wdef *w, int item, int flag); /* item action function */
    FILE *fp;          /* file pointer */
    chanid_t chid;     /* channel ID */
    char *savbuff;     /* addr of screen save buffer */
    struct simple_item *ilist;
};

char *_wsave(chanid_t chan, int timeout, struct QLRECT *coords);
char *_wrest(chanid_t chan, int timeout, char *savbuff);
char *w_save(struct _wdef *w);
int  w_pinf(struct _wdef *w);
int  w_outln(struct _wdef *w, int xshad, int yshad, int move);
struct _wdef *w_open(int width, int height, int xorg, int yorg, int flags);
struct _wdef *w_make(FILE *fp, int width, int height, int xorg, int yorg, 
                     int flags);
struct _wdef *_wopen(FILE *fp, int width, int height, int xorg, int yorg, 
                     int flags);
void w_setup(struct _wdef *w, int tp, int ts, int ti, char *title);
void w_restore(struct _wdef *w);
void w_close(struct _wdef *w);
void w_draw(struct _wdef *w);
void w_prev(struct _wdef *w);
void w_next(struct _wdef *w);
void w_up(struct _wdef *w);
void w_down(struct _wdef *w);
void w_pgup(struct _wdef *w);
void w_pgdn(struct _wdef *w);
void w_home(struct _wdef *w);
void w_end(struct _wdef *w);
void w_asitem(struct _wdef *w, int item, int flag);
int  w_select(struct _wdef *w, char *selkeys, char *esckeys);
int  w_edstr(struct _wdef *w, int xpos, int ypos, int maxlen, char *cptr);
int  w_edit(struct _wdef *w, int xpos, int ypos, int maxlen, void *obj,
            void (*preproc)(char *, void *), int (*postproc)(void *, char *));
int  w_edlin(struct _wdef *w, int xpos, int ypos, int maxlen, int *curpos,
             char *cptr);
void clearfield(struct _wdef *w, int xpos, int ypos, int len, int colour);

extern int w_paper, w_strip, w_ink, w_sstrip, w_sink, w_estrip, w_eink;
extern int w_bcolour, w_bwidth, w_xshad, w_yshad;

