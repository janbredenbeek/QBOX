* KILLMSG
* October 2, 1989
* Last revision: February 9, 1991 (support for QBOX 1.19 LASTREAD_BBS file)

version  SETSTR   1.19

         INCLUDE  FLP1_QDOS_IN_MAC

CR       EQU      $0D
LF       EQU      $0A

SV_DATAD EQU      $B0
SV_PROGD EQU      $AC

MAXAREA  EQU      256

MS_DATE  EQU      0
MS_OZONE EQU      4
MS_ONET  EQU      6
MS_ONODE EQU      8
MS_OPNT  EQU      10
MS_DZONE EQU      12
MS_DNET  EQU      14
MS_DNODE EQU      16
MS_DPNT  EQU      18
MS_ATTR  EQU      20
MS_COST  EQU      22
MS_REPTO EQU      24
MS_NXREP EQU      25
MS_NREAD EQU      26
MS_SPARE EQU      28
MS_TOUSR EQU      32

         OFFSET   0

SYSDIR   DS.L     1
MSGCHAN  DS.L     1
AREANUM  DS.W     1
RENUMTBL DS.B     256
FNAMBUF  DS.B     50
HDRBUF   DS.B     14
BUFFER   DS.B     512

         DATA     1024

         SECTION  CODE

         BRA.S    START
         DC.L     0
         DC.W     $4AFB
         STRING$  'KILLMSG'
         DC.B     ' v[version]'
MAREAS   STRING$  'MAREAS_BBS'
MESSAGES STRING$  'MESSAGES_BBS'
LASTREAD STRING$  'LASTREAD_BBS'

START    ADDA.L   A4,A6
         MOVEQ    #ERR.BP,D0
         MOVE.L   A7,A4
         TST.W    (A4)+
         BNE.S    KILL_JOB
         MOVEQ    #0,D7
         MOVE.W   (A4)+,D7
         BEQ.S    KILL_JOB
         ADD.L    A4,D7
         BSR      PROCESS
KILL_JOB MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

LD_WORD  MOVE.B   (A1)+,D1
         LSL.W    #8,D1
         MOVE.B   (A1)+,D1
         TST.W    D1
         RTS

LD_LONG  MOVEQ    #3,D0
LDL_LP   ROL.L    #8,D1
         MOVE.B   (A1)+,D1
         DBF      D0,LDL_LP
         TST.L    D1
         RTS

SKIPSPC  CMP.L    A4,D7
         BLS.S    SKP_END
         CMPI.B   #' ',(A4)
         BNE.S    SKP_END
         ADDQ.W   #1,A4
         BRA      SKIPSPC
SKP_END  RTS

READNUM  CMP.L    A4,D7
         BLS.S    SYNTXERR
         CMPI.B   #'0',(A4)
         BLO.S    SYNTXERR
         CMPI.B   #'9',(A4)
         BHI.S    SYNTXERR
         MOVEQ    #0,D0
         MOVEQ    #0,D1
RN_LOOP  CMP.L    A4,D7
         BLS.S    RN_END
         MOVE.B   (A4),D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    RN_END
         ADDQ.W   #1,A4
         MULU     #10,D1
         ADD.W    D0,D1
         BRA      RN_LOOP
RN_END   RTS

SYNTXERR SUBA.L   A0,A0
         PRINT    {'KILLMSG: Syntax error in command line',LF}
         MOVEQ    #ERR.XP,D0
         BRA      KILL_JOB

FOPEN    MOVEM.L  D3/A0-A1,-(A7)
         LEA      FNAMBUF(A6),A2
         MOVE.W   (A1)+,D0
         ADD.W    (A0),D0
         MOVE.W   D0,(A2)+
         SUB.W    (A0),D0
         BRA.S    FOPEN_3
FOPEN_2  MOVE.B   (A1)+,(A2)+
FOPEN_3  DBF      D0,FOPEN_2
         MOVE.W   (A0)+,D0
         BRA.S    FOPEN_5
FOPEN_4  MOVE.B   (A0)+,(A2)+
FOPEN_5  DBF      D0,FOPEN_4
FOPEN_6  MOVEQ    #-1,D1
         MOVE.L   (A7),D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    FOP_OK
         CMPI.L   #ERR.IU,D0
         BNE.S    FOP_END
         MOVEQ    #-1,D1
         MOVEQ    #50,D3
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         BRA      FOPEN_6
FOP_OK   MOVE.L   A0,4(A7)
FOP_END  MOVEM.L  (A7)+,D3/A0-A1
         TST.L    D0
         RTS

DO_IO    MOVEQ    #-1,D3
         TRAP     #3
         TST.L    D0
         BNE.S    IO_ERROR
         RTS
FOP_ERR  MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'KILLMSG: Failed to open file '}
         BRA.S    PRFNAM
IO_ERROR MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'KILLMSG: I/O Error file '}
PRFNAM   LEA      FNAMBUF(A6),A1
         JSR      (A2)
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,D0
         BRA      KILL_JOB

BAD_ENV  SUBA.L   A0,A0
         PRINT    {'KILLMSG: Cannot find QBOX system directory',LF}
         MOVEQ    #ERR.NF,D0
         RTS
BAD_AREA SUBA.L   A0,A0
         PRINT    {'KILLMSG: Invalid message area',LF}
         MOVEQ    #ERR.BP,D0
         RTS

PROCESS  QDOS     MT.INF
         MOVE.L   A0,A5
         MOVE.L   SV_DATAD(A5),D0
         BEQ.S    BAD_ENV
         MOVE.L   D0,A1
         LEA      MAREAS,A0
         MOVEQ    #IO.SHARE,D3
         BSR      FOPEN
         BEQ.S    SET_DIR
         MOVE.L   SV_PROGD(A5),D0
         BEQ.S    BAD_ENV
         MOVE.L   D0,A1
         BSR      FOPEN
         BNE      BAD_ENV
SET_DIR  MOVE.L   A1,SYSDIR(A6)
         BSR      READNUM
         MOVE.W   D1,AREANUM(A6)
         BEQ      BAD_AREA
         MOVE.W   D1,D4
         MOVE.W   #256,D2
         MOVEQ    #-1,D3
FINDAREA LEA      BUFFER+2(A6),A1
         QDOS     IO.FLINE
         CMPI.L   #ERR.EF,D0
         BEQ      BAD_AREA
         TST.L    D0
         BNE      IO_ERROR
         SUBQ.W   #1,D4
         BNE      FINDAREA
         SUBQ.W   #1,D1
         BLE      BAD_AREA
         QDOS     IO.CLOSE
         LEA      BUFFER+2(A6),A1
LOOKSPC  CMPI.B   #' ',(A1)
         BEQ.S    GOT_DIR
         CMPI.B   #LF,(A1)
         BEQ.S    GOT_DIR
         ADDQ.W   #1,A1
         BRA      LOOKSPC
GOT_DIR  MOVE.L   A1,D0
         LEA      BUFFER+2(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
         LEA      MESSAGES,A0
         MOVEQ    #IO.EXCL,D3
         BSR      FOPEN
         BNE      FOP_ERR
         MOVE.L   A0,MSGCHAN(A6)
         MOVEQ    #FS.HEADR&$FF,D0
         MOVEQ    #14,D2
         LEA      HDRBUF(A6),A1
         BSR      DO_IO
         MOVE.L   HDRBUF(A6),D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    MEM_OK
         SUBA.L   A0,A0
         PRINT    {'KILLMSG: Message file too big for memory',LF}
         MOVEQ    #ERR.OM,D0
         RTS
MEM_OK   MOVE.L   A0,A5
         MOVEQ    #FS.LOAD&$FF,D0
         MOVE.L   HDRBUF(A6),D2
         MOVE.L   MSGCHAN(A6),A0
         MOVE.L   A5,A1
         BSR      DO_IO
         MOVEQ    #0,D6
         MOVE.B   (A5),D6
KM_MAIN  BSR      SKIPSPC
         BEQ.S    KM_RENUM
         BSR      READNUM
         MOVE.W   D1,D4
         MOVE.W   D1,D5
         CMP.L    A4,D7
         BLS.S    DO_KILL
         CMPI.B   #'-',(A4)
         BNE.S    DO_KILL
         ADDQ.W   #1,A4
         CMP.L    A4,D7
         BLS.S    KM_LAST
         BSR      READNUM
         MOVE.W   D1,D5
DO_KILL  CMP.W    D6,D5
         BLS.S    KM_CKLOW
KM_LAST  MOVE.W   D6,D5
KM_CKLOW TST.W    D4
         BNE.S    KM_CHECK
         MOVEQ    #1,D4
KM_CHECK CMP.W    D4,D5
         BLO      KM_MAIN
         CMP.W    D6,D4
         BHI      KM_MAIN
KM_KILL  BSR      KILLMSG
         ADDQ.W   #1,D4
         CMP.W    D5,D4
         BLS      KM_KILL
         BRA      KM_MAIN
KM_RENUM MOVEQ    #0,D4
         LEA      1(A5),A0
         LEA      RENUMTBL+256(A6),A1
         MOVEQ    #256/4-1,D0
CLRTBL   CLR.L    -(A1)
         DBF      D0,CLRTBL
         MOVEQ    #0,D0
REN_LOOP MOVE.B   D4,(A1,D0.W)
         ADDQ.W   #1,D0
         CMP.W    D6,D0
         BHI.S    KM_RESTR
         TST.B    (A0)
         ADDQ.W   #4,A0
         BMI      REN_LOOP
         ADDQ.W   #1,D4
         BRA      REN_LOOP
KM_RESTR MOVE.W   HDRBUF+8(A6),D0
         MOVE.B   (A1,D0.W),HDRBUF+9(A6)
         MOVEQ    #FS.HEADS&$FF,D0
         MOVE.L   MSGCHAN(A6),A0
         LEA      HDRBUF(A6),A1
         BSR      DO_IO
         MOVEQ    #FS.POSAB&$FF,D0
         MOVEQ    #0,D1
         BSR      DO_IO
         MOVEQ    #FS.TRUNC&$FF,D0
         BSR      DO_IO
         MOVEQ    #IO.SBYTE&$FF,D0
         MOVE.B   D4,D1
         BSR      DO_IO
         MOVE.W   #255*4-1,D2
CLR_IDX  MOVEQ    #IO.SBYTE&$FF,D0
         MOVEQ    #-1,D1
         BSR      DO_IO
         DBF      D2,CLR_IDX
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         MOVE.L   D1,D5
         MOVEQ    #1,D4
         LEA      1(A5),A1
         LEA      RENUMTBL(A6),A3
REST_MSG SUBQ.W   #1,D6
         BLO.S    KM_USERS
         BSR      LD_LONG
         BMI      REST_MSG
         MOVE.L   A1,-(A7)
         BSR      SEND_MSG
         MOVE.L   (A7)+,A1
         BRA      REST_MSG
KM_USERS QDOS     IO.CLOSE
         MOVEQ    #IO.EXCL,D3
         LEA      LASTREAD,A0
         MOVE.L   SYSDIR(A6),A1
         BSR      FOPEN
         BNE      FOP_ERR
         MOVE.W   #MAXAREA*2,D2
         MOVEQ    #-1,D3
         MOVE.W   AREANUM(A6),D0
         SUBQ.W   #1,D0
         ADD.W    D0,D0
         LEA      BUFFER+1(A6),A2
         ADDA.W   D0,A2
         LEA      RENUMTBL(A6),A3
USERS_LP LEA      BUFFER(A6),A1
         QDOS     IO.FSTRG
         CMPI.L   #ERR.EF,D0
         BEQ.S    USERS_EN
         TST.L    D0
         BNE      IO_ERROR
         MOVE.B   (A2),D0
         MOVE.B   (A3,D0.W),(A2)
         MOVEQ    #FS.POSRE&$FF,D0
         MOVE.L   #-MAXAREA*2,D1
         BSR      DO_IO
         MOVEQ    #IO.SSTRG&$FF,D0
         LEA      BUFFER(A6),A1
         BSR      DO_IO
         BRA      USERS_LP
USERS_EN QDOS     IO.CLOSE
         MOVE.L   A5,A0
         QDOS     MT.RECHP
         MOVEQ    #0,D0
         RTS

GETPTR   ANDI.W   #$FF,D1
         LSL.W    #2,D1
         LEA      -3(A5,D1.W),A1
         BSR      LD_LONG
         RTS

KILLMSG  MOVE.W   D4,D1
         BSR      GETPTR
         BLT.S    KM_END
         LEA      (A5,D1.L),A0
         ST       -4(A1)
         MOVE.B   MS_REPTO(A0),D1
         BEQ.S    KM_NXREP
         BSR      GETPTR
         BLT.S    KM_NXREP
         MOVE.B   MS_NXREP(A0),MS_NXREP(A5,D1.L)
KM_NXREP MOVE.B   MS_NXREP(A0),D1
         BEQ.S    KM_END
         BSR      GETPTR
         BLT.S    KM_END
         MOVE.B   MS_REPTO(A0),MS_REPTO(A5,D1.L)
KM_END   RTS

SEND_MSG LEA      (A5,D1.L),A2
         MOVEQ    #0,D0
         MOVE.B   MS_REPTO(A2),D0
         MOVE.B   (A3,D0.W),MS_REPTO(A2)
         MOVE.B   MS_NXREP(A2),D0
         MOVE.B   (A3,D0.W),MS_NXREP(A2)
         LEA      MS_TOUSR(A2),A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         BSR      LD_WORD
         ADDA.W   D1,A1
         MOVE.L   A1,D2
         SUB.L    A2,D2
         MOVE.L   D5,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVEQ    #IO.SSTRG&$FF,D0
         MOVE.L   A2,A1
         BSR      DO_IO
         MOVE.L   D5,-(A7)
         ADD.L    D2,D5
         MOVE.L   D4,D1
         ADDQ.L   #4,D4
         MOVEQ    #FS.POSAB&$FF,D0
         BSR      DO_IO
         MOVEQ    #IO.SSTRG&$FF,D0
         MOVEQ    #4,D2
         MOVE.L   A7,A1
         BSR      DO_IO
         ADDQ.W   #4,A7
         RTS

         SECTION  MSG

         DC.W     0

         END
