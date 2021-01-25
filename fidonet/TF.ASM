* TempFront - Temporary QBOX FidoNet Mailer
* v1.01 - September 18, 1989

version  SETSTR   1.04

         INCLUDE  WIN1_UTILS_QDOS_IN_MAC

PRLOG    MACRO    A
[.LAB]   LEA      .S.[.L],A1
         JSR      PRLOG
         SECTION  MSG
.S.[.L]  DC.W     .E.[.L]-(*+2)
         DC.B     [A]
.E.[.L]  EQU      *
         SECTION  CODE
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

FTSCPROD EQU      $54

NL_ID    EQU      'NL01'

ZONE     EQU      -1
REGION   EQU      -2
HOST     EQU      -3
HUB      EQU      -4
PVT      EQU      -5
HOLD     EQU      -6
DOWN     EQU      -7

BELL     EQU      7
CR       EQU      $0D
LF       EQU      $0A
FF       EQU      $0C
ESC      EQU      $1B
FXBUFLEN EQU      8192

         OFFSET   0

QBOXVARS DS.L     1
PRLOGVEC DS.L     1
OWNERJOB DS.L     1
LOGCHAN  DS.L     1
COMCHAN  DS.L     1
INPCHAN  DS.L     1
DIRCHAN  DS.L     1
ERR_SP   DS.L     1
TIMEOUT  DS.L     1
CONSPEED DS.W     1
DESTZONE DS.W     1
DESTNET  DS.W     1
DESTNODE DS.W     1
FNAMBUF  DS.B     50
USERBUF2 DS.B     144
XMODBUF  DS.B     132
NODEBUF  DS.B     100
BUFFER   DS.B     FXBUFLEN

DATASPC  EQU      *

         SECTION  CODE

         JMP      START
CFGVER   DC.W     104
MYZONE   DC.W     2
MYNET    DC.W     9999
MYNODE   DC.W     9999
MO_START DC.W     0
MO_END   DC.W     0
SYSDIR   STRING$  'win1_QBOX_SYS_'
         DS.B     50-(*-SYSDIR)
INBD_DIR STRING$  'win1_QBOX_IN_'
         DS.B     50-(*-INBD_DIR)
OTBD_DIR STRING$  'win1_QBOX_OUT_'
         DS.B     50-(*-OTBD_DIR)
NDLSTFNM STRING$  'NODELIST_BBS'

START    CMPI.B   #SP.WTCALL,D0
         BNE      OLDQSPIL
         LEA      STORAGE,A5
         MOVE.L   D1,OWNERJOB(A5)
         MOVE.L   A4,PRLOGVEC(A5)
         MOVE.L   A6,QBOXVARS(A5)
START_2  MOVEQ    #-1,D3
         JSR      OLDQSPIL
         TST.L    D0
         BNE      RET_QBOX
         MOVE.L   4(A6),D0
         LEA      STORAGE,A6
         MOVE.L   D0,LOGCHAN(A6)
         MOVE.L   A0,COMCHAN(A6)
         MOVE.W   D1,CONSPEED(A6)
         BLT.S    NOSPEED
         PRLOG    {'CONNECTION AT '}
         MOVE.L   D0,A0
         LEA      BAUDTBL,A1
         ADD.W    D1,D1
         ADDA.W   (A1,D1.W),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         PRINT    {' BPS',LF}
         BRA.S    WHACK
NOSPEED  PRLOG    {'CONNECTION SPEED UNKNOWN',LF}
WHACK    JSR      SET1MIN
PURGE1   JSR      CHKTIMER
         BNE.S    DISCON
         MOVEQ    #5,D3
         JSR      PURGE_LP
WHACK2   MOVE.W   #5*50,D3
         JSR      GETCHR1
         BLT.S    DISCON
         BGT.S    TSIGNON
         CMPI.B   #CR,D1
         BEQ.S    WHACK3
         CMPI.B   #' ',D1
         BNE      PURGE1
WHACK3   JSR      CHKTIMER
         BNE.S    DISCON
         MOVEQ    #5,D3
         JSR      GETCHR1
         BLT.S    DISCON
         BGT.S    TSIGNON
         CMPI.B   #CR,D1
         BEQ      WHACK3
         CMPI.B   #' ',D1
         BEQ      WHACK3
         BRA      PURGE1
TSIGNON  TXSTR    {FF,'QBoxMail v[version]  (C)JB''89-''90',CR,LF,LF}
         QDOS     MT.RCLCK
         MOVEQ    #60,D2
         BSR      DIVLONG
         MOVE.W   #24*60,D2
         BSR      DIVLONG
         MOVE.W   MO_START,D1
         MOVE.W   MO_END,D2
         CMP.W    D1,D2
         BLO.S    CHKMO_2
         SF       D7
         CMP.W    D1,D0
         BLO.S    TXSIGNON
         CMP.W    D2,D0
         SLO      D7
         BRA.S    TXSIGNON
CHKMO_2  ST       D7
         CMP.W    D1,D0
         BHS.S    TXSIGNON
         CMP.W    D2,D0
         SLO      D7
TXSIGNON TST.B    D7
         BNE.S    ML_ONLY
         TXSTR    {'Press <ESC> for BBS or wait 10 seconds',CR}
         BRA.S    TXS_PURG
ML_ONLY  TXSTR    {'System does not allow human callers right now, please hang up',CR}
TXS_PURG MOVEQ    #5,D3
         JSR      PURGE_LP
GT_TSYNC JSR      CHKTIMER
         BNE.S    DISCON
         MOVE.W   #10*50,D3
         JSR      GETCHR1
         BLT.S    DISCON
         BGT.S    GO_BBS
         CMPI.B   #CR,D1
         BEQ      TXSIGNON
         CMPI.B   #' ',D1
         BEQ      TXSIGNON
         CMPI.B   #ESC,D1
         BEQ.S    GO_BBS
         CMPI.B   #TSYNC,D1
         BNE      GT_TSYNC
         BSR      DO_MAIL
         MOVEQ    #50,D3
         BSR      PAUSE
DISCON   MOVE.L   COMCHAN(A6),A0
         MOVEQ    #SP.DSCON,D0
         BSR      CALLSPIL
         PRLOG    {'LINE DISCONNECTED',LF}
         MOVEQ    #2*50,D3
         BSR      PAUSE
         PRLOG    {'WAITING FOR CALL',LF}
         MOVEQ    #SP.WTCALL,D0
         MOVE.L   OWNERJOB(A6),D1
         MOVE.L   COMCHAN(A6),A0
         MOVE.L   PRLOGVEC(A6),A4
         MOVE.L   QBOXVARS(A6),A6
         BRA      START_2
GO_BBS   TST.B    D7
         BEQ.S    GO_BBS2
         PRLOG    {'REJECTING HUMAN CALLER',LF}
         BRA      DISCON
GO_BBS2  PRLOG    {'SWITCHING TO BBS',LF}
         MOVEQ    #0,D0
         MOVE.W   CONSPEED(A6),D1
         MOVE.L   COMCHAN(A6),A0
         MOVE.L   QBOXVARS(A6),A6
RET_QBOX RTS

READNUM  CMPI.B   #'0',(A1)
         BLO.S    GN_ERR
         CMPI.B   #'9',(A1)
         BHI.S    GN_ERR
         MOVEQ    #0,D0
         MOVEQ    #0,D1
GN_LOOP  MOVE.B   (A1),D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    GN_END
         ADDQ.W   #1,A1
         MULU     #10,D1
         ADD.W    D0,D1
         BRA      GN_LOOP
GN_END   MOVEQ    #0,D0
         RTS
GN_ERR   MOVEQ    #ERR.XP,D0
         RTS

TOUPPER  CMPI.B   #'a',D1
         BLT.S    TU_END
         CMPI.B   #'z',D1
         BGT.S    TU_END
         SUBI.B   #'a'-'A',D1
TU_END   RTS

PRLOG    PEA      PRLOG_RT
         MOVE.L   PRLOGVEC(A6),-(A7)
         MOVE.L   QBOXVARS(A6),A6
         RTS
PRLOG_RT LEA      STORAGE,A6
         RTS

TXCHAR   MOVEQ    #SP.SBYTE,D0
         BRA.S    DO_OUTP
TXSTR    MOVEQ    #SP.SSTRG,D0
         MOVE.W   (A1)+,D2
         BRA.S    DO_OUTP
FLUSH    MOVEQ    #SP.FLUSH,D0
DO_OUTP  MOVEM.L  D1/D3/A0,-(A7)
         MOVEQ    #-1,D3
         MOVE.L   COMCHAN(A6),A0
         BSR.S    CALLSPIL
         MOVEM.L  (A7)+,D1/D3/A0
         RTS

DO_INP   MOVE.L   A0,-(A7)
         MOVE.L   COMCHAN(A6),A0
         BSR.S    CALLSPIL
         MOVE.L   (A7)+,A0
         RTS

CALLSPIL MOVEM.L  D2-D7/A1-A5,-(A7)
         MOVE.L   PRLOGVEC(A6),A4
         MOVE.L   QBOXVARS(A6),A6
         JSR      OLDQSPIL
         LEA      STORAGE,A6
         MOVEM.L  (A7)+,D2-D7/A1-A5
         TST.L    D0
         RTS

* DIVIDE D1.L BY D2.W
* QUOTIENT IN D1.L, REMAINDER IN D0.W

DIVLONG  MOVEQ    #0,D0
         SWAP     D1
         MOVE.W   D1,D0
         DIVU     D2,D0
         SWAP     D0
         MOVE.W   D0,D1
         SWAP     D1
         DIVU     D2,D1
         MOVE.W   D1,D0
         SWAP     D1
         EXG      D0,D1
         RTS

* Date conversion routine
* Entry: D1 QDOS date, A1 pointer to string buffer
* Date format: DD MMM YY  HH:MM:SS

* Date conversion routine
* Entry: D1 QDOS date
* Exit: D0L month-1, D1L day of month, D2L year, D2H hours, D3L mins, D3H secs
*       D0H day of week (Sun=0)

GETDATE  MOVEQ    #60,D2
         BSR      DIVLONG
         MOVE.W   D0,D3
         SWAP     D3
         BSR      DIVLONG
         MOVE.W   D0,D3
         DIVU     #24,D1
         MOVE.L   D1,D2
         MOVEQ    #0,D0
         MOVE.W   D1,D0
         DIVU     #7,D0
         MOVEQ    #100,D4
         MULU     D4,D1
         ADDI.L   #30675,D1
         DIVU     #36525,D1
         MOVE.W   D1,D2
         ADDI.W   #1960,D2
         CLR.W    D1
         SWAP     D1
         DIVU     D4,D1
         ADDI.W   #123,D1
         MULU     D4,D1
         DIVU     #3061,D1
         SUBQ.W   #2,D1
         CMPI.W   #12,D1
         BLT.S    GD_2
         SUBI.W   #12,D1
         ADDQ.W   #1,D2
GD_2     MOVE.W   D1,D0
         CLR.W    D1
         SWAP     D1
         DIVU     D4,D1
         ADDQ.W   #1,D1
         RTS

ZNN_TO_H LEA      BUFFER(A6),A1
         MOVE.W   #16,(A1)+
         MOVE.W   DESTZONE(A6),D1
         BSR.S    ITOH_W
         MOVE.W   DESTNET(A6),D1
         BSR.S    ITOH_W
         MOVE.W   DESTNODE(A6),D1
ITOH_W   MOVEQ    #3,D2
ITOHW_LP ROL.W    #4,D1
         MOVEQ    #$0F,D0
         AND.B    D1,D0
         CMPI.B   #9,D0
         BLS.S    ITOHW_2
         ADDQ.B   #7,D0
ITOHW_2  ADDI.B   #'0',D0
         MOVE.B   D0,(A1)+
         DBF      D2,ITOHW_LP
         RTS

OPEN_PKT MOVE.L   #'_PKT',D3
         LEA      INPCHAN(A6),A3
         BRA.S    OP_INP
OPEN_ATT MOVE.L   #'_ATT',D3
         LEA      DIRCHAN(A6),A3
         BRA.S    OP_INP
OPEN_FRQ MOVE.L   #'_FRQ',D3
         LEA      DIRCHAN(A6),A3
OP_INP   BSR.S    OP_NAME
         BNE.S    OI_END
         BRA.S    STO_INP
OP_FILE  MOVEQ    #IO.EXCL,D3
         BRA.S    OP_FALL
OP_FNEW  MOVEQ    #IO.NEW,D3
         BRA.S    OP_FALL
OP_FOVER MOVEQ    #IO.OVER,D3
OP_FALL  BSR.S    OPEN_2
         BNE.S    OI_END
         LEA      INPCHAN(A6),A3
STO_INP  MOVE.L   A0,(A3)
OI_END   TST.L    D0
         RTS
OP_NAME  BSR      ZNN_TO_H
         MOVE.L   D3,(A1)+
         MOVEQ    #IO.SHARE,D3
         LEA      BUFFER(A6),A0
         LEA      OTBD_DIR(PC),A1
         BRA.S    OPEN_2
OPENSYS  LEA      SYSDIR(PC),A1
OPEN_2   BSR.S    MKFNAME
OPEN_3   MOVEM.L  D3/A0,-(A7)
OPEN3_LP MOVEQ    #-1,D1
         MOVEM.L  (A7),D3/A0
         QDOS     IO.OPEN
         CMPI.L   #ERR.IU,D0
         BNE.S    OPEN_END
         MOVEQ    #50,D3
         BSR.S    PAUSE
         BRA      OPEN3_LP
OPEN_END ADDQ.W   #8,A7
         TST.L    D0
         RTS

PAUSE    MOVEM.L  D1/A0-A1,-(A7)
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         MOVEM.L  (A7)+,D1/A0-A1
         RTS

FCLOSE   MOVE.L   INPCHAN(A6),A0
         QDOS     IO.CLOSE
         RTS

DIRCLOSE MOVE.L   DIRCHAN(A6),A0
         QDOS     IO.CLOSE
         RTS

MKFNAME  LEA      FNAMBUF(A6),A2
         MOVE.W   (A0)+,D0
         MOVE.W   (A1)+,D1
         MOVE.W   D0,(A2)
         ADD.W    D1,(A2)+
OPEN_LP1 MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      OPEN_LP1
OPEN_LP2 MOVE.B   (A0)+,(A2)+
         SUBQ.W   #1,D0
         BGT      OPEN_LP2
         LEA      FNAMBUF(A6),A0
         RTS

MAKE_PKT MOVEM.L  D1-D5/A1,-(A7)
         BSR      ZNN_TO_H
         MOVE.L   #'_PKT',(A1)+
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER(A6),A0
         LEA      OTBD_DIR(PC),A1
         BSR      OPEN_2
         BEQ      OP_MARK
         CMPI.L   #ERR.NF,D0
         BNE      OP_END
         MOVEQ    #IO.NEW,D3
         LEA      FNAMBUF(A6),A0
         BSR      OPEN_3
         BNE      OP_END
         LEA      BUFFER(A6),A1
         MOVEQ    #$3C,D0
CLR_PKHD CLR.L    (A1)+
         SUBQ.W   #4,D0
         BGT      CLR_PKHD
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         BSR      GETDATE
         LEA      BUFFER(A6),A1
         MOVE.L   MYNET(PC),D4
         MOVE.L   DESTNET(A6),D5
         ROL.W    #8,D4
         ROL.W    #8,D5
         MOVE.W   D4,(A1)
         MOVE.W   D5,2(A1)
         ROL.W    #8,D2
         MOVE.W   D2,4(A1)
         MOVE.B   D0,6(A1)
         MOVE.B   D1,8(A1)
         SWAP     D2
         MOVE.B   D2,10(A1)
         MOVE.B   D3,12(A1)
         SWAP     D3
         MOVE.B   D3,14(A1)
         ADDQ.B   #2,18(A1)
         SWAP     D4
         ROL.W    #8,D4
         SWAP     D5
         ROL.W    #8,D5
         MOVE.W   D4,20(A1)
         MOVE.W   D5,22(A1)
         MOVE.B   #FTSCPROD,24(A1)
         MOVEQ    #$3C,D2
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         MOVE.L   D0,D4
         BEQ.S    OP_BACK
         QDOS     IO.CLOSE
         MOVE.L   D4,D0
         BRA.S    OP_END
OP_MARK  MOVE.L   #999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
OP_BACK  MOVEQ    #-2,D1
         QDOS     FS.POSRE
OP_END   MOVEM.L  (A7)+,D1-D5/A1
         TST.L    D0
         RTS

FBYTE    MOVEQ    #IO.FBYTE&$FF,D0
         BRA.S    DO_IO
FSTRG    MOVEQ    #IO.FSTRG&$FF,D0
         BRA.S    DO_IO
SBYTE    MOVEQ    #IO.SBYTE&$FF,D0
         BRA.S    DO_IO
SSTRG    MOVEQ    #IO.SSTRG&$FF,D0
DO_IO    MOVEQ    #-1,D3
         TRAP     #3
         TST.L    D0
         BEQ.S    IO_END
         PRLOG    {'*** I/O ERROR: '}
         MOVE.L   LOGCHAN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         MOVE.L   ERR_SP(A6),A7
IO_END   RTS

FINDZONE MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         MOVE.L   -(A1),D1
         QDOS     FS.POSAB
FZ_LOOP  MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         CMP.W    -4(A1),D4
         BEQ.S    FZ_MATCH
         MOVEQ    #0,D1
         MOVE.W   -2(A1),D1
         BEQ.S    FNODE_NF
         QDOS     FS.POSRE
         BRA      FZ_LOOP
FZ_MATCH MOVEQ    #6,D2
         BSR      FSTRG
         MOVE.L   -6(A1),D5
         MOVE.W   D4,-4(A1)
         MOVEQ    #0,D0
         RTS

FINDNET  CMP.W    -4(A1),D4
         BEQ.S    FR_MATCH
         MOVE.W   -2(A1),D0
         BEQ.S    FNODE_NF
         ADD.L    D0,D5
         MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BRA      FINDNET
FR_MATCH MOVE.L   D5,D1
         QDOS     FS.POSAB
         MOVEQ    #2,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         MOVE.W   D4,(A1)+
         BSR.S    GETNODE
         CMPI.W   #HOST,(A1)
         SEQ      D5
FNODE_OK MOVEQ    #0,D0
         RTS
FNODE_NF MOVEQ    #ERR.NF,D0
         RTS

FINDNODE TST.W    D4
         BEQ.S    FNODE_OK
FN_LOOP  MOVEQ    #2,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         MOVE.W   -2(A1),D1
         BGT.S    FNODE_CP
         CMPI.W   #HUB,D1
         BGT      FNODE_NF
         BSR      FSTRG
         MOVE.W   -2(A1),D1
FNODE_CP CMP.W    D4,D1
         MOVE.W   SR,-(A7)
         BSR.S    GETNODE
         MOVE.W   (A7)+,CCR
         BNE      FN_LOOP
         RTS

GETNODE  MOVEQ    #1,D2
         BSR      FSTRG
         MOVEQ    #0,D2
         MOVE.B   -1(A1),D2
         BSR      FSTRG
         LEA      NODEBUF(A6),A1
         MOVEQ    #0,D0
         RTS

LOOK_NL  MOVEM.L  D1-D2/D4-D5/A0-A1,-(A7)
         MOVE.L   A7,ERR_SP(A6)
         SUBQ.L   #4,ERR_SP(A6)
         MOVEQ    #IO.SHARE,D3
         LEA      NDLSTFNM,A0
         BSR      OPENSYS
         BNE.S    BAD_NL
         MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         MOVEQ    #ERR.BP,D0
         CMPI.L   #NL_ID,-(A1)
         BNE.S    FN_END
         MOVE.W   DESTZONE(A6),D4
         BSR      FINDZONE
         BNE.S    FN_END
         MOVE.W   DESTNET(A6),D4
         BSR      FINDNET
         BNE.S    FN_END
         MOVE.W   DESTNODE(A6),D4
         BSR      FINDNODE
FN_END   MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
         MOVE.B   D5,D3
BAD_NL   MOVEM.L  (A7)+,D1-D2/D4-D5/A0-A1
         TST.L    D0
         RTS

DISPNODE LEA      BUFFER(A6),A1
         LEA      NODEBUF(A6),A0
         TST.W    (A0)+
         BGT.S    DN_NAME
         ADDQ.W   #2,A0
DN_NAME  ADDQ.W   #1,A0
         CMPI.B   #$80,(A0)
         BEQ.S    DN_NNAME
CVT_CNAM MOVEQ    #$7F,D1
         AND.B    (A0),D1
         MOVE.B   D1,(A1)+
         TST.B    (A0)+
         BPL      CVT_CNAM
DN_NNAME MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVE.L   LOGCHAN(A6),A0
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         RTS

DO_MAIL  JSR      RECV_FTS
         BNE.S    HANG_UP
         TST.L    D1
         BLT.S    HANG_UP
         MOVE.L   D1,DESTNET(A6)
         MOVE.W   MYZONE(PC),DESTZONE(A6)
         MOVE.L   LOGCHAN(A6),A0
         PRINT    {'Received from node '}
         MOVE.W   DESTNET(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         MOVEQ    #'/',D1
         QDOS     IO.SBYTE
         MOVE.W   DESTNODE(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' - '}
         BSR      LOOK_NL
         BNE.S    N_UNKN
         BSR      DISPNODE
         BRA.S    TSTPKUP
N_UNKN   PRINT    {'Unknown node',LF}
TSTPKUP  BSR      OPEN_ATT
         BNE.S    NO_ATTS
         BSR      DIRCLOSE
         BSR      MAKE_PKT
         QDOS     IO.CLOSE
         BRA.S    DO_PKUP
NO_ATTS  BSR      OPEN_PKT
         BNE.S    END_SES
         BSR      FCLOSE
DO_PKUP  JSR      SEND_FTS
         BRA.S    HANG_UP
END_SES  MOVEQ    #0,D0
HANG_UP  TST.L    D0
         BNE.S    REP_ERR
         PRLOG    {'SESSION SUCCESSFULLY COMPLETED',LF}
         BRA.S    HANGUP2
REP_ERR  PRLOG    {'SESSION UNSUCCESSFULLY COMPLETED',LF}
HANGUP2  RTS

         INCLUDE  FLP2_FILEXFER_ASM

         SECTION  MSG

BAUDTBL  DC.W     B300-BAUDTBL
         DC.W     B1275-BAUDTBL
         DC.W     B1200-BAUDTBL
         DC.W     B2400-BAUDTBL
         DC.W     B4800-BAUDTBL
         DC.W     B9600-BAUDTBL
B300     STRING$  '300'
B1275    STRING$  '1200/75'
B1200    STRING$  '1200'
B2400    STRING$  '2400'
B4800    STRING$  '4800'
B9600    STRING$  '9600'

         DS.W     0

STORAGE  DS.B     DATASPC

         DC.W     0

OLDQSPIL EQU      *

         END
