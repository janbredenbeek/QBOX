#include <stdio_h>
#include <stdlib_h>
#include <fcntl_h>
#include <unistd_h>
#include <string_h>
#include <ctype_h>
#include <qdos_h>
#include <wamm_h>

extern char version[];

#define SETUPFNAME   "SETUP_BBS"
#define SET_FPRINT   0x51534554
#define THISREV   1
#define COMPREV   1

#define MAXPATH 18
#define MAXNAME 38
#define MAXFNAME 46
#define MAX_AKA 10

#define TWIT     0
#define DISGRACE 1
#define NORMAL   2
#define SPECIAL  3
#define EXTRA    4
#define COSYSOP  8
#define SYSOP    9
#define MAXLEV   9

#define MAIL_ONLY 1
#define BBS_ONLY  2

typedef struct {
   short int zone, net, node, point;
} ADDRESS;

struct _setup {
   unsigned long fingerprint; /* fingerprint of SETUP_QBOX file */
   unsigned short thisrev,    /* Revision level of this file */
                  comprev;    /* Rev. level required for backward compat. */
   unsigned long  totlen;     /* Total length of setup file */
   char sysdir[MAXPATH],      /* system directory (QLSTR) */
        inbound[MAXPATH],     /* inbound directory (QLSTR) */
        outbound[MAXPATH],    /* outbound directory (QLSTR) */
        msgtmp[MAXPATH],      /* temporary message path (QLSTR) */
        qspil[22],            /* QSPIL filename (QLSTR) */
        log1[MAXFNAME],       /* log file for remote server (QLSTR) */
        log2[MAXFNAME],       /* log file for local server (QLSTR) */
        editor[MAXFNAME],     /* local message editor (QLSTR) */
        terminal[MAXFNAME],   /* local terminal emulator */
        sysname[MAXNAME],     /* system's name (QLSTR) */
        sysop[MAXNAME],       /* Sysop's name (QLSTR) */
        mailprog[MAXFNAME],   /* Program(s) to execute on rcvd mail */
        afteruser[MAXFNAME],  /* Program(s) to execute after each user */
        faxprog[MAXFNAME],    /* Program(s) to execute on fax call */
         spare1[344];         /* filler */

   unsigned short int init_sec;  /* initial security level */
   unsigned long init_mgroups, init_fgroups; /* initial area groups */
   unsigned short init_msgarea, init_filearea;
   unsigned short logintime[MAXLEV + 1]; /* time limit for each level */
   unsigned short sysopmsg;   /* msg area for log-off message */
   unsigned short yell_start, yell_end;
   unsigned char  yellflag;   /* Yell enabled if != 0 */
   unsigned char  local_only, mailmode;
   unsigned char  s_txslo, s_rxslo;
            char  s_bufsize;
   unsigned char  spare2[26];
   ADDRESS myaddress[MAX_AKA]; /* network addresses */
   short int pointnet[MAX_AKA]; /* pointnets */
   unsigned short mail_start, mail_end; /* start/end time of mail-only period
                                           (in minutes; 0-1439) */
};

#define skipspc(p)   while(isspace(*p)) p++

extern struct _setup setup;
extern char path[];

void error(char *);
int savechanges(void);
void do_filenames(void);
void time_to_asc(char *, unsigned short *);
int asc_to_time(unsigned short *, char *);
void addr_to_asc(char *, ADDRESS *);
int readnum(char **);
int asc_to_addr(ADDRESS *, char *);
void do_mailer(void);
void do_user(void);
void do_misc(void);
void do_modem(void);

