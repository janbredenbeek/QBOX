* QBOX BULLETIN BOARD SYSTEM
*
* Copyright (C) 1987-1994 by Jan Bredenbeek, Hilversum, Holland.
*
*
* MAIN_ASM  Main execution code (Sysop frontpanel)

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         DATA     1024

* Main job's variables

         OFFSET   0

M_SETUP  DS.B     S_LEN
MQSPILVC DS.L     1        QSPIL vector
MLOGCHAN DS.L     1        Log window ID
SIGNWND  DS.L     1        Signon window ID
LINEJOB  DS.L     1        Line server job ID
LOCALJOB DS.L     1        Local server job ID
SERCHAN  DS.L     1        Serial channel ID
WIN_POS  DS.W     4        Window size & cursor position
YELLMOD  DS.B     1        Yell off (0) or on (<>0)
O_LOCAL  DS.B     1        Local switch from commandline (0 = off)
O_NOTMCK DS.B     1
O_MONLY  DS.B     1
S_DIR    DS.B     50
         DS.W     0
MAINBUF  DS.B     80       Buffer for various purposes

         XREF     ITOD.W,STARTSUB,SKIPSPC,TOUPPER,OPEN_SUB,EXEC,WRITE$,WRITEL$
         XREF     DO_INP,DO_OUTP,CALLSPIL,SPEEDS,NOBEEP,PAUSE,TXMSG,TXSTR
         XREF     USLVTBL

         SECTION  CODE

QB_BASE  JMP      START
M$       EQU      QB_BASE+$8000
         DC.W     $4AFB,$4AFB
         STRING$  {'QBOX'}

SIGNWIN  STRING$  'CON_452X42A30X12'
LOGWIN   STRING$  'SCR_452X162A30X54'
PIPE_OUT STRING$  'PIPE_80'
PIPE_IN  STRING$  'PIPE'
CON_PARM DC.B     4,1,0,7

         XDEF     USLSTFNM,LSTRDFNM,MAREAFNM,FAREAFNM,MSG_FNAM,LOGINFNM
         XDEF     BUL_FNAM,NBULFNAM,NOTFDFNM,ED_FNAM,INF_FNAM,INF0FNAM
         XDEF     LOGOUTFN,DIR_FNAM,NWUSFNAM,TWITFNAM,NMAILFNM,QUESTFNM
         XDEF     QRESLTFN,CON_PARM,NMSGFNAM,ORIGFNAM,TMSGFNAM,NDLSTFNM

SETUPFNM STRING$  'SETUP_BBS'
USLSTFNM STRING$  'USERS_BBS'
LSTRDFNM STRING$  'LASTREAD_BBS'
MAREAFNM STRING$  'MAREAS_BBS'
FAREAFNM STRING$  'FAREAS_BBS'
MSG_FNAM STRING$  'MESSAGES_BBS'
LOGINFNM STRING$  'LOGON_BBS'
BUL_FNAM STRING$  'BULLETIN_BBS'
NBULFNAM STRING$  'NEWBUL_BBS'
NMSGFNAM STRING$  'NEWLOG_BBS'
NOTFDFNM STRING$  'NOTFOUND_BBS'
ED_FNAM  STRING$  'EDITORIAL_BBS'
INF_FNAM STRING$  'INFO_BBS'
INF0FNAM STRING$  'INFO00_BBS'
LOGOUTFN STRING$  'LOGOFF_BBS'
DIR_FNAM STRING$  'FILES_BBS'
NWUSFNAM STRING$  'NEWUSERS_BBS'
TWITFNAM STRING$  'TWITMSG_BBS'
NMAILFNM STRING$  'NEWMAIL_BBS'
QUESTFNM STRING$  'QUESTION_BBS'
QRESLTFN STRING$  'QRESULT_BBS'
NDLSTFNM STRING$  'NODELIST_BBS'
ORIGFNAM STRING$  'ORIGIN'
TMSGFNAM STRING$  'MSG_TMP'
         DS.W     0

START    ADDA.L   A4,A6
         MOVE.L   A6,A0
         MOVE.W   #MAINBUF-M_SETUP,D0
CLR_VARS CLR.L    (A0)+
         SUBQ.W   #4,D0
         BHI      CLR_VARS
         MOVE.W   (A7)+,D0
         LSL.W    #2,D0
         LEA      (A7,D0.W),A0
         MOVE.L   A0,A1
         MOVE.L   A0,A2
         WRITE$
         MOVE.B   #LF,(A1)
         MOVE.L   A2,A1
QBOX_OPT JSR      SKIPSPC
         BEQ.S    LD_SETUP
         CMPI.B   #'-',(A1)+
         BNE.S    LD_SETUP
         MOVE.B   (A1),D1
         CMPI.B   #LF,D1
         BEQ.S    LD_SETUP
         ADDQ.W   #1,A1
         JSR      TOUPPER
         CMPI.B   #'L',D1
         BNE.S    OPT_2
         ST       O_LOCAL(A6)
         BRA.S    OPT_SKIP
OPT_2    CMPI.B   #'T',D1
         BNE.S    OPT_3
         ST       O_NOTMCK(A6)
         BRA.S    OPT_SKIP
OPT_3    CMPI.B   #'M',D1
         BNE.S    OPT_4
         ST       O_MONLY(A6)
         BRA.S    OPT_SKIP
OPT_4    CMPI.B   #'D',D1
         BNE.S    OPT_SKIP
         JSR      SKIPSPC
         BEQ      QBOX_OPT
         LEA      S_DIR+2(A6),A0
         MOVEQ    #0,D1
OPT_4LP  MOVE.B   (A1)+,(A0)+
         ADDQ.W   #1,D1
         CMPI.W   #35,D1
         BGE.S    OPT_4END
         CMPI.B   #' ',(A1)
         BHI      OPT_4LP
OPT_4END MOVE.W   D1,S_DIR(A6)
OPT_SKIP CMPI.B   #' ',(A1)
         BLS      QBOX_OPT
         ADDQ.W   #1,A1
         BRA      OPT_SKIP

LD_SETUP LEA      S_DIR(A6),A1
         TST.W    (A1)
         BEQ.S    LD_SETP
         LEA      SETUPFNM,A0
         LEA      MAINBUF(A6),A2
         MOVEQ    #IO.SHARE,D3
         JSR      OPEN_SUB
         BEQ.S    LD_SET2
LD_SETP  QDOS     MT.INF
         MOVE.L   $AC(A0),A1
         MOVE.L   A1,D0
         BEQ.S    LD_SETD
         LEA      SETUPFNM,A0
         LEA      MAINBUF(A6),A2
         MOVEQ    #IO.SHARE,D3
         JSR      OPEN_SUB
         BEQ.S    LD_SET2
LD_SETD  QDOS     MT.INF
         MOVE.L   $B0(A0),A1
         MOVE.L   A1,D0
         BEQ.S    LDS_ERR1
         LEA      SETUPFNM,A0
         LEA      MAINBUF(A6),A2
         MOVEQ    #IO.SHARE,D3
         JSR      OPEN_SUB
         BEQ.S    LD_SET2
LDS_ERR1 MOVE.L   D0,D4
         SUBA.L   A0,A0
         PRINT    {'QBOX: Unable to locate setup file',LF}
         BRA      S_ABORT
LD_SET2  MOVEQ    #12,D2
         MOVEQ    #-1,D3
         LEA      M_SETUP(A6),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    LDS_ERR2
         CMPI.L   #FINGERPR,M_SETUP(A6)
         BNE.S    LDS_ERR3
         CMPI.W   #COMPREV,S_COMPRV(A6)
         BNE.S    LDS_ERR3
         MOVE.L   S_TOTLEN(A6),D2
         CMPI.L   #S_LEN,D2
         BLS.S    LD_SET3
         MOVE.L   #S_LEN,D2
LD_SET3  SUBI.W   #12,D2
         QDOS     IO.FSTRG
         TST.L    D0
         BEQ.S    CHK_TIME
LDS_ERR2 MOVE.L   D0,D4
         QDOS     IO.CLOSE
         SUBA.L   A0,A0
         PRINT    {'QBOX: I/O Error loading setup file: '}
         BRA      S_ABORT
LDS_ERR3 QDOS     IO.CLOSE
         SUBA.L   A0,A0
         PRINT    {'QBOX: Incompatible setup file version',LF}
         MOVEQ    #0,D4
         BRA      S_ABORT

CHK_TIME QDOS     IO.CLOSE
         LEA      M$,A0
         MOVE.L   A0,(A6)
         MOVE.B   S_YELL(A6),YELLMOD(A6)
         TST.B    O_NOTMCK(A6)
         BNE.S    DATE_OK
         MOVEQ    #IO.SHARE,D3
         LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         LEA      MAINBUF(A6),A2
         JSR      OPEN_SUB
         BNE.S    DATE_OK
         MOVEQ    #$40,D2
         MOVEQ    #-1,D3
         LEA      MAINBUF(A6),A1
         QDOS     FS.HEADR
         MOVE.L   D0,D4
         QDOS     IO.CLOSE
         TST.L    D4
         BNE.S    DATE_OK
         QDOS     MT.RCLCK
         SUB.L    MAINBUF+$34(A6),D1
         CMPI.L   #365*24*60*60,D1
         BLS.S    DATE_OK
         SUBA.L   A0,A0
         PRINT    {'QBOX: Wrong clock setting',LF}
         BRA      S_ABORT
DATE_OK  TST.B    S_LOCAL(A6)
         BNE.S    ISLOCAL
         TST.B    O_LOCAL(A6)
         BEQ.S    NOTLOCAL
ISLOCAL  ST       O_LOCAL(A6)
         ST       D7
         BSR      LOC_CHAT
         BRA      QBOXEXIT
NOTLOCAL MOVEQ    #IO.SHARE,D3
         LEA      S_QSPIL(A6),A0
         LEA      S_SYSDIR(A6),A1
         LEA      MAINBUF(A6),A2
         BSR      OPEN_SUB
         MOVE.L   D0,D4
         IF NE THEN
            SUBA.L   A0,A0
            PRINT    {'QBOX: Can''t find QSPIL driver '}
            LEA      MAINBUF(A6),A1
            JSR      (A2)
            MOVEQ    #LF,D1
            QDOS     IO.SBYTE
            BRA.S    S_ABORT
         ENDIF
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      MAINBUF(A6),A1
         QDOS     FS.HEADR
         MOVE.L   D0,D4
         BNE.S    QSP_IOER
         MOVE.L   -(A1),D1
         MOVEQ    #-1,D2
         MOVEM.L  D1/D3/A0,-(A7)
         QDOS     MT.ALCHP
         MOVE.L   A0,A1
         MOVEM.L  (A7)+,D2/D3/A0
         MOVE.L   D0,D4
         IF NE THEN
            QDOS     IO.CLOSE
            SUBA.L   A0,A0
            PRINT    {'QBOX: No memory for QSPIL',LF}
            BRA.S    S_ABORT
         ENDIF
         MOVE.L   A1,MQSPILVC(A6)
         QDOS     FS.LOAD
         MOVE.L   D0,D4
         QDOS     IO.CLOSE
         TST.L    D4
         BNE.S    QSP_IOER
         MOVE.L   MQSPILVC(A6),A2
         MOVEQ    #SP.INIT,D0
         MOVEQ    #-1,D1
         MOVEQ    #0,D7
         JSR      (A2)
         MOVE.L   D0,D4
         BEQ.S    SER_OK
         SUBA.L   A0,A0
         PRINT    {'QBOX: QSPIL initialisation error',LF}
         BRA.S    S_ABORT
QSP_IOER SUBA.L   A0,A0
         PRINT    {'QBOX: QSPIL file I/O error',LF}
S_ABORT  MOVE.L   D4,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         MOVEQ    #-1,D1
         MOVE.L   D4,D3
         QDOS     MT.FRJOB
SER_OK   MOVE.L   A0,SERCHAN(A6)
         LEA      SIGNWIN,A0
         LEA      CON_PARM,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         MOVE.L   D0,D4
         IF NE THEN
            SUBA.L   A0,A0
            PRINT    {'QBOX: Unable to open console window',LF}
            BRA      S_ABORT
         ENDIF
         MOVE.L   A0,SIGNWND(A6)
         LEA      LOGWIN,A0
         LEA      CON_PARM,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         MOVE.L   D0,D4
         IF NE THEN
            SUBA.L   A0,A0
            PRINT    {'QBOX: Unable to open log window',LF}
            BRA      S_ABORT
         ENDIF
         MOVE.L   A0,MLOGCHAN(A6)
         BSR      MKQBOXJB
         MOVE.L   D0,D4
         IF NE THEN
            SUBA.L   A0,A0
            PRINT    {'QBOX: Unable to start',LF}
            BRA      S_ABORT
         ENDIF
         MOVE.L   D1,LINEJOB(A6)
         MOVE.B   #1,LINENR(A2)
         SF       LOCALMOD(A2)
         SF       NOLOG(A2)
         MOVE.L   SERCHAN(A6),A0
         MOVE.L   A0,COM_IN(A2)
         MOVE.L   A0,COM_OUT(A2)
         MOVE.L   MQSPILVC(A6),QSPILVEC(A2)
         BSR      SIGNON
         MOVE.L   LINEJOB(A6),D1
         MOVEQ    #32,D2
         MOVEQ    #0,D3
         QDOS     MT.ACTIV
         BRA.S    WAITKEY
WAIT_SIG BSR      SIGNON
         BRA.S    WAITKEY
WAIT_STA BSR      DISPSTAT
WAITKEY  MOVEM.W  WIN_POS+4(A6),D1-D2
         MOVEQ    #-1,D3
         MOVE.L   SIGNWND(A6),A0
         QDOS     SD.POS
         QDOS     SD.CURE
         MOVE.W   #60*50,D3
         QDOS     IO.FBYTE
         MOVEM.L  D0/D1,-(A7)
         QDOS     SD.CURS
         MOVEM.L  (A7)+,D0/D1
         TST.L    D0
         BNE      WAIT_STA
         CMPI.B   #$F8,D1
         BEQ      WAIT_SIG
         CMPI.B   #$C0,D1
         BEQ      TM_MIN1
         CMPI.B   #$C8,D1
         BEQ      TM_PLUS1
         CMPI.B   #$D0,D1
         BEQ      TM_PLUS5
         CMPI.B   #$D8,D1
         BEQ      TM_MIN5
         ANDI.B   #$DF,D1
         CMPI.B   #'L',D1
         BEQ      LOC_EDIT
         CMPI.B   #'C',D1
         BEQ      TRY_CHAT
         CMPI.B   #'S',D1
         BEQ      CHG_LEVL
         CMPI.B   #'Q',D1
         BEQ.S    QBXQUIT
         CMPI.B   #'Y',D1
         BNE      WAIT_STA
         TST.B    YELLMOD(A6)
         SEQ      YELLMOD(A6)
         BSR      GETJBAD
         MOVE.B   YELLMOD(A6),YELLFLG(A0)
WAIT_PRM BSR      FLIPYELL
         BRA      WAIT_STA
QBXQUIT  BSR      GETJBAD
         MOVE.B   ONLINE(A0),-(A7)
         MOVE.L   COM_OUT(A0),A0
         BNE.S    QBXQUIT2
         MOVE.L   D1,-(A7)
         MOVEQ    #0,D2
         QDOS     MT.JINF
         MOVE.L   (A7)+,D1
         MOVE.L   $40-$68(A0),A0
QBXQUIT2 MOVE.L   A0,-(A7)
         QDOS     MT.FRJOB
         MOVE.L   (A7)+,A0
         MOVE.B   (A7)+,D1
         MOVEQ    #SP.CLOSE,D0
         SUBA.L   A4,A4
         MOVE.L   MQSPILVC(A6),A5
         MOVEQ    #0,D7
         JSR      (A5)
         MOVEQ    #0,D0
QBOXEXIT MOVE.L   D0,D3
         MOVEQ    #-1,D1
         QDOS     MT.FRJOB

TM_MIN1  MOVEQ    #-1,D1
         BRA.S    TM_CHG
TM_PLUS1 MOVEQ    #1,D1
         BRA.S    TM_CHG
TM_MIN5  MOVEQ    #-5,D1
         BRA.S    TM_CHG
TM_PLUS5 MOVEQ    #5,D1
TM_CHG   MOVE.W   D1,-(A7)
         BSR      GETJBAD
         MOVE.W   (A7)+,D1
         CMPI.B   #ISHUMAN,ONLINE(A0)
         BNE      WAITKEY
         ADD.W    D1,TIMELEFT(A0)
         BRA      WAIT_STA

CHG_LEVL BSR      GETJBAD
         MOVE.L   A0,A2
         CMPI.B   #ISHUMAN,ONLINE(A2)
         BNE      WAITKEY
         MOVEQ    #0,D1
         MOVEQ    #3,D2
         MOVEQ    #-1,D3
         MOVE.L   SIGNWND(A6),A0
         QDOS     SD.POS
         QDOS     SD.CLRLN
         LOAD$    {'New security level (Twit/Disgrace/Normal/Special/Extra/Cosysop/sysOp): '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         MOVE.B   D1,D2
         QDOS     SD.CURS
         CMPI.B   #ESC,D2
         BEQ      WAIT_PRM
         MOVEQ    #$DF-256,D1
         AND.B    D2,D1
         LEA      LEVL_TAB-1,A1
GET_LVLL ADDQ.L   #1,A1
         MOVE.B   (A1)+,D0
         BEQ      CHG_LEVL
         CMP.B    D0,D1
         BNE      GET_LVLL
         ANDI.B   #US.HELPL,USERBUF+US_LEVEL(A2)
         MOVEQ    #0,D0
         MOVE.B   (A1),D0
         OR.B     D0,USERBUF+US_LEVEL(A2)
         ADD.W    D0,D0
         LEA      S_DTIME(A6),A0
         MOVE.W   (A0,D0.W),D3
         QDOS     MT.RCLCK
         SUB.L    USERBUF+US_LSTLG(A2),D1
         DIVU     #60,D1
         SUB.W    D1,D3
         SUB.W    USERBUF+US_DAYTM(A2),D3
         IF MI THEN
            MOVEQ    #0,D3
         ENDIF
         MOVE.W   D3,TIMELEFT(A2)
         BRA      WAIT_PRM

LEVL_TAB DC.B     'T',LV.TWIT,'D',LV.DISGR,'N',LV.NORM,'S',LV.SPEC
         DC.B     'E',LV.EXTRA,'C',LV.COSYS,'O',LV.SYSOP,0,0

MKQBOXJB MOVE.L   #BUFSZ+4096,D3
         LEA      STARTSUB,A1
         BSR.S    MAKE_JOB
         BNE.S    MKQ_ERR
         MOVE.L   A2,A0
         MOVE.W   #BUFFER,D0
MKQ_CLR  CLR.L    (A0)+
         SUBQ.W   #4,D0
         BHI      MKQ_CLR
         LEA      M_SETUP(A6),A0
         LEA      SETUP(A2),A1
         MOVE.W   #S_LEN-1,D0
MKQ_LP   MOVE.B   (A0)+,(A1)+
         DBF      D0,MKQ_LP
         MOVE.L   MLOGCHAN(A6),LOGCHAN(A2)
         MOVE.W   #BUFSZ-1,BUFSIZE(A2)
         MOVE.B   YELLMOD(A6),YELLFLG(A2)
         SF       ONLINE(A2)
         SF       RINGBACK(A2)
         MOVE.L   D1,-(A7)
         QDOS     MT.INF
         MOVE.L   D1,OWNERJOB(A2)
         MOVE.L   (A7)+,D1
         MOVEQ    #0,D0
MKQ_ERR  RTS

MAKE_JOB MOVEQ    #-1,D1
         MOVEQ    #11,D2
         ADD.W    8(A1),D2
         BCLR     #0,D2
         MOVE.L   A1,-(A7)
         SUBA.L   A1,A1
         QDOS     MT.CJOB
         MOVE.L   (A7)+,A1
         TST.L    D0
         BNE.S    MJ_ERR
         MOVE.L   A0,A2
         MOVE.W   #$4EF9,(A2)+
         MOVE.L   A1,(A2)+
         ADDQ.W   #6,A1
         SUBQ.L   #6,D2
MJ_COPY  MOVE.W   (A1)+,(A2)+
         SUBQ.L   #2,D2
         BNE      MJ_COPY
MJ_ERR   RTS

GETJBAD  MOVE.L   LINEJOB(A6),D1
GETJBADL MOVE.L   D1,-(A7)
         MOVEQ    #0,D2
         QDOS     MT.JINF
         MOVEQ    #11,D1
         ADD.W    8(A0),D1
         BCLR     #0,D1
         ADDA.W   D1,A0
         MOVE.L   (A7)+,D1
         RTS

TRY_CHAT BSR      GETJBAD
         CMPI.B   #ISHUMAN,ONLINE(A0)
         BNE      WAITKEY
         LEA      NOBEEP,A3
         QDOS     MT.IPCOM
         SF       D7
         BRA.S    CL_LOG

LOC_EDIT ST       D7
CL_LOG   QDOS     SD.CURS
         BSR.S    LOC_CHAT
         BRA      WAIT_STA

* Enter Local mode (D7.B <> 0) or Chat mode (D7.B = 0)
* Entry: A5 start addr of terminal emulator

LOC_CHAT TST.B    D7
         BEQ.S    EXE_TERM
         BSR      MKQBOXJB
         IF NE THEN
            LOAD$    {'Unable to start local server',LF},A1
            BRA      DSPERROR
         ENDIF
         MOVE.L   D1,LOCALJOB(A6)
         MOVE.B   #2,LINENR(A2)
         ST       LOCALMOD(A2)
         ST       NOLOG(A2)
         CLR.L    QSPILVEC(A2)
         TST.B    O_LOCAL(A6)
         BNE.S    EXE_TERM
         BSR      GETJBAD
         ST       NOLOG(A0)
EXE_TERM MOVEQ    #32,D6
         LEA      S_TERM(A6),A0
         SUBA.L   A2,A2
         LEA      CHAT_PIP,A3
         TST.B    D7
         IF NE THEN
            LEA      LOC_PIP,A3
         ENDIF
         MOVE.W   D7,-(A7)
         MOVEQ    #0,D7
         JSR      EXEC
         MOVE.W   (A7)+,D7
         TST.L    D0
         BEQ.S    TST_CHT
         TST.B    D7
         BEQ.S    EXET_ERR
         MOVE.L   LOCALJOB(A6),D1
         QDOS     MT.FRJOB
EXET_ERR LOAD$    {'Unable to execute terminal emulator',LF},A1
         BSR.S    DSPERROR
         BRA.S    REST_LOG
TST_CHT  TST.B    D7
         BEQ      GO_CHAT
         MOVE.L   LOCALJOB(A6),D1
         MOVEQ    #32,D2
         MOVEQ    #-1,D3
         QDOS     MT.ACTIV
         MOVEQ    #0,D0
REST_LOG TST.B    O_LOCAL(A6)
         IF EQ THEN
            MOVE.L   D0,-(A7)
            BSR      GETJBAD
            SF       NOLOG(A0)
            MOVE.L   (A7)+,D0
         ENDIF
         RTS

DSPERROR MOVE.L   SIGNWND(A6),A0
         MOVE.L   D0,-(A7)
         MOVE.L   A1,-(A7)
         MOVE.L   A0,D0
         BEQ.S    DSPE_0
         MOVEQ    #-1,D3
         QDOS     SD.CLRLN
         MOVEQ    #0,D1
         QDOS     SD.TAB
         MOVE.L   (A7)+,A1
         MOVE.W   (A1)+,D2
         SUBQ.W   #1,D2
         QDOS     IO.SSTRG
         LOAD$    {' - press any key '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         QDOS     SD.CURE
         QDOS     IO.FBYTE
         BRA.S    DSPE_END
DSPE_0   LOAD$    {'QBOX: '},A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVE.L   (A7)+,A1
         JSR      (A2)
DSPE_END MOVE.L   (A7)+,D0
         RTS

* Set up pipes for local login

LOC_PIP  MOVE.L   D1,D4             Terminal job ID goes to D4
         MOVE.L   LOCALJOB(A6),D1
         BSR      GETJBADL          Get job ID and base addr of local server
         MOVE.L   A0,A2
         MOVEQ    #0,D3
         LEA      PIPE_OUT,A0
         QDOS     IO.OPEN
         MOVE.L   A0,COM_OUT(A2)    Open its output channel
         EXG      D1,D4
         MOVEQ    #0,D3
         LEA      PIPE_OUT,A0       Switch job IDs and open output for terminal
         QDOS     IO.OPEN
         MOVE.L   A0,-(A5)
         ADDQ.W   #1,D5
         EXG      D1,D4
         MOVE.L   A0,D3             Pass the ID on to the input channel for
         LEA      PIPE_IN,A0        the local server
         QDOS     IO.OPEN
         MOVE.L   A0,COM_IN(A2)
         EXG      D1,D4
         MOVE.L   COM_OUT(A2),D3    Finally open the terminal's input channel
         LEA      PIPE_IN,A0        using the local server's output ch ID
         QDOS     IO.OPEN
         MOVE.L   A0,-(A5)          Push ID onto the terminal's stack
         ADDQ.W   #1,D5
         MOVEQ    #0,D0
         RTS

SIGNON   MOVEQ    #-1,D1
         MOVEQ    #-1,D2
         QDOS     MT.DMODE
         TST.B    D1
         IF NE THEN
            MOVEQ    #0,D1
            MOVEQ    #-1,D2
            QDOS     MT.DMODE
         ENDIF
         LEA      CON_PARM,A2
         MOVEQ    #-1,D3
         MOVE.L   MLOGCHAN(A6),A0
         MOVE.B   (A2),D1
         MOVEQ    #0,D2
         MOVE.B   1(A2),D2
         QDOS     SD.BORDR
         QDOS     SD.CLEAR
         MOVE.L   SIGNWND(A6),A0
         MOVE.B   (A2),D1
         QDOS     SD.BORDR
         QDOS     SD.CLEAR
         PRINT    {'QBOX Bulletin Board System  v[version]   Copyright 1987-94 Jan Bredenbeek'}
FLIPYELL MOVEQ    #-1,D3
         MOVE.L   SIGNWND(A6),A0
         MOVEQ    #0,D1
         MOVEQ    #3,D2
         QDOS     SD.POS
         QDOS     SD.CLRLN
         PRINT    {$5B,'L]ogin  ',$5B,'C]hat  ',$5B,'S]ec. Level  ',$5B,'Q]uit  ',$5B,'Y]ell alarm ('}
         TST.B    YELLMOD(A6)
         IF NE THEN
            PRINT    'ON'
         ELSE
            PRINT    'OFF'
         ENDIF
         PRINT    {')  ',$5B,'¼½¾¿]Time >'}
         LEA      WIN_POS(A6),A1
         QDOS     SD.CHENQ

DISPSTAT BSR      GETJBAD
         MOVE.L   A0,A2
         LEA      MAINBUF(A6),A1
         WRITE$   {'Status: '},A1
         MOVE.B   ONLINE(A2),D0
         BNE.S    DS_ONLIN
         WRITE$   {'Idle - waiting for '},A1
         TST.B    RINGBACK(A2)
         IF EQ THEN
            WRITE$   {'call'},A1
         ELSE
            WRITE$   {'call-back'},A1
         ENDIF
DS_1LINE MOVEQ    #1,D2
         BSR      DS_DISP
         LEA      MAINBUF(A6),A1
         MOVEQ    #2,D2
         BRA      DS_DISP
DS_ONLIN SUBQ.B   #ISHUMAN,D0
         BEQ.S    DS_HUMAN
         LOAD$    {'FAX session'},A0
         SUBQ.B   #OUTMAIL-ISHUMAN,D0
         BGT.S    DS_WRITE
         LOAD$    {'Inbound mail session'},A0
         BLT.S    DS_WRITE
         LOAD$    {'Outbound mail session'},A0
DS_WRITE WRITE$
         BRA      DS_1LINE
DS_HUMAN LEA      USERBUF+US_NAME(A2),A0
         BSR      DS_STR
         WRITE$   {' of '},A1
         LEA      USERBUF+US_CITY(A2),A0
         BSR      DS_STR
         WRITE$   {' online at '},A1
         MOVE.B   BPS(A2),D0
         EXT.W    D0
         ADD.W    D0,D0
         MOVE.L   (A6),A0
         LEA      SPEEDS-M$(A0),A0
         ADDA.W   (A0,D0.W),A0
         MOVE.W   (A0)+,D0
         BSR      DS_STR3
         WRITE$   {' bps'}
         MOVEQ    #1,D2
         BSR.S    DS_DISP
         LEA      MAINBUF(A6),A1
         WRITE$   {'Sec. Level: '}
         LEA      USLVTBL,A0
         MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A2),D0
         ADD.W    D0,D0
         ADDA.W   (A0,D0.W),A0
         WRITE$
         WRITE$   {'  Time left: '}
         QDOS     MT.RCLCK
         SUB.L    USERBUF+US_LSTLG(A2),D1
         DIVU     #60,D1
         MOVE.W   TIMELEFT(A2),D0
         EXG      D0,D1
         SUB.W    D0,D1
         IF LT THEN
            MOVEQ    #0,D1
         ENDIF
         MOVEQ    #0,D2
         JSR      ITOD.W
         WRITE$   {' minutes'}
         MOVEQ    #2,D2
DS_DISP  MOVE.L   A1,-(A7)
         MOVEQ    #0,D1
         MOVEQ    #0,D3
         MOVE.L   SIGNWND(A6),A0
         QDOS     SD.POS
         MOVE.L   (A7)+,D2
         LEA      MAINBUF(A6),A1
         SUB.L    A1,D2
         QDOS     IO.SSTRG
         QDOS     SD.CLRRT
DS_END   RTS

DS_STR   MOVEQ    #0,D0
         MOVE.B   (A0)+,D0
         BRA.S    DS_STR3
DS_STR2  MOVE.B   (A0)+,(A1)+
DS_STR3  DBF      D0,DS_STR2
         RTS

CHAT_PIP MOVEQ    #0,D3
         LEA      PIPE_OUT,A0
         QDOS     IO.OPEN
         MOVE.L   A0,-(A5)
         ADDQ.W   #1,D5
         MOVE.L   D1,D4
         MOVEQ    #-1,D1
         MOVE.L   A0,D3
         LEA      PIPE_IN,A0
         QDOS     IO.OPEN
         MOVE.L   A0,MAINBUF(A6)
         MOVEQ    #0,D3
         LEA      PIPE_OUT,A0
         QDOS     IO.OPEN
         MOVE.L   A0,MAINBUF+4(A6)
         MOVE.L   D4,D1
         MOVE.L   A0,D3
         LEA      PIPE_IN,A0
         QDOS     IO.OPEN
         MOVE.L   A0,-(A5)
         ADDQ.W   #1,D5
         MOVEQ    #0,D0
         RTS

GO_CHAT  MOVE.L   LINEJOB(A6),D1
         MOVEM.L  MAINBUF(A6),D5-D6
CHATWAIT BSR      GETJBAD
         TST.L    D3
         BGE      CHATWAIT
         TST.B    WAITCHAR(A0)
         BEQ      CHATWAIT
         MOVE.L   A6,-(A7)
         PEA      MAINBUF(A6)
         MOVE.L   A0,A6
         MOVEQ    #0,D2
         QDOS     MT.PRIOR
         QDOS     MT.RELJB
         QDOS     MT.RCLCK
         MOVE.L   D1,D7
         LEA      CHATIN1,A2
         LEA      CHATOUT1,A3
         LEA      CHATIN2,A4
         LEA      CHATOUT2,A5
         TXMSG    {'*** Sysop breaking in for a chat ***'}
         MOVEQ    #0,D4
CHAT_LP  BSR.S    CHAT_SUB
         BEQ.S    CHAT_E1
         EXG      A2,A4
         EXG      A3,A5
         BSR.S    CHAT_SUB
         EXG      A2,A4
         EXG      A3,A5
         BEQ.S    CHAT_E2
         MOVEQ    #2,D3
         JSR      PAUSE
         BRA      CHAT_LP

CHAT_E1  MOVE.L   D6,A0
         PRINT    {CR,LF,LF,'*** LINE DISCONNECTED; PLEASE END CHAT MODE ***',CR,LF,LF}
         MOVE.L   D5,A0
         MOVEQ    #-1,D3
         REPEAT
            QDOS     IO.FBYTE
         UNTIL D0 EQ.L #ERR.EF
         ST       CHATFLG(A6)
         BRA.S    CHAT_END
CHAT_E2  MOVE.B   #1,CHATFLG(A6)
         TXMSG    {'*** Chat ended, returning to BBS ***'}
CHAT_END MOVE.L   D5,A0
         QDOS     IO.CLOSE
         MOVE.L   D6,A0
         QDOS     IO.CLOSE
         QDOS     MT.RCLCK
         SUB.L    D7,D1
         DIVU     #60,D1
         ADD.W    D1,TIMELEFT(A6)
         SUB.W    D1,USERBUF+US_DAYTM(A6)
         ADDQ.W   #4,A7
         MOVE.L   (A7)+,A6
         MOVE.L   LINEJOB(A6),D1
         MOVEQ    #32,D2
         QDOS     MT.PRIOR
         MOVEQ    #0,D0
         RTS

CHAT_SUB MOVEQ    #0,D2
         MOVE.L   4(A7),A1
         ADDA.W   D4,A1
CS_LOOP  JSR      (A2)
         CMPI.L   #ERR.EF,D0
         BEQ      CS_END
         ADDQ.L   #1,D0
         BEQ      CS_OUT
         ANDI.B   #$7F,D1
         IF D1 EQ.B #BS OR D1 EQ.B #DEL THEN
            TST.W    D4
            BEQ      CS_LOOP
            BSR      CS_OUT
            LOAD$    {BS,' ',BS},A1
            MOVE.W   (A1)+,D2
            BSR      CS_OUT2
            SUBQ.W   #1,D4
            BRA      CHAT_SUB
         ENDIF
         IF D1 EQ.B #CR THEN
            BSR.S    CS_OUT
            LOAD$    {CR,LF},A1
            MOVE.W   (A1)+,D2
            BSR.S    CS_OUT2
            MOVEQ    #0,D4
            BRA      CHAT_SUB
         ENDIF
         CMP.B    USERBUF+US_WIDTH(A6),D4
         IF HS THEN
            MOVE.W   D1,-(A7)
            BSR.S    CS_OUT
            ADDA.W   D2,A1
            MOVEQ    #0,D2
CS_FSP      CMPI.B   #' ',-(A1)
            BEQ.S    CS_SPF
            ADDQ.W   #1,D2
            SUBQ.W   #1,D4
            BGT      CS_FSP
            MOVEQ    #0,D2
CS_SPF      PEA      1(A1)
            MOVE.W   D2,D4
            BEQ.S    CS_CRLF
            ADDQ.W   #1,D4
            BCLR     #0,D4
            SUBA.W   D4,A7
            MOVE.L   A7,A1
            MOVE.W   D2,D0
            REPEAT
               MOVE.B   #BS,(A1)+
               SUBQ.W   #1,D0
            UNTIL    EQ
            BSR.S    CS_OUT
            MOVE.W   D2,D0
            REPEAT
               MOVE.B   #' ',(A1)+
               SUBQ.W   #1,D0
            UNTIL    EQ
            BSR.S    CS_OUT
            ADDA.W   D4,A7
            MOVE.W   D2,D4
CS_CRLF     LOAD$    {CR,LF},A1
            MOVE.W   (A1)+,D2
            BSR.S    CS_OUT2
            MOVE.L   (A7)+,A0
            MOVE.L   6(A7),A1
            MOVE.W   D4,D0
            IF NE THEN
               REPEAT
                  MOVE.B   (A0)+,(A1)+
                  SUBQ.W   #1,D0
               UNTIL    LE
            ENDIF
            MOVE.W   D4,D2
            MOVE.W   (A7)+,D1
         ENDIF
         MOVE.B   D1,(A1)+
         ADDQ.W   #1,D2
         ADDQ.W   #1,D4
         BRA      CS_LOOP
CS_OUT   SUBA.W   D2,A1
CS_OUT2  TST.W    D2
         IF NE THEN
            JSR      (A3)
            JSR      (A5)
         ENDIF
         MOVEQ    #1,D0
CS_END   RTS

CHATIN1  MOVEQ    #0,D3
         MOVEQ    #SP.FBYTE,D0
         JMP      DO_INP

CHATOUT1 MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         SUBA.W   D1,A1
         RTS

CHATIN2  MOVE.L   D5,A0
         MOVEQ    #0,D3
         MOVE.L   A1,-(A7)
         QDOS     IO.FBYTE
         MOVE.L   (A7)+,A1
         RTS

CHATOUT2 MOVE.L   D6,A0
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         SUBA.W   D1,A1
         RTS

         END
