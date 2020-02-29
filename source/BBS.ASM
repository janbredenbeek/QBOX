* QBOX BULLETIN BOARD SYSTEM
*
* Copyright (C) 1987-1994 by Jan Bredenbeek, Hilversum, Holland
*
*
* Main BBS-handling code

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         DATA     0

         XREF     USLSTFNM,LSTRDFNM,MAREAFNM,FAREAFNM,MSG_FNAM,LOGINFNM
         XREF     BUL_FNAM,NBULFNAM,NOTFDFNM,ED_FNAM,INF_FNAM,INF0FNAM
         XREF     LOGOUTFN,DIR_FNAM,NWUSFNAM,TWITFNAM,NMSGFNAM,QUESTFNM
         XREF     QRESLTFN,NMAILFNM
         XREF     FILES,DATE$,ITOD.W,ITOD.L,USERPARM,MAILBOX,WRITEMSG
         XREF     DIVLONG,GETTIME,FINDUSER,WR_USER,USERLIST,YESNO,NOYES
         XREF     TOUPPER,INPUT,GETNAM1,GETNAM2,CMPNAME,COPYNAME,WRITEERR
         XREF     PRINTNAM,PRINTNM1,GETLINE,READNUM,MAREAMSG,SET_AREA
         XREF     CHK_AREA,PURGE_LP,SET1MIN,CHKTIMER,GETCHR1,DO_INBND
         XREF     EXEC,EXT_CMDL,EXT_CHAN,EXT_RET,WRITE$,WRITEL$

         SECTION  CODE

* Transmit character, CR+LF, LF

         XDEF     TXCRLF,TXLF,TXCHAR

TXCRLF   TST.B    SPEC_OUT(A6)
         BNE.S    TXLF
         MOVEQ    #CR,D1
         BSR.S    TXCHAR
TXLF     MOVEQ    #LF,D1
TXCHAR   MOVEM.L  D1/A1,-(A7)
         MOVEQ    #SP.SBYTE,D0
         BSR.S    DO_OUTP
         MOVEM.L  (A7)+,D1/A1
         RTS

* Transmit message

         XDEF     TXMSG

TXMSG    MOVE.L   A1,-(A7)
         TXSTR    {CR,LF,LF}
         MOVE.L   (A7)+,A1
         BSR.S    TXSTR
         TXSTR    {CR,LF,LF}
         RTS

         XDEF     TXSTR

TXSTR    MOVEM.L  D1-D2/A1,-(A7)
         MOVE.W   (A1)+,D2
         MOVEQ    #SP.SSTRG,D0
         BSR.S    DO_OUTP
         MOVEM.L  (A7)+,D1-D2/A1
         RTS

* Various output functions

         XDEF     FLUSH,DUMP_OPB,DO_OUTP

FLUSH    MOVEQ    #SP.FLUSH,D0
         BRA.S    DO_OUTP
DUMP_OPB MOVEQ    #SP.DUMP,D0
DO_OUTP  MOVEM.L  D3/A0,-(A7)
         MOVEQ    #-1,D3
         TST.B    SPEC_OUT(A6)
         BNE.S    DO_OUT1
         MOVE.L   COM_OUT(A6),A0
         TST.B    LOCALMOD(A6)
         BNE.S    DO_OUT2
         BSR.S    CALLSPIL
         BRA.S    DO_OUT3
DO_OUT1  MOVE.L   INPCHAN(A6),A0
DO_OUT2  MOVE.B   OUTKTBL-SP.SBYTE(PC,D0.W),D0
         TRAP     #3
DO_OUT3  MOVEM.L  (A7)+,D3/A0
         TST.L    D0
         RTS
OUTKTBL  DC.B     IO.SBYTE&$FF,IO.SSTRG&$FF,FS.FLUSH&$FF
         DC.B     IO.DUMP&$FF,IO.PARIT&$FF

         XDEF     SETPAR

SETPAR   TST.B    LOCALMOD(A6)
         BNE.S    SP_END
         MOVEQ    #SP.PARIT,D0
         MOVE.L   COM_OUT(A6),A0

* Call QSPIL routines

         XDEF     CALLSPIL

CALLSPIL MOVEM.L  D2-D7/A2-A6,-(A7)
         MOVEQ    #0,D7
         LEA      LOG,A4
         MOVE.L   QSPILVEC(A6),A5
         JSR      (A5)
         MOVEM.L  (A7)+,D2-D7/A2-A6
         TST.L    D0
SP_END   RTS

* Write log entry
* LOG0: NULL terminated string in LOGBUF, LOG: QDOS-type string at (A1)

         XDEF     LOG,LOG0,LOG1

LOG0     MOVE.L   D0,-(A7)
         LEA      LOGBUF(A6),A1
LOG0_LP  TST.B    (A1)+
         BNE      LOG0_LP
         MOVE.B   #LF,-1(A1)
         MOVE.L   A1,D0
         LEA      LOGBUF(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
         MOVE.L   (A7)+,D0

LOG      MOVEM.L  D0-D4/A0-A2,-(A7)
         MOVE.L   A1,A2
         SUBA.W   #32,A7
         QDOS     MT.RCLCK
         MOVE.L   A7,A1
         JSR      DATE$
         JSR      GETTIME
         CMP.W    LOGDATE(A6),D2
         BEQ.S    LG_TIME
         MOVE.W   D2,LOGDATE(A6)
         LOAD$    {LF,'----------  '},A1
         MOVE.W   (A1)+,D2
         BSR.S    LOG_FILE
         MOVE.L   A7,A1
         MOVEQ    #17,D2
         BSR.S    LOG_FILE
         LOAD$    {'QBOX',LF},A1
         MOVE.W   (A1)+,D2
         BSR.S    LOG_FILE
LG_TIME  LEA      15(A7),A1
         MOVE.B   #' ',(A1)
         MOVE.W   (A2)+,D4
         CMPI.B   #' ',1(A2)
         BNE.S    LG_SPACE
         MOVE.B   (A2),(A1)
         ADDQ.W   #2,A2
         SUBQ.W   #2,D4
         BGE.S    LG_SPACE
         MOVEQ    #0,D4
LG_SPACE MOVE.B   #' ',10(A1)
         MOVE.B   #' ',11(A1)
         MOVEQ    #12,D2
         BSR.S    LOG_ALL
         MOVE.W   D4,D2
         MOVE.L   A2,A1
         BSR.S    LOG_ALL
         ADDA.W   #32,A7
         MOVEM.L  (A7)+,D0-D4/A0-A2
         RTS

LOG1     MOVEM.L  D0-D3/A0-A1,-(A7)
         MOVE.W   (A1)+,D2
         BSR.S    LOG_ALL
         MOVEM.L  (A7)+,D0-D3/A0-A1
LOG_RTS  RTS

LOG_ALL  TST.B    NOLOG(A6)
         BNE.S    LOG_FILE
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     IO.SSTRG
         SUBA.W   D1,A1
LOG_FILE MOVEQ    #-1,D3
         MOVE.L   LOGFILE(A6),A0
         QDOS     IO.SSTRG
         RTS

         XDEF     OP_FILE,OP_FIN,OP_FNEW,OP_FOVER,OP_FDIR,OPEN_SUB,OPENSUB1

OP_FILE  MOVEM.L  D1/D3/A2-A3,-(A7)
         MOVEQ    #0,D3
         BRA.S    OP_F1
OP_FIN   MOVEM.L  D1/D3/A2-A3,-(A7)
         MOVEQ    #1,D3
         BRA.S    OP_F1
OP_FNEW  MOVEM.L  D1/D3/A2-A3,-(A7)
         MOVEQ    #2,D3
         BRA.S    OP_F1
OP_FOVER MOVEM.L  D1/D3/A2-A3,-(A7)
         MOVEQ    #3,D3
OP_F1    LEA      INPCHAN(A6),A3
         BRA.S    OP_F2
OP_FDIR  MOVEM.L  D1/D3/A2-A3,-(A7)
         LEA      DIR_FNAM,A0
         LEA      DIRBUF(A6),A1
         LEA      DIRCHAN(A6),A3
OP_F2    LEA      FNAMBUF(A6),A2
         BSR.S    OPEN_SUB
         IF EQ THEN
            MOVE.L   A0,(A3)
         ENDIF
         MOVEM.L  (A7)+,D1/D3/A2-A3
         TST.L    D0
         RTS
OPEN_SUB MOVE.W   (A1)+,D0
         MOVE.W   D0,D1
         ADDQ.W   #2,A2
         BRA.S    GDIR2
GDIR1    MOVE.B   (A1)+,(A2)+
GDIR2    DBF      D0,GDIR1
         MOVE.W   (A0)+,D0
         ADD.W    D0,D1
         CMPI.W   #48,D1
         BLE.S    GDIR4
         MOVEQ    #ERR.BN,D0
         RTS
GDIR3    MOVE.B   (A0)+,(A2)+
GDIR4    DBF      D0,GDIR3
         SUBA.W   D1,A2
         MOVE.W   D1,-(A2)
OPENSUB1 MOVE.L   A2,A0
         MOVEQ    #-1,D1
         QDOS     IO.OPEN
         CMPI.L   #ERR.IU,D0
         BNE.S    GDIR6
         MOVE.W   D3,-(A7)
         MOVEQ    #50,D3
         BSR.S    PAUSE
         MOVE.W   (A7)+,D3
         BRA      OPENSUB1
GDIR6    TST.L    D0
         RTS

         XDEF     PAUSE

PAUSE    MOVEM.L  D1/A0-A1,-(A7)
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         MOVEM.L  (A7)+,D1/A0-A1
         RTS

         XDEF     OP_ERROR,IO_ERROR

OP_ERROR LOAD$    {'? Can''t open file '},A0
         BRA.S    RET_MAIN
IO_ERROR LOAD$    {'? I/O Error file '},A0
RET_MAIN LEA      LOGBUF(A6),A1
         WRITE$
         LEA      FNAMBUF(A6),A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      WRITEERR
         CLR.B    -1(A1)
         BSR      LOG0
         TXSTR    {CR,LF,'Returning to main menu',CR,LF}
         MOVE.L   SPSAV(A6),A7
         JMP      MAIN

OPEN_LOG CLR.W    LOGDATE(A6)
         LEA      S_LOG1(A6),A0
         TST.B    LOCALMOD(A6)
         IF NE THEN
            LEA      S_LOG2(A6),A0
         ENDIF
         MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         MOVE.L   A0,A2
         QDOS     IO.OPEN
         CMPI.L   #ERR.NF,D0
         BEQ.S    LOG_NEW
         TST.L    D0
         BNE.S    LOG_ERR
         MOVE.L   #999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
LOG_OK   MOVE.L   A0,LOGFILE(A6)
         RTS
LOG_NEW  MOVEQ    #-1,D1
         MOVEQ    #IO.NEW,D3
         MOVE.L   A2,A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    LOG_OK
LOG_ERR  MOVE.L   #$FFFF0200,LOGFILE(A6)
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Unable to open logfile: '},A1
         JSR      WRITEERR
         CLR.B    -1(A1)
         JMP      LOG0

         XDEF     FCLOSE,DIRCLOSE

FCLOSE   MOVE.L   INPCHAN(A6),A0
         MOVE.L   A0,D0
         IF NE THEN
            QDOS     IO.CLOSE
            CLR.L    INPCHAN(A6)
         ENDIF
         RTS
DIRCLOSE MOVE.L   DIRCHAN(A6),A0
         MOVE.L   A0,D0
         IF NE THEN
            QDOS     IO.CLOSE
            CLR.L    DIRCHAN(A6)
         ENDIF
         RTS

         XDEF     TYPE

TYPE     MOVEM.L  D1-D5/A2,-(A7)
         BSR      OP_FIN
         BNE      TYPE_RTS
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
T_TEST   QDOS     IO.FBYTE
         TST.L    D0
         BNE.S    T_REWIND
         TST.B    D1
         BMI.S    T_NO_TXT
         SUBQ.W   #1,D2
         BNE      T_TEST
T_REWIND MOVEQ    #0,D1
         QDOS     FS.POSAB
         LEA      LOGBUF(A6),A1
         WRITE$   {'Displaying '},A1
         LEA      FNAMBUF(A6),A0
         WRITE$
         CLR.B    (A1)
         JSR      LOG0
         JSR      TXCRLF
         MOVEQ    #0,D5
TYPE_LP  MOVE.L   INPCHAN(A6),A0
         MOVE.W   BUFSIZE(A6),D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    TYPE_ERR
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         REPEAT
            BSR.S    TXLINE
         UNTIL    LE
         BEQ.S    TYPE_LP
         BRA.S    TYPE_END
T_NO_TXT TXSTR    {CR,LF,'This is NOT a text file!'}
         BRA.S    TYPE_END
TYPE_ERR CMPI.L   #ERR.EF,D0
         BEQ.S    TYPE_END
         LEA      LOGBUF(A6),A1
         WRITE$   {'? I/O Error displaying file: '},A1
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
TYPE_END JSR      TXCRLF
         BSR      FCLOSE
TYPE_RTS MOVEM.L  (A7)+,D1-D5/A2
         RTS

* Transmit D1.W (no justification done)

         XDEF     TXNUMBER,TXNUM_F

TXNUMBER MOVEM.L  D1-D2/A1,-(A7)
         MOVEQ    #0,D2
         BRA.S    TXNUM_2
TXNUM_F  MOVEM.L  D1-D2/A1,-(A7)
TXNUM_2  SUBQ.W   #6,A7
         MOVE.L   A7,A1
         JSR      ITOD.W
         MOVE.L   A1,D2
         SUB.L    A7,D2
         MOVE.L   A7,A1
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         ADDQ.W   #6,A7
         MOVEM.L  (A7)+,D1-D2/A1
         RTS

         XDEF     TXLINE,TXLINE2

TXLINE   MOVEQ    #0,D2
         MOVE.B   USERBUF+US_WIDTH(A6),D2
TXLINE2  MOVE.W   D1,D4
         MOVE.W   D2,D0
         SUB.W    D2,D4
         BGT.S    TXLIN1
         MOVE.W   D1,D2
         MOVEQ    #0,D4
         BRA.S    TXLIN2
TXLIN1   CMPI.B   #CR,(A1,D2.W)
         BNE.S    TXLIN1A
         ADDQ.W   #1,D2
         SUBQ.W   #1,D4
         BRA.S    TXLIN2
TXLIN1A  CMPI.B   #' ',(A1,D2.W)
         BEQ.S    TXLIN2
         ADDQ.W   #1,D4
         SUBQ.W   #1,D2
         BNE.S    TXLIN1A
         MOVE.W   D0,D2
         MOVE.W   D1,D4
         SUB.W    D2,D4
TXLIN2   TST.B    PRINTLIN(A6)
         BNE.S    TXLIN3
         ADDA.W   D2,A1
         BRA.S    TXLIN4
TXLIN3   BSR.S    ASKMORE
         BNE.S    TXABORT
         TST.W    D2
         BEQ.S    TXLIN3A
         CMPI.B   #CR,-1(A1,D2.W)
         SEQ      -(A7)
         BNE.S    TXLIN31
         SUBQ.W   #1,D2
TXLIN31  MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         TST.B    (A7)+
         BEQ.S    TXLIN3A
         ADDQ.L   #1,A1
TXLIN3A  JSR      TXCRLF
         BSR.S    TXWAIT
         BEQ.S    TXABORT
TXLIN4   TST.W    D4
TXLIN4A  BEQ.S    TXLIN_EN
         CMPI.B   #' ',(A1)
         BNE.S    TXLIN_EN
         ADDQ.W   #1,A1
         SUBQ.W   #1,D4
         BRA      TXLIN4A
TXLIN_EN MOVE.W   D4,D1
         MOVEQ    #0,D0
         MOVE.W   D4,D0
         RTS
TXABORT  JSR      TXCRLF
         MOVEQ    #-1,D0
         RTS

         XDEF     ASKMORE

ASKMORE  TST.B    SPEC_OUT(A6)
         BNE.S    ASKM_END
         MOVE.B   USERBUF+US_LINES(A6),D1
         BCLR     #7,D1
         BEQ.S    ASKM_END
         ADDQ.B   #1,D5
         CMP.B    D1,D5
         BLT.S    ASKM_END
         MOVE.L   A1,-(A7)
         TXSTR    {'More? (Y/n) '}
ASKM_GET JSR      GETCHAR
         JSR      TOUPPER
         CMPI.B   #CR,D1
         BEQ.S    ASKM_YES
         CMPI.B   #'N',D1
         BEQ.S    ASKM_NO
         CMPI.B   #'Y',D1
         BNE      ASKM_GET
ASKM_YES TXSTR    {CR,'            ',CR}
         MOVE.L   (A7)+,A1
         MOVEQ    #1,D5
ASKM_END MOVEQ    #0,D0
         RTS
ASKM_NO  JSR      TXCHAR
         MOVE.L   (A7)+,A1
         MOVEQ    #-1,D0
         RTS

         XDEF     TXWAIT

TXWAIT   TST.B    SPEC_OUT(A6)
         BNE.S    TXWT_RTS
         MOVEM.L  D0-D1/D3/A0-A1,-(A7)
TXW_LOOK JSR      LOOKCHAR
         BNE.S    TXWT_END
TXW_XOFF JSR      TOUPPER
         CMPI.B   #XOFF,D1
         BEQ.S    TXWT_WT
         CMPI.B   #'P',D1
         BNE.S    TXWT_ETX
TXWT_WT  JSR      GETCHAR
         BRA      TXW_XOFF
TXWT_ETX CMPI.B   #'C'-'@',D1
         BEQ.S    TXWT_CLR
         CMPI.B   #'K'-'@',D1
         BEQ.S    TXWT_CLR
         CMPI.B   #'S',D1
         BNE      TXW_LOOK
TXWT_CLR JSR      DUMP_OPB
         MOVEQ    #0,D0
TXWT_END MOVEM.L  (A7)+,D0-D1/D3/A0-A1
TXWT_RTS RTS

         XDEF     CHKTIME

CHKTIME  MOVEM.L  D0/D2/A0,-(A7)
         QDOS     MT.RCLCK
         MOVEM.L  (A7)+,D0/D2/A0
         ADD.L    D0,D1
         SUB.L    USERBUF+US_LSTLG(A6),D1
         DIVU     #60,D1
         MOVE.W   TIMELEFT(A6),D0
         SUB.W    D1,D0
         RTS

         XDEF     DO_INP

DO_INP   MOVEM.L  A0-A1,-(A7)
         MOVE.L   COM_IN(A6),A0
         TST.B    LOCALMOD(A6)
         BNE.S    DO_INP2
         JSR      CALLSPIL
         BRA.S    DO_INP3
DO_INP2  SUBQ.B   #SP.PEND-IO.PEND&$FF,D0
         TRAP     #3
DO_INP3  MOVEM.L  (A7)+,A0-A1
         TST.L    D0
         RTS

         XDEF     LOOKCHAR,GETCHAR,TGETCHAR

LOOKCHAR MOVE.L   D3,-(A7)
         MOVEQ    #0,D3
         BRA.S    GETCHAR1
GETCHAR  MOVE.L   D3,-(A7)
         MOVEQ    #-1,D3
         TST.B    LOCALMOD(A6)
         BNE.S    GETCHAR1
         MOVE.W   #180*50,D3
         MOVEQ    #0,D0
         BSR      CHKTIME
         BGT.S    CHK2MINS
         TXMSG    {'Time limit exceeded, call back tomorrow'}
         LOG      {'Time limit exceeded',LF}
         BRA      LOGOUT
CHK2MINS SUBQ.W   #2,D0
         BGT.S    TIME_OK
         TST.B    TMWARNED(A6)
         BNE.S    TIME_OK
         ST       TMWARNED(A6)
         TXMSG    {'WARNING: ONLY 2 MINUTES LEFT!'}
TIME_OK  ST       WAITCHAR(A6)
         BRA.S    GETCHAR1
TGETCHAR MOVE.L   D3,-(A7)
         ANDI.L   #$7FFF,D3
GETCHAR1 MOVEQ    #SP.FBYTE,D0
         BSR      DO_INP
         SF       WAITCHAR(A6)
         TST.B    CHATFLG(A6)
         SF       CHATFLG(A6)
         BGT      GETCHAR1
         BLT.S    LOGOUT
         TST.L    D3
         BGE.S    GC_RSTOR
         CMPI.L   #ERR.NC,D0
         BEQ.S    IN_TIMO
GC_RSTOR MOVE.L   (A7)+,D3
         CMPI.L   #ERR.EF,D0
         BEQ.S    LOGOUT
         TST.L    D0
         BNE.S    GC_RTS
         ANDI.B   #$7F,D1
         CMPI.B   #'C'-'@',D1
         BEQ.S    GC_DUMP
         CMPI.B   #'K'-'@',D1
         BNE.S    GC_ESC
GC_DUMP  MOVE.W   D1,-(A7)
         JSR      DUMP_OPB
         MOVE.W   (A7)+,D1
         BRA.S    GC_RTS
GC_ESC   TST.B    ESCMODE(A6)
         SF       ESCMODE(A6)
         IF NE THEN
            ORI.B    #$80,D1
         ENDIF
         IF D1 EQ.B #$1B THEN
            ST       ESCMODE(A6)
         ENDIF
         TST.L    D0
GC_RTS   RTS

         XDEF     LOGOUT

IN_TIMO  LOG      {'Inactivity timeout',LF}
         TXMSG    {'INACTIVITY TIMEOUT, DISCONNECTING'}
LOGOUT   MOVE.L   SPSAV(A6),A7
         JSR      DIRCLOSE
         JSR      FCLOSE
         QDOS     MT.RCLCK
         MOVE.L   USERBUF+US_LSTLG(A6),D0
*         MOVE.L   D1,USERBUF+US_LSTLG(A6)
         SUB.L    D0,D1
         DIVU     #60,D1
         ADD.W    D1,USERBUF+US_DAYTM(A6)
         TST.W    USERBUF+US_CALLS(A6)
         BEQ.S    OFFLINE
         MOVE.W   USERPOS(A6),D1
         LEA      USERBUF(A6),A1
         JSR      WR_USER
         BNE.S    USBBS_ER
         LEA      LSTRDFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FILE
         BNE.S    LSTRD_ER
         MOVE.W   USERPOS(A6),D1
         MOVE.W   #MAXAREA*2,D2
         MULU     D2,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         TST.L    D0
         BNE.S    LSTRD_ER
         LEA      LASTREAD(A6),A1
         QDOS     IO.SSTRG
         TST.L    D0
         BEQ.S    OFFLINE
LSTRD_ER LOAD$    {'? File I/O Error LASTREAD_BBS: '},A0
         BRA.S    OFFLIN1
USBBS_ER LOAD$    {'? File I/O Error USERS_BBS: '},A0
OFFLIN1  LEA      LOGBUF(A6),A1
         WRITE$
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
OFFLINE  JSR      FCLOSE
         JSR      DIRCLOSE
         TST.B    LOCALMOD(A6)
         BEQ.S    DISCON
         MOVE.L   COM_IN(A6),A0
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         CMPI.L   #ERR.EF,D0
         BNE      START2
         MOVEQ    #-1,D1
         QDOS     MT.FRJOB

DISCON   JSR      FLUSH
         MOVEQ    #50,D3
         JSR      PAUSE
         MOVEQ    #SP.DSCON,D0
         MOVE.L   COM_IN(A6),A0
         JSR      CALLSPIL
         LOG      {'Line disconnected',LF}
         MOVEQ    #100,D3
         JSR      PAUSE
         LEA      S_MAILPR(A6),A0
         TST.B    GOTMAIL(A6)
         BNE.S    DO_EXTPR
         CMPI.B   #ISHUMAN,ONLINE(A6)
         BNE.S    SIGN_OFL
         TST.W    USERPOS(A6)
         BMI.S    SIGN_OFL
         LEA      S_AFTUSR(A6),A0
DO_EXTPR TST.B    (A0)
         BEQ.S    SIGN_OFL
         MOVE.L   A0,-(A7)
         MOVEQ    #SP.CLOSE,D0
         MOVEQ    #0,D1
         MOVE.L   COM_IN(A6),A0
         JSR      CALLSPIL
         MOVE.L   (A7)+,A0
         MOVEQ    #32,D6
         MOVEQ    #-1,D7
         LEA      EXT_CMDL,A2
         LEA      EXT_CHAN,A3
         JSR      EXEC
         BSR      EXT_RET
         MOVEQ    #SP.INIT,D0
         MOVE.L   OWNERJOB(A6),D1
         JSR      CALLSPIL
SIGN_OFL SF       ONLINE(A6)
         BSR.S    REL_MAIN
         BRA      START2

REL_MAIN TST.B    LOCALMOD(A6)
         BNE.S    RM_END
         MOVE.L   OWNERJOB(A6),D1
         MOVEQ    #0,D2
         QDOS     MT.JINF
         TST.W    $14-$68(A0)       JB_STAT
         BLT.S    RM_END
         MOVE.L   OWNERJOB(A6),D1
         QDOS     MT.RELJB
RM_END   RTS

         XDEF     STARTSUB

STARTSUB BRA.S    STARTSB1
         DS.L     1
         DC.W     $4AFB
         STRING$  {'QBOX Line 1'}
JB_LINE  EQU      *-STARTSUB-1
STARTSB1 ADDA.L   A4,A6
         MOVE.L   A7,SPSAV(A6)
         CLR.L    INPCHAN(A6)
         CLR.L    DIRCHAN(A6)
         CLR.B    RINGBACK(A6)
         BSR      OPEN_LOG
         MOVE.L   QSPILVEC(A6),A2
         MOVE.L   A2,D0
         BEQ.S    START2
         ADDQ.L   #4,A2
         MOVE.B   #'0',QSPILREV(A6)
         MOVE.L   (A2)+,D1
         MOVEQ    #$F0-256,D0
         AND.L    D1,D0
         CMPI.L   #'QSP0',D0
         BNE.S    START2
         MOVE.B   D1,QSPILREV(A6)
         TST.B    NOLOG(A6)
         BNE.S    START2
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         LOAD$    {'QSPIL: '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVE.L   A2,A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
START2   SF       ONLINE(A6)
         SF       ESCMODE(A6)
         SF       CHATFLG(A6)
         SF       WAITCHAR(A6)
         SF       TMWARNED(A6)
         SF       SYSOPMSG(A6)
         SF       KLUDGE(A6)
         SF       SPEC_OUT(A6)
         SF       GOTMAIL(A6)
         MOVE.W   #-1,USERPOS(A6)
         MOVE.W   #US_LEN,D0
         LEA      USERBUF(A6),A1
CLR_USR  CLR.L    (A1)+
         SUBQ.W   #4,D0
         BGT      CLR_USR
         CLR.W    LOGDATE(A6)
         CLR.L    CON_XTRA(A6)
         ST       BPS(A6)
         SF       CONN_ARQ(A6)
         TST.B    LOCALMOD(A6)
         BNE      GO_BBS2
         TST.B    RINGBACK(A6)
         BNE.S    S_RBACK
         LOG      {'Waiting for call',LF}
         MOVE.L   OWNERJOB(A6),D1
         MOVEQ    #-1,D3
         MOVE.L   COM_IN(A6),A0
         MOVEQ    #SP.WTCAL,D0
         JSR      CALLSPIL
         BNE.S    CAL_FAIL
         BRA.S    SET_COM
S_RBACK  LOG      {'Waiting for callback',LF}
         MOVE.W   #30*50,D3
         JSR      PAUSE
         SUBQ.B   #1,RINGBACK(A6)
         LEA      LOGBUF(A6),A1
         WRITE$   {'Dialling '},A1
         LEA      USERBUF2+2(A6),A0
         WRITE$
         CLR.B    (A1)
         JSR      LOG0
         MOVE.L   OWNERJOB(A6),D1
         MOVE.L   COM_IN(A6),A0
         LEA      USERBUF2(A6),A1
         MOVE.W   (A1)+,D2
         MOVEQ    #SP.DIAL,D0
         JSR      CALLSPIL
         BEQ.S    CLR_RB
CAL_FAIL LOG      {'No connection',LF}
         BRA      START2
CLR_RB   CLR.B    RINGBACK(A6)
SET_COM  MOVE.L   A0,COM_IN(A6)
         MOVE.L   A0,COM_OUT(A6)
         MOVE.B   D1,BPS(A6)
         CLR.L    CON_XTRA(A6)
         CMPI.B   #'1',QSPILREV(A6)
         BLO.S    TST_SPD
         BTST     #8,D1
         SNE      CONN_ARQ(A6)
         MOVE.L   A1,CON_XTRA(A6)
TST_SPD  EXT.W    D1
         CMPI.B   #CONN_FAX,D1
         BNE.S    NOFAX
         LOG      {'FAX Connect',LF}
         LEA      S_FAXPRG(A6),A0
         TST.B    (A0)
         BNE.S    GO_FAX
         LOG      {'? No FAX program to execute!',LF}
         BRA      DISCON
GO_FAX   MOVE.B   #INFAX,ONLINE(A6)
         MOVEQ    #32,D6
         MOVEQ    #-1,D7
         LEA      EXT_CMDL,A2
         LEA      EXT_CHAN,A3
         JSR      EXEC
         JSR      EXT_RET
         BRA      DISCON
NOFAX    CMPI.B   #MAXMODEM,D1
         BHI.S    CONN_2
         LEA      LOGBUF(A6),A1
         WRITE$   {'Connection at '},A1
         ADD.W    D1,D1
         LEA      SPEEDS,A0
         ADD.W    (A0,D1.W),A0
         WRITE$
         WRITE$   {' bps '}
         MOVE.L   CON_XTRA(A6),A0
         MOVE.L   A0,D0
         IF NE THEN
            WRITE$
         ENDIF
         CLR.B    (A1)+
         JSR      LOG0
         BRA.S    CONNECT
CONN_2   LOG      {'Connection speed unknown',LF}
CONNECT  MOVEQ    #PA.NONE,D1
         JSR      SETPAR
WHACK    JSR      SET1MIN
PURGE1   JSR      CHKTIMER
         BNE      GARBLED
         MOVEQ    #5,D3
         JSR      PURGE_LP
WHACK2   MOVE.W   #5*50,D3
         JSR      GETCHR1
         BLT      CR_LOST1
         BGT.S    TSIGNON
         CMPI.B   #CR,D1
         BEQ.S    WHACK3
         CMPI.B   #' ',D1
         BNE      PURGE1
WHACK3   JSR      CHKTIMER
         BNE      GARBLED
         MOVEQ    #5,D3
         JSR      GETCHR1
         BLT      CR_LOST1
         BGT.S    TSIGNON
         CMPI.B   #CR,D1
         BEQ      WHACK3
         CMPI.B   #' ',D1
         BEQ      WHACK3
         BRA      PURGE1
TSIGNON  MOVEQ    #0,D3
         JSR      PURGE_LP
         TXSTR    {FF,'QBOX v[version]',CR,LF,LF}
TSIGNON2 ST       D7
         MOVE.B   S_MONLY(A6),D0
         BEQ.S    CHK_WIN
         CMPI.B   #MAILONLY,D0
         BEQ.S    ML_ONLY
         SF       D7
         BRA      GO_BBS
CHK_WIN  MOVEM.W  S_MSTART(A6),D1-D2
         SUBQ.W   #5,D1
         IF LO THEN
            ADDI.W   #24*60,D1
         ENDIF
         BSR      CHKTMBND
         BCS.S    ML_NOW
         SF       D7
         TXSTR    {'Press <ESC> twice for BBS or wait 10 seconds',CR}
         BRA.S    GT_TSYNC
ML_NOW   TXSTR    {'System does not allow human callers right now, please hang up',CR}
         BRA.S    GT_TSYNC
ML_ONLY  TXSTR    {'Mail only system. Please hang up.',CR}
GT_TSYNC JSR      CHKTIMER
         BNE.S    GARBLED
         MOVE.W   #10*50,D3
         JSR      GETCHR1
         BLT.S    CR_LOST1
         BGT.S    GO_BBS
         CMPI.B   #CR,D1
         BEQ      TSIGNON2
         CMPI.B   #' ',D1
         BEQ      TSIGNON2
         CMPI.B   #ESC,D1
         BNE.S    CHKTSYNC
         JSR      GETCHR1
         BLT.S    CR_LOST1
         BGT      GT_TSYNC
         CMPI.B   #ESC,D1
         BEQ.S    GO_BBS
CHKTSYNC CMPI.B   #TSYNC,D1
         BNE      GT_TSYNC
         MOVE.B   #INMAIL,ONLINE(A6)
         MOVE.B   D1,-(A7)
         BSR      REL_MAIN
         MOVE.B   (A7)+,D1
         JSR      DO_INBND
         BRA      OFFLINE
GARBLED  LOG      {'? Received nothing but garbage on line',LF}
         BRA      DISCON
CR_LOST1 LOG      {'? Carrier lost',LF}
         BRA      DISCON

GO_BBS   JSR      TXCRLF
         JSR      TXLF
         TST.B    D7
         BEQ.S    GO_BBS2
         LOG      {'Rejecting human caller',LF}
         BRA      DISCON
GO_BBS2  LOG      {'Switching to BBS',LF}
         MOVE.B   #ISHUMAN,ONLINE(A6)
         MOVE.B   #LV.DISGR,USERBUF+US_LEVEL(A6)
         MOVE.B   #79,USERBUF+US_WIDTH(A6)
         MOVE.B   #24,USERBUF+US_LINES(A6)
         QDOS     MT.RCLCK
         MOVE.L   D1,USERBUF+US_LSTLG(A6)
         MOVE.W   #10,TIMELEFT(A6)
         ST       PRINTLIN(A6)
         SF       LINUMFLG(A6)
         LEA      LOGINFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      TYPE
         LOG      {'Logging on',LF}
         SF       ECHOPNT(A6)
ENT_NAME MOVEQ    #US.NMAX,D2
         ST       D0
         GETNAM2  {'Please enter your first and last name: '}
         TST.L    D0
         BLT.S    TWONAMES
         CMPI.L   #5<<24+'Sys',(A1)
         BNE.S    LASTNAME
         CMPI.W   #'op',4(A1)
         BEQ.S    TWONAMES
LASTNAME LEA      USERBUF(A6),A2
         JSR      COPYNAME
         MOVE.L   A2,-(A7)
         MOVEQ    #US.NMAX-1,D2
         SUB.W    D1,D2
         ST       D0
         GETNAM2  {'And your LAST name: '}
         MOVE.L   (A7),A2
         JSR      COPYNAME
         MOVE.L   (A7)+,A2
         MOVE.B   (A2),D1
         MOVE.B   #' ',(A2)
         ADDQ.B   #1,D1
         LEA      USERBUF(A6),A1
         ADD.B    D1,(A1)
         BRA.S    USRSRCH
TWONAMES LEA      USERBUF(A6),A2
         JSR      COPYNAME
USRSRCH  LEA      LOGBUF(A6),A1
         WRITE$   {'User online: '},A1
         LEA      USERBUF(A6),A0
         MOVE.B   (A0)+,D0
         REPEAT
            MOVE.B   (A0)+,(A1)+
            SUBQ.B   #1,D0
         UNTIL    LE
         CLR.B    (A1)+
         JSR      LOG0
         TXSTR    {'Searching user file...',CR,LF}
         LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         MOVE.L   D0,D4
         CMPI.L   #ERR.NF,D4
         BEQ.S    USBBS_NF
         TST.L    D4
         BNE      USBBS_ER
         LEA      USERBUF(A6),A1
         LEA      USERBUF2(A6),A2
         JSR      FINDUSER
         MOVE.L   D0,D4
         MOVE.W   D1,USERPOS(A6)
         JSR      FCLOSE
         TST.L    D4
         BEQ      CHKPASSW
         CMPI.L   #ERR.EF,D4
         BNE      USBBS_ER
USBBS_NF MOVE.W   #-1,USERPOS(A6)
         LOG      {'Name not found!',LF}
         LEA      NOTFDFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      TYPE
         IF NE THEN
            TXSTR    {CR,LF,'Your name was not located in the user list!',CR,LF}
            TXSTR    {'Press Y if you are REALLY a new user, or N if you have',CR,LF}
            TXSTR    {'entered your name incorrectly by accident',CR,LF}
         ENDIF
         TXSTR    {CR,LF,'Name Entered: '}
         LEA      USERBUF(A6),A1
         JSR      PRINTNAM
         TXSTR    {'.',CR,LF,LF,'Did you enter your name correctly'}
         REPEAT
            JSR      LOOKCHAR
         UNTIL    NE
         JSR      NOYES
         BEQ.S    NEW_USER
         LOG      {'Re-entering name',LF}
         BRA      ENT_NAME
NEW_USER LEA      USERBUF2(A6),A1
         MOVEQ    #US_LEN/4,D0
         REPEAT
            CLR.L    (A1)+
            SUBQ.W   #1,D0
         UNTIL    EQ
         LEA      USERBUF(A6),A1
         LEA      USERBUF2(A6),A2
         JSR      COPYNAME
         LEA      NMSGFNAM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      TYPE
         BEQ.S    GETCITY
         TXSTR    {CR,LF,'Hello, a new user on this system!',CR,LF,LF}
GETCITY  MOVEQ    #US.CMAX,D2
         ST       D0
         GETNAM2  {'Which town are you calling from? '}
         JSR      PRINTNAM
         JSR      YESNO
         BNE      GETCITY
         LEA      BUFFER(A6),A1
         LEA      USERBUF2+US_CITY(A6),A2
         JSR      COPYNAME
GETPASSW MOVEQ    #US.PMAX,D2
         ST       D0
         ST       ECHOPNT(A6)
         GETNAM1  {'Enter the password you want to use on this system (max. 16 chars)',CR,LF}
         LEA      USERBUF2+US_PASSW(A6),A2
         JSR      COPYNAME
         MOVEQ    #US.PMAX,D2
         ST       D0
         GETNAM1  {'Please re-enter for verification: '}
         SF       ECHOPNT(A6)
         LEA      USERBUF2+US_PASSW(A6),A2
         JSR      CMPNAME
         BEQ.S    PWD_OK
         TXSTR    {'Password check failed - try again!',CR,LF}
         BRA      GETPASSW
PWD_OK   MOVE.W   S_INISEC(A6),D1
         MOVE.B   D1,USERBUF2+US_LEVEL(A6)
         LEA      S_MGROUP(A6),A1
         MOVE.L   (A1)+,USERBUF2+US_MACCS(A6)
         MOVE.L   (A1),USERBUF2+US_FACCS(A6)
         MOVE.B   #79,USERBUF2+US_WIDTH(A6)
         MOVE.B   #24+$80,USERBUF2+US_LINES(A6)
         SF       USERBUF2+US_MBCMD(A6)
         MOVE.W   S_MAREA(A6),D1
         MOVE.B   D1,USERBUF2+US_MAREA(A6)
         MOVE.W   S_FAREA(A6),D1
         MOVE.B   D1,USERBUF2+US_FAREA(A6)
         MOVE.W   #MAXAREA,D0
         LEA      LASTREAD(A6),A1
         REPEAT
            CLR.L    (A1)+
            SUBQ.W   #2,D0
         UNTIL    LE
         LEA      USERBUF2+US_NAME(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      COPYNAME
         LEA      USERBUF2+US_CITY(A6),A1
         LEA      USERBUF+US_CITY(A6),A2
         JSR      COPYNAME
         JSR      QUESTION
         BRA.S    PW_OK
CHKPASSW MOVEQ    #3,D7
PWLOOP   ST       ECHOPNT(A6)
         MOVEQ    #US.PMAX,D2
         ST       D0
         GETNAM1  {'Password: '}
         SF       ECHOPNT(A6)
         LEA      USERBUF2+US_PASSW(A6),A2
         JSR      CMPNAME
         BEQ.S    PW_OK
         TXSTR    {'Incorrect, try again',CR,LF}
         LEA      LOGBUF(A6),A1
         WRITE$   {'Incorrect password: '},A1
         LEA      BUFFER(A6),A0
         MOVE.B   (A0)+,D0
         REPEAT
            MOVE.B   (A0)+,(A1)+
            SUBQ.B   #1,D0
         UNTIL    LE
         CLR.B    (A1)+
         JSR      LOG0
         SUBQ.B   #1,D7
         BNE      PWLOOP
         TXSTR    {'You have entered a wrong password three times.',CR,LF}
         TXSTR    {'As a result, I have to log you off...',CR,LF}
         LOG      {'Password failure',LF}
         BRA      LOGOUT
PW_OK    LEA      USERBUF2(A6),A1
         LEA      USERBUF(A6),A2
         MOVEQ    #US_LEN/4,D0
         REPEAT
            MOVE.L   (A1)+,(A2)+
            SUBQ.W   #1,D0
         UNTIL    LE
         ADDQ.W   #1,USERBUF+US_CALLS(A6)
         IF VS THEN
            MOVE.W   #1,USERBUF+US_CALLS(A6)
         ENDIF
         TXSTR    {CR,LF,'This is your '}
         MOVEQ    #0,D1
         MOVE.W   USERBUF+US_CALLS(A6),D1
         JSR      TXNUMBER
         DIVU     #10,D1
         MOVE.L   D1,D0
         SWAP     D0
         ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         SWAP     D1
         SUBQ.W   #1,D1
         BEQ.S    USE_TH
         CMPI.W   #4,D0
         BLT.S    FIND_SUF
USE_TH   MOVEQ    #0,D0
FIND_SUF ADD.W    D0,D0
         LEA      SUFTBL,A1
         ADDA.W   D0,A1
         MOVEQ    #2,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         TXSTR    {' call to this system.',CR,LF}
         MOVE.L   USERBUF+US_LSTLG(A6),D7
         MOVE.L   D7,LASTCALL(A6)
         IF NE THEN
            TXSTR    {'Your previous call was on '}
            MOVE.L   D7,D1
            JSR      TXTIME
         ENDIF
         MOVE.L   D7,D1
         JSR      GETTIME
         MOVE.W   D1,D7
         QDOS     MT.RCLCK
         MOVE.L   D1,D6
         MOVE.L   D1,USERBUF+US_LSTLG(A6)
         JSR      GETTIME
         IF D1 NE.W D7 THEN
            CLR.W    USERBUF+US_DAYTM(A6)
         ENDIF
         SF       TMWARNED(A6)
         LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FILE
         IF NE THEN
            CMPI.L   #ERR.NF,D0
            BNE      USBBS_ER
            LOG      {'No USERS_BBS, creating file',LF}
            LEA      USLSTFNM,A0
            LEA      S_SYSDIR(A6),A1
            JSR      OP_FNEW
            BNE      USBBS_ER
         ENDIF
         MOVEQ    #-1,D3
         MOVE.W   #US_LEN,D2
         MOVE.W   USERPOS(A6),D1
         CMP.W    D3,D1
         BNE.S    UPD_USER
FIND_VAC ADDQ.W   #1,USERPOS(A6)
         LEA      BUFFER(A6),A1
         QDOS     IO.FSTRG
         CMPI.L   #ERR.EF,D0
         BEQ.S    UPD_USER
         TST.L    D0
         BNE      USBBS_ER
         TST.B    BUFFER+US_NAME(A6)
         BEQ.S    UPD_USER
         MOVEQ    #US.LEVEL,D0
         AND.B    BUFFER+US_LEVEL(A6),D0
         SUBQ.B   #LV.NORM,D0
         BHI      FIND_VAC
         MOVE.L   D6,D0
         SUB.L    BUFFER+US_LSTLG(A6),D0
         CMPI.L   #30*24*60*60,D0
         BLS      FIND_VAC
         CMPI.L   #90*24*60*60,D0
         BHI.S    UPD_USER
         CMPI.W   #1,BUFFER+US_CALLS(A6)
         BHI      FIND_VAC
UPD_USER MOVE.W   USERPOS(A6),D1
         MULU     D2,D1
         QDOS     FS.POSAB
         LEA      USERBUF(A6),A1
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      USBBS_ER
         JSR      FCLOSE
         LEA      LSTRDFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FILE
         IF NE THEN
            CMPI.L   #ERR.NF,D0
            BNE      LSTRD_ER
            LEA      LSTRDFNM,A0
            LEA      S_SYSDIR(A6),A1
            JSR      OP_FNEW
            BNE      LSTRD_ER
         ENDIF
         MOVE.W   USERPOS(A6),D1
         MOVE.W   #MAXAREA*2,D2
         MULU     D2,D1
         MOVE.L   D1,D5
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         CMP.L    D5,D1
         IF NE THEN
            LOG      {'? LASTREAD_BBS too short',LF}
            BRA      OFFLINE
         ENDIF
         LEA      LASTREAD(A6),A1
         TST.L    D4
         IF EQ THEN
            QDOS     IO.FSTRG
         ELSE
            QDOS     IO.SSTRG
         ENDIF
         TST.L    D0
         BNE      LSTRD_ER
         JSR      FCLOSE
         TST.L    D4
         IF NE THEN
            LEA      NWUSFNAM,A0
            LEA      S_SYSDIR(A6),A1
            JSR      OP_FILE
            IF EQ THEN
               MOVE.L   #999999,D1
               MOVEQ    #-1,D3
               QDOS     FS.POSAB
               LEA      USERBUF(A6),A1
               JSR      PRINTNM1
               MOVEQ    #LF,D1
               QDOS     IO.SBYTE
               JSR      FCLOSE
            ENDIF
         ENDIF
         MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A6),D0
         ADD.W    D0,D0
         LEA      S_DTIME(A6),A1
         MOVE.W   (A1,D0.W),D0
         SUB.W    USERBUF+US_DAYTM(A6),D0
         IF LE THEN
            TXSTR    {CR,LF,'Sorry, but you have no time left for today.',CR,LF}
            TXSTR    {'Please try again after midnight...',CR,LF,LF}
            BRA      LOGOUT
         ENDIF
         MOVE.W   D0,TIMELEFT(A6)
         TST.B    LOCALMOD(A6)
         BNE.S    DSP_BUL
         CMPI.B   #BBS_ONLY,S_MONLY(A6)
         BEQ.S    DSP_BUL
         MOVE.W   S_MSTART(A6),D3
         CMP.W    S_MEND(A6),D3
         BEQ.S    DSP_BUL
         QDOS     MT.RCLCK
         MOVEQ    #60,D2
         JSR      DIVLONG
         MOVE.W   #24*60,D2
         JSR      DIVLONG
         SUB.W    D0,D3
         IF LO THEN
            ADD.W    D2,D3
         ENDIF
         CMP.W    TIMELEFT(A6),D3
         BHS.S    DSP_BUL
         MOVE.W   D3,TIMELEFT(A6)
         TXSTR    {CR,LF,'NOTICE:',CR,LF}
         TXSTR    {'Your time limit has been adjusted downwards because of an upcoming',CR,LF}
         TXSTR    {'mail schedule. Your available time for this session is '}
         MOVE.W   D3,D1
         JSR      TXNUMBER
         TXSTR    {' minutes',CR,LF}
         JSR      ASK_ENTR
DSP_BUL  BSR      REL_MAIN
         MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A6),D0
         IF EQ THEN
            JSR      TWITMSG
         ELSE
            JSR      BULLETIN
         ENDIF
         LEA      MSCANNED(A6),A1
         MOVE.W   #MAXAREA,D0
         REPEAT
            SF       (A1)+
            SUBQ.W   #1,D0
         UNTIL    EQ

         XDEF     MAIN

MAIN     LOG      {'Main menu',LF}
         LEA      MAINTBL,A1
         JSR      INDEXER
         BRA      MAIN

         SECTION  MSG

         XDEF     SPEEDS

         DC.W     SPFAX-SPEEDS
         DC.W     SP0-SPEEDS
SPEEDS   DC.W     SP300-SPEEDS
         DC.W     SP1275-SPEEDS
         DC.W     SP1200-SPEEDS
         DC.W     SP2400-SPEEDS
         DC.W     SP4800-SPEEDS
         DC.W     SP9600-SPEEDS
         DC.W     SP19200-SPEEDS
         DC.W     SP38400-SPEEDS
         DC.W     SP7200-SPEEDS
         DC.W     SP12000-SPEEDS
         DC.W     SP14400-SPEEDS
         DC.W     SP16800-SPEEDS
         DC.W     SP21600-SPEEDS
         DC.W     SP24000-SPEEDS
         DC.W     SP26400-SPEEDS
         DC.W     SP28800-SPEEDS
         DC.W     SP31200-SPEEDS
         DC.W     SP33600-SPEEDS
         DC.W     SP36000-SPEEDS
SPFAX    STRING$  'FAX'
SP0      STRING$  '0'
SP300    STRING$  '300'
SP1275   STRING$  '1200/75'
SP1200   STRING$  '1200'
SP2400   STRING$  '2400'
SP4800   STRING$  '4800'
SP7200   STRING$  '7200'
SP9600   STRING$  '9600'
SP12000  STRING$  '12000'
SP14400  STRING$  '14400'
SP16800  STRING$  '16800'
SP19200  STRING$  '19200'
SP21600  STRING$  '21600'
SP24000  STRING$  '24000'
SP26400  STRING$  '26400'
SP28800  STRING$  '28800'
SP31200  STRING$  '31200'
SP33600  STRING$  '33600'
SP36000  STRING$  '36000'
SP38400  STRING$  '38400'
SUFTBL   DC.B     'thstndrd'
         SECTION  CODE

MAINTBL  STRING$  {'Main'}
         STRING$  {LV.DISGR,'M',$5B,'M]ail section'}
         DC.W     MAILBOX-*
         STRING$  {LV.DISGR,'F',$5B,'F]ile section'}
         DC.W     FILES-*
         STRING$  {LV.DISGR,'B',$5B,'B]ulletin'}
         DC.W     BULLETIN-*
         STRING$  {LV.DISGR,'E',$5B,'E]ditorial'}
         DC.W     EDITOR-*
         STRING$  {LV.DISGR,'I',$5B,'I]nfo'}
         DC.W     INFO-*
         STRING$  {LV.DISGR,'S',$5B,'S]tatistics'}
         DC.W     STATS-*
         STRING$  {LV.TWIT,'G',$5B,'G]oodbye'}
         DC.W     LOGOFF-*
         STRING$  {LV.DISGR,'C',$5B,'C]hange user settings'}
         DC.W     USERPARM-*
         STRING$  {LV.DISGR,'U',$5B,'U]sers list'}
         DC.W     USERLIST-*
         STRING$  {LV.DISGR,'A',$5B,'A]nswer questionnaire'}
         DC.W     QUEST2-*
         STRING$  {LV.DISGR,'Y',$5B,'Y]ell sysop'}
         DC.W     YELL-*
         STRING$  {LV.COSYS,'R',$5B,'R]ing back'}
         DC.W     CALLBACK-*
         STRING$  {LV.TWIT,'V',$5B,'V]ersion'}
         DC.W     VERSION-*
         DC.W     0

         XDEF     IN_DISPL

IN_DISPL MOVEM.L  D6-D7,-(A7)
         JSR      TXCRLF
         MOVE.L   A1,-(A7)
         JSR      TXSTR
         TXSTR    {': '}
         MOVE.L   (A7)+,A1
         TST.B    D4
         BGT.S    INDSPEND
         MOVE.W   (A1)+,D2
         MOVE.B   USERBUF+US_WIDTH(A6),D6
         SUB.B    D2,D6
         SUBQ.B   #2,D6
         ADDQ.W   #1,D2
         BCLR     #0,D2
         ADDA.W   D2,A1
         SF       D7
IN_LOOP1 MOVE.W   (A1)+,D2
         CMP.B    (A1),D5
         BLO.S    IN_SKIP
         TST.B    D7
         ST       D7
         IF NE THEN
            TST.B    D4
            IF LT THEN
               MOVEQ    #',',D1
               JSR      TXCHAR
            ENDIF
            MOVEQ    #' ',D1
            JSR      TXCHAR
         ENDIF
         TST.B    D4
         IF EQ THEN
            MOVE.B   1(A1),D1
            JSR      TXCHAR
         ELSE
            SUB.B    D2,D6
            IF LT THEN
               JSR      TXCRLF
               MOVE.B   USERBUF+US_WIDTH(A6),D6
               SUB.B    D2,D6
            ENDIF
            MOVEM.L  D2/A1,-(A7)
            ADDQ.W   #2,A1
            SUBQ.W   #2,D2
            MOVEQ    #SP.SSTRG,D0
            JSR      DO_OUTP
            MOVEM.L  (A7)+,D2/A1
         ENDIF
IN_SKIP  ADDQ.W   #3,D2
         BCLR     #0,D2
         ADDA.W   D2,A1
         TST.W    (A1)
         BNE      IN_LOOP1
         TXSTR    {': '}
INDSPEND MOVEM.L  (A7)+,D6-D7
         RTS

         XDEF     INDEXER

INDEXER  MOVEM.L  D4-D5,-(A7)
         MOVE.L   A1,-(A7)
         MOVE.B   USERBUF+US_HELPL(A6),D4
         MOVEQ    #US.LEVEL,D5
         AND.B    D4,D5
         LSR.B    #4,D4
         SUBQ.B   #1,D4
INDAGAIN MOVE.L   (A7),A1
         BSR      IN_DISPL
GTCHOICE JSR      GETCHAR
         CMPI.B   #CR,D1
         BNE.S    IN_CHK
         MOVEQ    #-1,D4
         BRA      INDAGAIN
IN_CHK   MOVE.L   (A7),A1
         BSR.S    IN_LKUP
         BNE      GTCHOICE
         JSR      TXCHAR
         JSR      TXCRLF
         ADDQ.W   #4,A7
         MOVEM.L  (A7)+,D4-D5
         JMP      (A1)

         XDEF     IN_LKUP

IN_LKUP  MOVE.B   D1,D2
         JSR      TOUPPER
         EXG      D1,D2
         MOVE.W   (A1),D0
INDEX_1  ADDQ.W   #3,D0
         BCLR     #0,D0
         ADDA.W   D0,A1
         MOVE.W   (A1)+,D0
         BEQ.S    IND_END
         CMP.B    (A1),D5
         BLO      INDEX_1
         CMP.B    1(A1),D2
         BNE      INDEX_1
         ADDQ.W   #1,D0
         BCLR     #0,D0
         ADDA.W   D0,A1
         ADDA.W   (A1),A1
         MOVEQ    #0,D0
         RTS
IND_END  MOVEQ    #-1,D0
         RTS

EDITOR   LOG      {'Editorial',LF}
         LEA      ED_FNAM,A0
         BRA.S    SYS_TYPE

INFO     LEA      INF0FNAM,A0
         BSR.S    SYS_TYPE
         BNE.S    INFO_2
INFO_ASK MOVEQ    #10,D2
         LEA      BUFFER(A6),A1
         INPUT    {'Choose one, <ENTER> to quit: '}
         SUBQ.W   #1,D1
         BLE.S    INFO_END
         JSR      READNUM
         BNE      INFO_ASK
         TST.W    D1
         BEQ      INFO_ASK
         CMPI.W   #99,D1
         BHI      INFO_ASK
         LEA      BUFFER(A6),A0
         MOVE.L   A0,A1
         MOVE.W   #10,(A1)+
         MOVE.L   #'INFO',(A1)+
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         JSR      ITOD.W
         MOVE.L   #'_BBS',(A1)+
         BSR.S    SYS_TYPE
         BNE.S    INFO_ERR
         BSR      ASK_ENTR
         BRA      INFO
INFO_ERR TXSTR    {'No such item',CR,LF}
         BRA      INFO
INFO_END RTS
INFO_2   LEA      INF_FNAM,A0
         BRA.S    SYS_TYPE

TWITMSG  LEA      TWITFNAM,A0
SYS_TYPE LEA      S_SYSDIR(A6),A1
         JMP      TYPE

         XDEF     LOGOFF

LOGOFF   LOG      {'Logging off',LF}
         TXSTR    {'Log off'}
         JSR      YESNO
         BNE.S    NO_LOGOF
         MOVE.W   S_SYSOPM(A6),D1
         IF NE THEN
            TXSTR    {'Leave a message to '}
            LEA      S_SYSOP+1(A6),A1
            JSR      PRINTNAM
            JSR      NOYES
            IF EQ THEN
               BSR.S    L_SYSMSG
            ENDIF
         ENDIF
         LEA      LOGOUTFN,A0
         BSR      SYS_TYPE
         TXSTR    {CR,LF,'Logged on : '}
         MOVE.L   USERBUF+US_LSTLG(A6),D1
         BSR.S    TXTIME
         TXSTR    {'Logged off: '}
         QDOS     MT.RCLCK
         BSR.S    TXTIME
         JMP      LOGOUT
NO_LOGOF RTS

         XDEF     TXTIME

TXTIME   SUBA.W   #32,A7
         MOVE.L   A7,A1
         JSR      DATE$
         SUBA.W   D2,A1
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         ADDA.W   #32,A7
         JMP      TXCRLF

L_SYSMSG LEA      MAREAMSG,A2
         MOVE.W   S_SYSOPM(A6),D1
         MOVEQ    #-1,D7
         JSR      SET_AREA
         ST       SYSOPMSG(A6)
         JMP      WRITEMSG

         XDEF     STATS

STATS    TXSTR    {CR,LF,'Your statistics for '}
         QDOS     MT.RCLCK
         MOVE.L   D1,-(A7)
         BSR      TXTIME
         TXSTR    {CR,LF,'Time online this session.......... '}
         MOVE.L   (A7)+,D1
         SUB.L    USERBUF+US_LSTLG(A6),D1
         DIVU     #60,D1
         MOVEQ    #5,D2
         MOVEQ    #' ',D3
         JSR      TXNUM_F
         TXSTR    {' minutes',CR,LF,'Time remaining for this session... '}
         MOVE.W   TIMELEFT(A6),D0
         EXG      D0,D1
         SUB.W    D0,D1
         JSR      TXNUM_F
         TXSTR    {' minutes',CR,LF,'Time of previous sessions today... '}
         MOVE.W   USERBUF+US_DAYTM(A6),D1
         JSR      TXNUM_F
         TXSTR    {' minutes',CR,LF,'Time limit per day................ '}
         LEA      S_DTIME(A6),A1
         MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A6),D0
         ADD.W    D0,D0
         MOVE.W   (A1,D0.W),D1
         JSR      TXNUM_F
         TXSTR    {' minutes',CR,LF,'Number of sessions to date........ '}
         MOVE.W   USERBUF+US_CALLS(A6),D1
         JSR      TXNUM_F
         TXSTR    {CR,LF,'Previous session was on........... '}
         MOVE.L   LASTCALL(A6),D1
         BRA      TXTIME

RB_LOCAL TXSTR    {CR,LF,'No Ring-back possible in LOCAL mode!',CR,LF}
         RTS
RB_ERR   TXSTR    {CR,LF,'Sorry, but this system can''t Ring-back...',CR,LF}
         RTS
CALLBACK TST.B    LOCALMOD(A6)
         BNE.S    RB_LOCAL
         LOG      {'Requesting ringback',LF}
         MOVEQ    #SP.FBAUD,D0
         JSR      CALLSPIL
         BNE.S    RB_ERR
         MOVE.B   D1,D7
         BEQ.S    RB_ERR
         MOVEQ    #0,D6
         TXSTR    {CR,LF,'Ring Back - Possible speeds:',CR,LF,LF}
LIST_SPD BTST     D6,D7
         BEQ.S    LSPD_NXT
         MOVEQ    #'1',D1
         ADD.B    D6,D1
         JSR      TXCHAR
         TXSTR    {': '}
         LEA      SPEEDS,A1
         MOVE.W   D6,D0
         ADD.W    D0,D0
         ADDA.W   (A1,D0.W),A1
         JSR      TXSTR
         TXSTR    {' bps',CR,LF}
LSPD_NXT ADDQ.W   #1,D6
         CMPI.W   #MAXMODEM,D6
         BLE      LIST_SPD
GET_SPD  TXSTR    {CR,LF,'Choose one or <ENTER> to cancel: '}
         JSR      GETCHAR
         JSR      TXCHAR
         CMPI.B   #CR,D1
         BEQ.S    RB_END
         SUBI.B   #'1',D1
         CMPI.B   #MAXMODEM,D1
         BHI      GET_SPD
         BTST     D1,D7
         BEQ      GET_SPD
         LEA      USERBUF2(A6),A1
         MOVE.W   D1,(A1)+
         ADDQ.W   #2,A1
         MOVEQ    #80,D2
         INPUT    {CR,LF,'Enter dial string: '}
         SUBQ.W   #1,D1
         BLE.S    RB_END
         MOVE.W   D1,-(A1)
         TXSTR    {CR,LF,'I''ll ring you back in 30 seconds',CR,LF}
         TXSTR    {'When your phone rings, put your modem online in answer mode',CR,LF}
         TXSTR    {'(or back channel mode if using 1200/75 bps)',CR,LF,LF}
         MOVE.B   #2,RINGBACK(A6)
         JMP      LOGOUT
RB_END   RTS

VERSION  TXSTR    {CR,LF,'QBOX Bulletin Board System Version [version]',CR,LF}
         TXSTR    {'Copyright (C) 1987-94 by Jan Bredenbeek',CR,LF}
         TXSTR    {'This version assembled at [.DATE]',CR,LF}
         RTS

* Check time boundaries
* Entry: D1 start time, D2 end time (0-1439 minutes)
* Exit:  C-flag set (LO/CS) if within time boundary

CHKTMBND MOVEM.W  D1-D2,-(A7)
         QDOS     MT.RCLCK
         MOVEQ    #60,D2
         JSR      DIVLONG
         MOVE.W   #24*60,D2
         JSR      DIVLONG
         MOVEM.W  (A7)+,D1-D2
         SUB.W    D1,D2
         IF LO THEN
            ADDI.W   #24*60,D2
         ENDIF
         SUB.W    D1,D0
         IF LO THEN
            ADDI.W   #24*60,D0
         ENDIF
         CMP.W    D2,D0
         RTS

         XDEF     YELL

YELL     LOG      {'YELL!',LF}
         TXMSG    {'Calling sysop...'}
         TST.B    YELLFLG(A6)
         BEQ.S    NO_NOISE
         MOVEM.W  S_YSTART(A6),D1-D2
         BSR      CHKTMBND
         BCC.S    NO_NOISE
         LEA      YELLBEEP,A3
         QDOS     MT.IPCOM
NO_NOISE ST       WAITCHAR(A6)
         MOVE.W   #10*50,D3
         JSR      PAUSE
         SF       WAITCHAR(A6)
         MOVEQ    #0,D0
         TST.B    CHATFLG(A6)
         SF       CHATFLG(A6)
         IF EQ THEN
            LEA      NOBEEP,A3
            QDOS     MT.IPCOM
            TXMSG    {'Sysop not present!'}
            MOVEQ    #-1,D0
         ENDIF
         RTS
YELLBEEP DC.B     $0A,8,$55,$55,$AA,$AA,6,11,556&$FF,556/$100,0,0,16*1,0,1
         DS.W     0

         XDEF     NOBEEP

NOBEEP   DC.B     $0B,0,0,0,0,0,1

BULLETIN LEA      BUL_FNAM,A0
         BSR      SYS_TYPE
         TXSTR    {'Scanning message base...',CR,LF,LF}
         JSR      FLUSH
         LEA      NMAILFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BNE.S    SM_NMSG
         MOVEQ    #-1,D3
SM_LOOP  QDOS     IO.FBYTE
         TST.L    D0
         BNE.S    SM_NOMSG
         LEA      BUFFER(A6),A1
         MOVE.B   D1,(A1)+
         MOVEQ    #0,D2
         MOVE.B   D1,D2
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    SM_NOMSG
         MOVE.L   A1,A3
         QDOS     IO.FBYTE
         MOVE.B   D1,D2
         MOVE.L   A3,A1
         MOVE.B   D1,(A1)+
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    SM_NOMSG
         LEA      BUFFER(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      CMPNAME
         BNE      SM_LOOP
         TXSTR    {'New messages for you in area(s) '}
         MOVE.B   (A3)+,D4
         BSR.S    DSPAREAS
         BRA.S    SM_CLOS1
SM_NOMSG TXSTR    {'No new mail for you',CR,LF}
         JSR      FLUSH
SM_CLOS1 JSR      FCLOSE
SM_NMSG  MOVE.L   LASTCALL(A6),D6
         LEA      MAREAFNM,A0
         LEA      MSG_FNAM,A4
         MOVE.L   USERBUF+US_MACCS(A6),D7
         BSR.S    SCANAREA
         IF NE THEN
            TXSTR    {'There are new messages in area(s) '}
            BSR.S    DSPAREAS
         ELSE
            TXSTR    {'No new messages since your last call',CR,LF}
            JSR      FLUSH
         ENDIF
         LEA      FAREAFNM,A0
         LEA      DIR_FNAM,A4
         MOVE.L   USERBUF+US_FACCS(A6),D7
         BSR.S    SCANAREA
         IF NE THEN
            TXSTR    {'There are new files in area(s) '}
            BSR.S    DSPAREAS
         ELSE
            TXSTR    {'No new files since your last call',CR,LF}
            JSR      FLUSH
         ENDIF
         RTS

SM_COMMA TXSTR    {', '}
DSPAREAS MOVEQ    #0,D1
         MOVE.B   (A3)+,D1
         ADDQ.W   #1,D1
         JSR      TXNUMBER
         SUBQ.B   #1,D4
         BGT      SM_COMMA
         JSR      TXCRLF
         JMP      FLUSH

SCANAREA MOVEQ    #0,D4
         LEA      BUFFER+256(A6),A3
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BNE      SA_RTS
         CLR.L    INPCHAN(A6)
         MOVE.L   A0,DIRCHAN(A6)
         MOVEQ    #0,D5
SA_ALOOP MOVEQ    #127,D2
         MOVEQ    #-1,D3
         MOVE.L   DIRCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    SA_A_END
         SUBQ.W   #1,D1
         BEQ.S    SA_NXTAR
         JSR      CHK_AREA
         BNE.S    SA_NXTAR
         LEA      BUFFER(A6),A1
         LEA      DIRBUF+2(A6),A2
SA_A_DIR MOVE.B   (A1)+,D1
         CMPI.B   #' ',D1
         BLS.S    SA_A_OPN
         MOVE.B   D1,(A2)+
         BRA      SA_A_DIR
SA_A_OPN MOVE.L   A2,D1
         LEA      DIRBUF+2(A6),A1
         SUB.L    A1,D1
         MOVE.W   D1,-(A1)
         MOVE.L   A4,A0
         LEA      DIRBUF(A6),A1
         JSR      OP_FIN
         BNE.S    SA_NXTAR
         MOVEQ    #$40,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         JSR      FCLOSE
         MOVE.L   BUFFER+$0A(A6),D1
         BNE.S    SA_CMP
         MOVE.L   BUFFER+$34(A6),D1
SA_CMP   CMP.L    D1,D6
         BHI.S    SA_NXTAR
         MOVE.B   D5,(A3)+
         ADDQ.W   #1,D4
SA_NXTAR ADDQ.W   #1,D5
         CMPI.W   #MAXAREA,D5
         BLT      SA_ALOOP
SA_A_END JSR      DIRCLOSE
SA_RTS   SUBA.W   D4,A3
         TST.W    D4
         RTS

QUEST2   TXSTR    {CR,LF,'You have answered these questions already at the first login.',CR,LF}
         TXSTR    {'Do you want to answer them again'}
         JSR      NOYES
         BNE.S    QUESTRTS
QUESTION LOG      {'Answering questionnaire',LF}
         LEA      QUESTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BEQ.S    GO_QUEST
         TXSTR    {'No questionnaire today!',CR,LF}
QUESTRTS RTS
GO_QUEST MOVE.L   A0,DIRCHAN(A6)
         LEA      QRESLTFN,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FILE
         BEQ.S    GO_Q1
         LEA      QRESLTFN,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FNEW
         BNE      OP_ERROR
GO_Q1    MOVE.L   #999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         PRINT    {'User: '}
         LEA      USERBUF+US_NAME(A6),A1
         JSR      PRINTNM1
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         PRINT    {'City: '}
         LEA      USERBUF+US_CITY(A6),A1
         JSR      PRINTNM1
         PRINT    {LF,LF}
         REPEAT
            JSR      LOOKCHAR
         UNTIL    NE
QUEST_LP MOVE.L   DIRCHAN(A6),A0
         LEA      BUFFER+2(A6),A1
         MOVE.W   BUFSIZE(A6),D2
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    QUEST_EN
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         MOVE.W   D1,-(A1)
         BEQ.S    Q_NO_REP
         CMPI.B   #'',1(A1,D1.W)
         BEQ.S    Q_INPUT
Q_NO_REP JSR      TXSTR
         JSR      TXCRLF
         BRA      QUEST_LP
Q_INPUT  MOVEQ    #80,D2
         MOVE.L   A1,A0
         SUBQ.W   #1,(A0)
         LEA      1(A0,D1.W),A1
         JSR      INPUT
         MOVE.B   #LF,-1(A1,D1.W)
         MOVE.L   INPCHAN(A6),A0
         LEA      BUFFER(A6),A1
         MOVE.W   D1,D2
         ADD.W    (A1)+,D2
         QDOS     IO.SSTRG
         BRA      QUEST_LP
QUEST_EN MOVE.L   INPCHAN(A6),A0
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         JSR      FCLOSE
         JSR      DIRCLOSE

         XDEF     ASK_ENTR

ASK_ENTR TXSTR    {CR,LF,'Press <ENTER> to continue '}
         MOVEQ    #80,D2
         LEA      BUFFER(A6),A1
         JSR      GETLINE
         JMP      TXCRLF

         END
