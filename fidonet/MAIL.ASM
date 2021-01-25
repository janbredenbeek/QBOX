* MAIL - FTN-Network Mailer
* v1.01 - September 18, 1989

version  SETSTR   1.19j

         INCLUDE  FLP2_QDOS_IN_MAC

LOG      MACRO    A
[.LAB]   LOAD$    {[A]},A1
         JSR      LOG
         ENDM

TXSTR    MACRO    A
[.LAB]   LEA      .S.[.L],A1
         JSR      TXSTR
         SECTION  MSG
.S.[.L]  DC.W     .E.[.L]-(*+2)
         DC.B     [A]
.E.[.L]  EQU      *
         SECTION  CODE
         ENDM

SP.INIT  EQU      0
SP.WTCAL EQU      1
SP.DSCON EQU      2
SP.CLOSE EQU      3
SP.FBAUD EQU      4
SP.DIAL  EQU      5
SP.PEND  EQU      8
SP.FBYTE EQU      9
SP.SBYTE EQU      10
SP.SSTRG EQU      11
SP.FLUSH EQU      12
SP.DUMP  EQU      13
SP.PARIT EQU      14

NL_ID    EQU      'NL01'            Nodelist ID & version

ZONE     EQU      -1
REGION   EQU      -2
HOST     EQU      -3
HUB      EQU      -4
PVT      EQU      -5
HOLD     EQU      -6
DOWN     EQU      -7

EOT      EQU      4
ENQ      EQU      5
BELL     EQU      7
CR       EQU      $0D
LF       EQU      $0A
NAK      EQU      $15
SYN      EQU      $16
CAN      EQU      $18
TSYNC    EQU      $AE
C        EQU      $43

         XREF     LOOK_NL,DISPNODE,SEND_FTS,RECV_FTS,DO_FREQ,A2ZNNP,ZNNP2A
         XREF     TOUPPER,READNUM,OPENSYS,SKIPSPC,ITOD_W,GETDATE,GETTIME,DATE$
         XREF     MAKE_PKT,WRITEERR,SETTIMER,GETCHR1,GETCHR2,PROGRESS,PURGE_LP

         XDEF     LOGCHAN,INPCHAN,DIRCHAN,TIMEOUT,ORIGZONE,ORIGNET,ORIGNODE
         XDEF     ORIGPNT,DESTZONE,DESTNET,DESTNODE,PASSWORD,FNAMBUF,FILENAME
         XDEF     XMODBUF,NODEBUF,LOGBUF,BUFFER,BPS

         OFFSET   0

QSPILVEC DS.L     1
LOGCHAN  DS.L     1
LOGFILE  DS.L     1
COMCHAN  DS.L     1
INPCHAN  DS.L     1
DIRCHAN  DS.L     1
TIMEOUT  DS.L     1
ORIGZONE DS.W     1
ORIGNET  DS.W     1
ORIGNODE DS.W     1
ORIGPNT  DS.W     1
DESTZONE DS.W     1
DESTNET  DS.W     1
DESTNODE DS.W     1
BPS      DS.W     1
TRYDELAY DS.W     1
LOGDATE  DS.W     1
NOPICKUP DS.B     1
CALLTRYS DS.B     1
FAILTRYS DS.B     1
         DS.W     0
PASSWORD DS.B     8
         DS.W     1
LOGBUF   DS.B     80
FNAMBUF  DS.B     50
FILENAME DS.B     50
XMODBUF  DS.B     132
NODEBUF  DS.B     100
BUFFER   DS.B     32768

         DATA     34*1024

         XDEF     SYSDIR,INBD_DIR,OTBD_DIR,NDLSTFNM

         SECTION  CODE

         JMP      JOBSTART          Skip job header
         DC.W     0                 Starts at 6 so pad 2 bytes...
         DC.W     $4AFB             Ident flag
JOBNAME  STRING$  {'MAIL'}          Name of program
         DS.W     0
MYZONE   DC.W     0
MYNET    DC.W     0
MYNODE   DC.W     0
MYPOINT  DC.W     0
SYSDIR   STRING$  'flp1_'
         DS.B     50-(*-SYSDIR)
LOGNAME  STRING$  'ram1_MAIL_LOG'
         DS.B     50-(*-LOGNAME)
INBD_DIR STRING$  'flp1_IN_'
         DS.B     50-(*-INBD_DIR)
OTBD_DIR STRING$  'flp1_OUT_'
         DS.B     50-(*-OTBD_DIR)
QSPILFNM STRING$  'QSPHAYES'
         DS.B     50-(*-QSPILFNM)
DIAL_PRE DC.B     'T',0
         DS.B     25-(*-DIAL_PRE)
DIAL1    DC.B     '31-35-',0
         DS.B     25-(*-DIAL1)
DIAL2    DC.B     '31- 0',0
         DS.B     25-(*-DIAL2)
DIAL3    DC.B     0
         DS.B     25-(*-DIAL3)
DIAL4    DC.B     '00-'
         DS.B     25-(*-DIAL4)
NDLSTFNM STRING$  'NODELIST_BBS'
         DS.W     0
BANNER   DC.B     4,1,4,0
         DC.W     448,182,32,20
CONSPEC  DC.B     0,0,0,7
         DC.W     444,170,34,31

JOBSTART ADDA.L   A4,A6
         CLR.L    LOGCHAN(A6)
         MOVE.W   (A7)+,D0
         BEQ.S    OPEN_CON
         MOVE.L   (A7),A0
         LSL.W    #2,D0
         ADDA.W   D0,A7
         BRA.S    SET_CON
OPEN_CON LEA      BANNER,A1
         MOVE.W   UT_SCR,A2
         JSR      (A2)
         BNE.S    CON_ERR
         LEA      JOBNAME,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         LEA      CONSPEC,A1
         MOVE.W   UT_CON,A2
         JSR      (A2)
         BEQ.S    SET_CON
CON_ERR  MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'MAIL: Unable to open screen window',LF}
         MOVE.L   (A7)+,D0
         BRA      KILL_JOB
SET_CON  MOVE.L   A0,LOGCHAN(A6)
         PRINT    {'MAIL  FTN-Network Mailer v[version]  [.DATE]',LF}
         PRINT    {'Copyright  1989-93 by Jan Bredenbeek',LF,LF}
         MOVE.L   A7,A0
         LEA      BUFFER(A6),A1
         MOVE.W   (A0)+,D0
         BEQ      BADPARAM
COPYPARA MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D0
         BGT      COPYPARA
         MOVE.B   #LF,(A1)+
         SF       NOPICKUP(A6)
         MOVE.B   #30,CALLTRYS(A6)
         MOVE.B   #2,FAILTRYS(A6)
         MOVE.W   #60,TRYDELAY(A6)
         MOVE.L   MYZONE(PC),ORIGZONE(A6)
         MOVE.L   MYNODE(PC),ORIGNODE(A6)
         CLR.L    LOGFILE(A6)
         CLR.L    PASSWORD(A6)
         CLR.L    PASSWORD+4(A6)
         LEA      BUFFER(A6),A1
         JSR      SKIPSPC
         BEQ      BADPARAM
         MOVEM.W  ORIGZONE(A6),D2-D4
         JSR      A2ZNNP
         BNE      BADPARAM
         MOVEM.W  D2-D4,DESTZONE(A6)
ARG_LOOP JSR      SKIPSPC
         BEQ      LDQSPIL
         MOVE.B   (A1)+,D1
         JSR      TOUPPER
         CMPI.B   #'A',D1
         BNE.S    ARG_NP
         CMPI.B   #'=',(A1)+
         BNE      BADPARAM
         MOVEM.W  DESTZONE(A6),D2-D4
         JSR      A2ZNNP
         BNE      BADPARAM
         MOVEM.W  D2-D5,ORIGZONE(A6)
         BRA      ARG_LOOP
ARG_NP   CMPI.B   #'N',D1
         BNE.S    ARG_R
         MOVE.B   (A1),D1
         JSR      TOUPPER
         CMPI.B   #'P',D1
         BNE.S    BADPARAM
         ADDQ.W   #1,A1
         ST       NOPICKUP(A6)
         BRA      ARG_LOOP
ARG_R    CMPI.B   #'R',D1
         BNE.S    ARG_D
         CMPI.B   #'=',(A1)+
         BNE.S    BADPARAM
         JSR      READNUM
         BNE.S    BADPARAM
         MOVE.B   D1,CALLTRYS(A6)
         CMPI.B   #',',(A1)
         BNE      ARG_LOOP
         ADDQ.W   #1,A1
         JSR      READNUM
         BNE.S    BADPARAM
         MOVE.B   D1,FAILTRYS(A6)
         BRA      ARG_LOOP
ARG_D    CMPI.B   #'D',D1
         BNE.S    ARG_PWD
         CMPI.B   #'=',(A1)+
         BNE.S    BADPARAM
         JSR      READNUM
         BNE.S    BADPARAM
         MOVE.W   D1,TRYDELAY(A6)
         BRA      ARG_LOOP
ARG_PWD  CMPI.B   #'!',D1
         BNE.S    BADPARAM
         LEA      PASSWORD(A6),A0
         MOVEQ    #8,D0
PWD_LOOP CMPI.B   #' ',(A1)
         BLS      ARG_LOOP
         MOVE.B   (A1)+,(A0)+
         SUBQ.B   #1,D0
         BGT      PWD_LOOP
PWD_END  CMPI.B   #' ',(A1)
         BLS      ARG_LOOP
         ADDQ.W   #1,A1
         BRA      PWD_END
BADPARAM MOVE.L   LOGCHAN(A6),A0
         PRINT    {'Usage: EW <dev>MAIL',$5B,',#channel];"<destaddr> ',$5B,'<flag>] ',$5B,'<flag>] ..."',LF,LF}
         PRINT    {'<flag> = A=<origaddr>                 (use alternative origin address)',LF}
         PRINT    {'       | D=<delay>                    (time in seconds between calls)',LF}
         PRINT    {'       | NP                           (don''t pickup mail from remote)',LF}
         PRINT    {'       | R=<callcount>',$5B,',<failcount>]  (specify call/failed connect limits)',LF}
         PRINT    {'       | !<password>                  (specify session password)',LF,LF}
         PRINT    {'Press any key to exit',LF}
         QDOS     SD.CURE
         MOVE.W   #30*50,D3
         QDOS     IO.FBYTE
         QDOS     SD.CURS
         MOVEQ    #ERR.BP,D0
         BRA      KILL_JOB

LDQSPIL  BSR      OPEN_LOG
         MOVEQ    #IO.SHARE,D3
         LEA      QSPILFNM,A0
         BSR      OPENSYS
         BNE      QSPIL_ER
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      QSPIL_ER
         MOVE.L   -(A1),D1
         MOVEQ    #-1,D2
         MOVE.L   A0,-(A7)
         QDOS     MT.ALCHP
         MOVE.L   A0,A1
         MOVE.L   (A7)+,A0
         TST.L    D0
         BNE      QSPIL_ER
         MOVE.L   A1,QSPILVEC(A6)
         MOVE.L   BUFFER(A6),D2
         MOVEQ    #-1,D3
         QDOS     FS.LOAD
         TST.L    D0
         BNE      QSPIL_ER
         QDOS     IO.CLOSE
         MOVEQ    #SP.INIT,D0
         MOVEQ    #-1,D1
         BSR      CALLSPIL
         BNE      QSPIL_ER
         MOVE.L   A0,COMCHAN(A6)
GO_PROC  BSR      PROCESS
         BEQ      KILL_JOB
         CMPI.L   #ERR.NC,D0
         BEQ.S    DEC_FAIL
         CMPI.L   #ERR.IU,D0
         BNE      KILL_JOB
         SUBQ.B   #1,CALLTRYS(A6)
         BNE.S    WAIT
         LOG      {'? Exceeded busy retry limit',LF}
         MOVEQ    #0,D0
         BRA      KILL_JOB
DEC_FAIL SUBQ.B   #1,FAILTRYS(A6)
         BNE.S    WAIT
         LOG      {'? Exceeded failure retry limit',LF}
         MOVEQ    #0,D0
         BRA      KILL_JOB
WAIT     MOVE.L   LOGCHAN(A6),A0
         LOAD$    {'Waiting; press SPACE to force dial or ESC to cancel: '},A1
         MOVE.W   (A1)+,D2
         MOVEQ    #0,D3
         QDOS     IO.SSTRG
         QDOS     SD.CURE
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   4(A7),D4
         ADDQ.W   #8,A7
         MOVE.W   TRYDELAY(A6),D5
WAIT_LP  MOVE.W   D5,D1
         MOVEQ    #0,D2
         LEA      BUFFER(A6),A1
         JSR      ITOD_W
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         QDOS     IO.SSTRG
         MOVEQ    #50,D3
         BSR      PAUSE
         MOVEQ    #0,D3
         QDOS     IO.FBYTE
         MOVEM.L  D0-D1,-(A7)
         MOVE.W   D4,D1
         QDOS     SD.TAB
         QDOS     SD.CLRRT
         MOVEM.L  (A7)+,D0-D1
         SUBQ.W   #1,D5
         BLE.S    WAIT_END
         CMPI.L   #ERR.NC,D0
         BEQ      WAIT_LP
WAIT_END MOVEM.L  D0-D1,-(A7)
         QDOS     SD.CURS
         MOVEQ    #0,D1
         QDOS     SD.TAB
         QDOS     SD.CLRLN
         MOVEM.L  (A7)+,D0-D1
         CMPI.L   #ERR.NC,D0
         BEQ      GO_PROC
         CMPI.B   #$1B,D1
         BNE      GO_PROC
         MOVEQ    #0,D0
         BRA.S    KILL_JOB
QSPIL_ER LOG      {'! Unable to load or initialise QSPIL driver',LF}
KILL_JOB MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

         XDEF     TXCHAR,TXSTR,FLUSH,DUMP_OPB,DO_OUTP

TXCHAR   MOVEQ    #SP.SBYTE,D0
         BRA.S    DO_OUTP
TXSTR    MOVEQ    #SP.SSTRG,D0
         MOVE.W   (A1)+,D2
         BRA.S    DO_OUTP
FLUSH    MOVEQ    #SP.FLUSH,D0
         BRA.S    DO_OUTP
DUMP_OPB MOVEQ    #SP.DUMP,D0
DO_OUTP  MOVEM.L  D1/D3/A0,-(A7)
         MOVEQ    #-1,D3
         MOVE.L   COMCHAN(A6),A0
         BSR.S    CALLSPIL
         MOVEM.L  (A7)+,D1/D3/A0
         RTS

         XDEF     DO_INP

DO_INP   MOVE.L   A0,-(A7)
         MOVE.L   COMCHAN(A6),A0
         BSR.S    CALLSPIL
         MOVE.L   (A7)+,A0
         RTS

CALLSPIL MOVEM.L  D2-D7/A1-A6,-(A7)
         LEA      LOG,A4
         MOVE.L   QSPILVEC(A6),A5
         JSR      (A5)
         MOVEM.L  (A7)+,D2-D7/A1-A6
         TST.L    D0
         RTS

OPEN_LOG CLR.W    LOGDATE(A6)
         LEA      LOGNAME(PC),A0
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
         LOG      {'? Unable to open logfile: '}

         XDEF     LOGERR

LOGERR   MOVE.L   D0,-(A7)
         MOVE.L   LOGCHAN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         MOVE.L   (A7)+,D0
LOGERR_2 MOVE.L   LOGFILE(A6),A0
         MOVE.W   UT_ERR,A2
         JMP      (A2)

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
         LOAD$    {'MAIL',LF},A1
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

LOG_ALL  MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     IO.SSTRG
         SUBA.W   D1,A1
LOG_FILE MOVEQ    #-1,D3
         MOVE.L   LOGFILE(A6),A0
         QDOS     IO.SSTRG
         RTS

         XDEF     PAUSE

PAUSE    MOVEM.L  D1/A0-A1,-(A7)
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         MOVEM.L  (A7)+,D1/A0-A1
         RTS

         XDEF     FCLOSE

FCLOSE   MOVE.L   INPCHAN(A6),A0
         MOVE.L   A0,D0
         BEQ.S    FCLOS_EN
         QDOS     IO.CLOSE
         CLR.L    INPCHAN(A6)
FCLOS_EN RTS

         XDEF     DIRCLOSE

DIRCLOSE MOVE.L   DIRCHAN(A6),A0
         MOVE.L   A0,D0
         BEQ.S    FCLOS_EN
         QDOS     IO.CLOSE
         CLR.L    DIRCHAN(A6)
         RTS

DIAL_SUB TST.B    (A0)
         BEQ.S    DS_NOMAT
         MOVE.L   A1,-(A7)
DS_LOOP1 MOVE.B   (A0)+,D0
         BEQ.S    DS_REM
         CMPI.B   #' ',D0
         BEQ.S    DS_SUB
         CMP.B    (A1)+,D0
         BEQ      DS_LOOP1
         MOVE.L   (A7)+,A1
DS_NOMAT MOVEQ    #ERR.NF,D0
         RTS
DS_PRFIX MOVE.L   A1,-(A7)
DS_SUB   MOVE.B   (A0)+,D0
         BEQ.S    DS_REM
         CMPI.B   #'-',D0
         BEQ.S    DS_NUM
         MOVE.B   D0,(A2)+
         BRA      DS_SUB
DS_NUM   MOVE.B   (A1)+,D0
         BEQ.S    DS_END
         CMPI.B   #'-',D0
         BEQ      DS_SUB
         MOVE.B   D0,(A2)+
         BRA      DS_NUM
DS_REM   MOVE.B   (A1)+,D0
         BEQ.S    DS_END
         CMPI.B   #'-',D0
         BEQ      DS_REM
         MOVE.B   D0,(A2)+
         BRA      DS_REM
DS_END   ADDQ.W   #4,A7
         MOVEQ    #0,D0
         RTS

PROCESS  BSR      LOOK_NL
         BEQ.S    TSTNODE
         CMPI.L   #ERR.BP,D0
         BEQ.S    NL_ERROR
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Unlisted system: '},A1
         LEA      DESTZONE(A6),A2
         JSR      ZNNP2A
         CLR.B    (A1)+
         JMP      LOG0
NL_ERROR LOG      {'? Nodelist access error',LF}
EXIT_1   RTS
TSTNODE  CMPI.W   #HUB,NODEBUF(A6)
         BGE.S    NODE_OK
         LOG      {'? System is PVT, HOLD or DOWN',LF}
         MOVEQ    #ERR.BP,D0
EXIT_ERR RTS
NODE_OK  JSR      DISPNODE
         CLR.B    (A1)+
         LEA      LOGBUF(A6),A1
         WRITE$   {'+ Calling '},A1
         LEA      BUFFER(A6),A2
CPYNNAME MOVE.B   (A2)+,(A1)+
         BNE      CPYNNAME
         JSR      LOG0
         MOVE.L   A0,A1
ENDNUM   TST.B    (A0)+
         BPL      ENDNUM
         ANDI.B   #$7F,-1(A0)
         CLR.B    (A0)
         LEA      BUFFER+2(A6),A2
         LEA      DIAL_PRE(PC),A0
COPY_PRE MOVE.B   (A0)+,(A2)+
         BNE      COPY_PRE
         SUBQ.W   #1,A2
         LEA      DIAL1(PC),A0
         BSR      DIAL_SUB
         BEQ.S    GO_DIAL
         LEA      DIAL2(PC),A0
         BSR      DIAL_SUB
         BEQ.S    GO_DIAL
         LEA      DIAL3(PC),A0
         BSR      DIAL_SUB
         BEQ.S    GO_DIAL
         LEA      DIAL4(PC),A0
         BSR      DS_PRFIX
GO_DIAL  LEA      BUFFER+2(A6),A0
         MOVE.L   A2,D0
         SUB.L    A0,D0
         MOVE.W   D0,-(A0)
         LEA      LOGBUF(A6),A1
         WRITE$   {'+ Dialling '},A1
         WRITE$
         MOVEQ    #SP.FBAUD,D0
         BSR      CALLSPIL
         BNE.S    DIAL_ERR
         MOVEQ    #15,D5
         TST.B    D1
         BNE.S    DIAL_SPD
DIAL_ERR LOG      {'? QSPIL driver does not support auto-dial',LF}
         MOVEQ    #ERR.BP,D0
         RTS
DIAL_SPD BTST     D5,D1
         DBNE     D5,DIAL_SPD
         WRITE$   {' at '},A1
         LEA      BAUDTBL,A0
         MOVE.W   D5,D0
         LSL.W    #2,D0
         MOVE.W   (A0,D0.W),BPS(A6)
         ADDA.W   2(A0,D0.W),A0
         WRITE$
         WRITE$   {' bps',0}
         BSR      LOG0
         MOVEQ    #SP.DIAL,D0
         MOVEQ    #-1,D1
         MOVE.L   D5,D2
         MOVE.L   COMCHAN(A6),A0
         LEA      BUFFER(A6),A1
         BSR      CALLSPIL
         BEQ.S    CONNECT
         CMPI.L   #ERR.NC,D0
         BEQ.S    NOCARIER
         CMPI.L   #ERR.IU,D0
         BEQ.S    BUSY
         LEA      LOGBUF(A6),A1
         WRITE$   {'? QSPIL error: '}
         JSR      WRITEERR
         CLR.B    (A1)+
         BRA      LOG0
NOCARIER LOG      {'+ No connection',LF}
         MOVEQ    #ERR.IU,D0
         RTS
BUSY     LOG      {'+ Busy',LF}
         RTS
CONNECT  MOVE.L   A0,COMCHAN(A6)
         LEA      LOGBUF(A6),A1
         CMPI.B   #15,D1
         BHI.S    NOSPEED
         WRITE$   {'+ Connection at '},A1
         LEA      BAUDTBL,A0
         EXT.W    D1
         LSL.W    #2,D1
         MOVE.W   (A0,D1.W),BPS(A6)
         ADDA.W   2(A0,D1.W),A0
         WRITE$
         WRITE$   {' bps',0},A1
         BRA.S    WHACK
NOSPEED  WRITE$   {'+ Connection at unknown speed',0}
WHACK    BSR      LOG0
         MOVEQ    #50,D3
         JSR      PURGE_LP
         MOVEQ    #30,D1
         JSR      SETTIMER
         MOVEQ    #CR,D2
GET_CR   MOVEQ    #75,D3
         JSR      GETCHR1
         BLT      NO_RESP
         BGT.S    WHACK_CR
         CMPI.B   #CR,D1
         BNE      GET_CR
         BRA.S    SENDMAIL
WHACK_CR LOAD$    {'Initiating remote',LF}
         BSR      PROGRESS
         MOVE.B   D2,D1
         MOVEQ    #45,D2
         SUB.B    D1,D2             Alternate between CR and SPACE
         JSR      TXCHAR
         BRA      GET_CR
SENDMAIL JSR      SEND_FTS
         BNE.S    HANG_UP
GET_PKUP LOAD$    {'Waiting for response from remote',LF}
         MOVEQ    #45,D1
         JSR      SETTIMER
         MOVEQ    #0,D2
GTINTENT MOVE.W   #45*50,D3
         JSR      GETCHR2
         BNE.S    SESS_OK
         CMPI.B   #TSYNC,D1
         BEQ.S    RECVMAIL
         CMPI.B   #SYN,D1
         BEQ.S    NO_FRQ
         CMPI.B   #ENQ,D1
         BEQ.S    FREQUEST
         CMPI.B   #NAK,D1
         BEQ.S    SEND_EOT
         CMPI.B   #C,D1
         BNE      GTINTENT
SEND_EOT MOVEQ    #EOT,D1
         JSR      TXCHAR
         BRA      GTINTENT
RECVMAIL TST.B    NOPICKUP(A6)
         BEQ.S    RCVMAIL2
         TST.B    D2
         BNE.S    SESS_OK
NO_FRQ   ADDQ.B   #1,D2
         MOVEQ    #CAN,D1
         JSR      TXCHAR
         BRA      GTINTENT
RCVMAIL2 JSR      RECV_FTS
         BNE.S    HANG_UP
         BRA      GET_PKUP
FREQUEST JSR      DO_FREQ
         BRA      GET_PKUP
SESS_OK  LOG      {'+ Session successful',LF}
         MOVEQ    #0,D0
         BRA.S    HANGUP2
NO_RESP  LOG      {'? No response from remote',LF}
HANG_UP  LOG      {'? Session failed',LF}
         MOVEQ    #ERR.NC,D0
HANGUP2  MOVE.L   D0,-(A7)
         MOVE.L   COMCHAN(A6),A0
         MOVEQ    #SP.DSCON,D0
         BSR      CALLSPIL
         MOVE.L   (A7)+,D0
         RTS

         SECTION  MSG

BAUDTBL  DC.W     300,B300-BAUDTBL
         DC.W     1200,B1275-BAUDTBL
         DC.W     1200,B1200-BAUDTBL
         DC.W     2400,B2400-BAUDTBL
         DC.W     4800,B4800-BAUDTBL
         DC.W     9600,B9600-BAUDTBL
         DC.W     19200,B19200-BAUDTBL
         DC.W     38400,B38400-BAUDTBL
         DC.W     7200,B7200-BAUDTBL
         DC.W     12000,B12000-BAUDTBL
         DC.W     14400,B14400-BAUDTBL
         DC.W     16800,B16800-BAUDTBL
         DC.W     21600,B21600-BAUDTBL
         DC.W     24000,B24000-BAUDTBL
         DC.W     26400,B26400-BAUDTBL
         DC.W     28800,B28800-BAUDTBL
B300     STRING$  '300'
B1275    STRING$  '1200/75'
B1200    STRING$  '1200'
B2400    STRING$  '2400'
B4800    STRING$  '4800'
B9600    STRING$  '9600'
B19200   STRING$  '19200'
B38400   STRING$  '38400'
B7200    STRING$  '7200'
B12000   STRING$  '12000'
B14400   STRING$  '14400'
B16800   STRING$  '16800'
B21600   STRING$  '21600'
B24000   STRING$  '24000'
B26400   STRING$  '26400'
B28800   STRING$  '28800'

         DC.W     0

         END
