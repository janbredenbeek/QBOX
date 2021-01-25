* EDITNL - Nodediff processor
* July 21, 1989

         INCLUDE  FLP1_QDOS_IN_MAC

version  SETSTR   1.00

CR       EQU      $0D
LF       EQU      $0A
INPBUFSZ EQU      256
CMDBUFSZ EQU      256

         OFFSET   0

INPCHAN  DS.L     1
CMDCHAN  DS.L     1
OUTCHAN  DS.L     1
ERR_SP   DS.L     1
INPBUF   DS.B     INPBUFSZ
CMDBUF   DS.B     CMDBUFSZ
FIRSTBUF DS.B     CMDBUFSZ+2

         DATA     1024

         SECTION  CODE

         BRA.S    START
         DC.L     0
         DC.W     $4AFB
         STRING$  {'EDITNL v[version]'}
         DC.W     $4AFB

* Parameter decode routine (see TK2 manual)

         MOVE.L   A0,A2
         CMPI.W   #3,D7
         BNE.S    ERR_BP
         MOVE.L   A5,A3
         TST.L    D5
         BNE.S    OP_CMD
         MOVEQ    #IO.OVER,D7
         BSR.S    OPENCHAN
OP_CMD   MOVEQ    #IO.SHARE,D7
         BSR.S    OPENCHAN
         TST.L    D4
         BNE.S    OP_END
         BSR.S    OPENCHAN
OP_END   RTS
ERR_BP   MOVEQ    #ERR.BP,D0
         RTS
OPENCHAN SUBQ.W   #8,A3
         JSR      (A2)
         BLT.S    OP_ERROR
         BGT.S    OP_OK
         MOVE.B   D7,D3
         JSR      2(A2)
         BNE.S    OP_ERROR
OP_OK    ADDQ.L   #1,D5
         MOVE.L   A0,-(A4)
         RTS
OP_ERROR ADDQ.W   #4,A7
         RTS

START    ADDA.L   A4,A6
         MOVEQ    #ERR.BP,D0
         CMPI.W   #3,(A7)+
         BNE.S    KILL_JOB
         MOVE.L   (A7)+,INPCHAN(A6)
         MOVE.L   (A7)+,CMDCHAN(A6)
         MOVE.L   (A7)+,OUTCHAN(A6)
         BSR      PROCESS
KILL_JOB MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

READNUM  CMPI.B   #'0',(A1)
         BLO.S    RN_ERR
         CMPI.B   #'9',(A1)
         BHI.S    RN_ERR
         MOVEQ    #0,D0
         MOVEQ    #0,D4
RN_LOOP  MOVE.B   (A1)+,D0
         CMPI.B   #CR,D0
         BEQ.S    RN_OK
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    RN_ERR
         MULU     #10,D4
         ADD.W    D0,D4
         BRA      RN_LOOP
RN_OK    MOVEQ    #0,D0
         RTS
RN_ERR   SUBA.L   A0,A0
         PRINT    {'EDITNL: Bad Nodediff command at line #'}
         MOVE.W   D5,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVEQ    #ERR.BL,D0
         MOVE.L   ERR_SP(A6),A7
         RTS

GETCMD   LEA      CMDBUF(A6),A1
GETCMD2  MOVE.W   #CMDBUFSZ,D2
         MOVEQ    #-1,D3
         MOVE.L   CMDCHAN(A6),A0
         QDOS     IO.FLINE
         TST.L    D0
         BEQ.S    GC_OK
         CMPI.L   #ERR.EF,D0
         BEQ.S    GC_RTS
         MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'EDITNL: Nodediff I/O error',LF}
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
         RTS
GC_OK    ADDQ.W   #1,D5
         SUBA.W   D1,A1
GC_RTS   TST.L    D0
         RTS

GETNL    MOVE.W   #INPBUFSZ,D2
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         LEA      INPBUF(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    GNL_ERR
         SUBA.W   D1,A1
         TST.B    D7
         BNE.S    GNL_RTS
         ST       D7
         LEA      FIRSTBUF(A6),A2
         CMP.W    (A2)+,D1
         BNE.S    MISMATCH
         MOVE.W   D1,D0
         SUBQ.W   #1,D0
CHKFIRST CMPM.B   (A1)+,(A2)+
         DBNE     D0,CHKFIRST
         SUBA.W   D1,A1
         BEQ.S    GNL_RTS
MISMATCH LEA      MISMMSG,A1
         MOVEQ    #ERR.BP,D0
         BRA.S    GNL_ERR1
GNL_ERR  LEA      NLERRMSG,A1
GNL_ERR1 MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
GNL_RTS  RTS

         SECTION  MSG
NLERRMSG STRING$  {'EDITNL: Nodelist I/O error',LF}
MISMMSG  STRING$  {'EDITNL: Mismatched Nodediff file',LF}
         SECTION  CODE

DO_OUT   MOVE.W   D1,D2
         MOVEQ    #-1,D3
         MOVE.L   OUTCHAN(A6),A0
         QDOS     IO.SSTRG
         TST.L    D0
         BEQ.S    OUT_OK
         MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'EDITNL: Output I/O error',LF}
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
OUT_OK   RTS

PROCESS  MOVE.L   A7,ERR_SP(A6)
         MOVEQ    #0,D5
         MOVEQ    #0,D7
         LEA      FIRSTBUF+2(A6),A1
         BSR      GETCMD2
         MOVE.W   D1,-(A1)
PROCLOOP BSR      GETCMD
         BNE.S    PROC_END
         MOVE.B   (A1)+,D1
         SUBI.B   #'A',D1
         BEQ.S    CMD_ADD
         SUBQ.B   #'C'-'A',D1
         BEQ.S    CMD_COPY
         SUBQ.B   #'D'-'C',D1
         BNE      RN_ERR
CMD_DEL  BSR      READNUM
DEL_LOOP BSR      GETNL
         SUBQ.W   #1,D4
         BHI      DEL_LOOP
         BRA      PROCLOOP
CMD_ADD  BSR      READNUM
ADD_LOOP BSR      GETCMD
         BSR      DO_OUT
         SUBQ.W   #1,D4
         BHI      ADD_LOOP
         BRA      PROCLOOP
CMD_COPY BSR      READNUM
CPY_LOOP BSR      GETNL
         BSR      DO_OUT
         SUBQ.W   #1,D4
         BHI      CPY_LOOP
         BRA      PROCLOOP
PROC_END MOVE.L   OUTCHAN(A6),A0
         MOVEQ    #$1A,D1
         QDOS     IO.SBYTE
         RTS

         SECTION  MSG
         DC.W     0

         END
