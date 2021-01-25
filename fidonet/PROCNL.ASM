* This program reads the standard IFNA-format nodelist.
* Each entry in the nodelist file has the following form:
*
* - word: 0 end of list, >0 node number, <0 special ident:
* Special idents are followed by the following information:
*   -1 (start zone): offset to first net/region start(W) + offset to next zone
*      start(L) + zone number
*   -2 (start region): offset to next region start(W) + region number
*   -3 (host): offset to next net start(W) + net number
*   -4 (hub): node number
*   -5 (pvt): node number
*   -6 (hold): node number
*   -7 (down): node number
*
* - node data:
*   byte: length of following fields
*   <node name> or <node name>, <location>; last char has bit 7 set
*   phone number; last char has bit 7 set

         INCLUDE  FLP1_QDOS_IN_MAC

* DEFINITIONS

NL_ID    EQU      'NL01'            Nodelist ID & version

ZONE     EQU      -1
REGION   EQU      -2
HOST     EQU      -3
HUB      EQU      -4
PVT      EQU      -5
HOLD     EQU      -6
DOWN     EQU      -7

CR       EQU      $0D
LF       EQU      $0A

         OFFSET   0

CONCHAN  DS.L     1
INPCHAN  DS.L     1
ERR_SP   DS.L     1
INPUT    DS.B     16
BUFFER   DS.B     128
OUTBUF   DS.B     128

         DATA     1024

         SECTION  CODE

         BRA.S    JOBSTART          Skip job header
         DC.L     0                 Starts at 6 so pad 4 bytes...
         DC.W     $4AFB             Ident flag
JOBNAME  STRING$  {'PROCNL'}        Name of program
         DS.W     0
WIN_DEF  DC.B     4,1,0,7
         DC.W     448,200,32,16
CURRZONE DC.W     2
CURRNET  DC.W     283

JOBSTART ADDA.L   A4,A6
         MOVE.W   (A7)+,D1
         SUBQ.W   #1,D1
         BNE.S    BADCMD
         MOVE.L   (A7)+,INPCHAN(A6)
         LEA      WIN_DEF,A1
         MOVE.W   UT_CON,A2
         JSR      (A2)
         MOVE.L   A0,CONCHAN(A6)
         BSR      PROCESS
         MOVEQ    #0,D3
         BRA.S    KILL_JOB
BADCMD   SUBA.L   A0,A0
         PRINT    {'Use EW PROCNL,<nodelist>',LF}
         MOVEQ    #ERR.BP,D3
KILL_JOB MOVEQ    #-1,D1
         QDOS     MT.FRJOB

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

ITOD_W   MOVEM.L  D1-D2,-(A7)
         CMPI.W   #9,D1
         BHI.S    DO_DIV
FILLSPC  SUBQ.W   #1,D2
         BLE.S    STO_DGT
         MOVE.B   #' ',(A1)+
         BRA      FILLSPC
DO_DIV   ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         SUBQ.W   #1,D2
         BSR      ITOD_W
         SWAP     D1
STO_DGT  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D1-D2
         RTS

FBYTE    MOVEQ    #IO.FBYTE&$FF,D0
         BRA.S    DO_IO
FSTRG    MOVEQ    #IO.FSTRG&$FF,D0
DO_IO    MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         TRAP     #3
         TST.L    D0
         BEQ.S    IO_END
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'*** Input I/O Error',LF}
         MOVE.L   ERR_SP(A6),A7
IO_END   RTS

FINDZONE MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         MOVEQ    #4,D1
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         MOVE.L   -(A1),D1
         QDOS     FS.POSAB
FZ_LOOP  MOVEQ    #4,D2
         LEA      BUFFER(A6),A1
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
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         BRA      FINDNET
FR_MATCH MOVE.L   D5,D1
         QDOS     FS.POSAB
         MOVEQ    #2,D2
         LEA      BUFFER(A6),A1
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
         LEA      BUFFER(A6),A1
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
         LEA      BUFFER(A6),A1
         MOVEQ    #0,D0
         RTS

LOOK_NL  MOVEM.L  D1-D2/D4-D5,-(A7)
         MOVE.W   D2,D4
         BSR      FINDZONE
         BNE.S    FN_END
         MOVE.W   (A7),D4
         BSR      FINDNET
         BNE.S    FN_END
         MOVE.W   2(A7),D4
         BSR      FINDNODE
FN_END   MOVE.B   D5,D3
         MOVEM.L  (A7)+,D1-D2/D4-D5
         TST.L    D0
         RTS

DISPNODE MOVEM.L  D1-D3/A0-A2,-(A7)
         LEA      BUFFER(A6),A0
         LEA      OUTBUF(A6),A1
         TST.W    (A0)
         BGT.S    CVT_NR
         MOVE.W   (A0)+,D1
         CMPI.W   #HOST,D1
         BLT.S    CVT_NR
         MOVE.W   D1,D0
         NEG.W    D0
         ADD.W    D0,D0
         LEA      CVT_TBL,A2
         ADDA.W   -2(A2,D0.W),A2
         MOVE.W   (A2)+,D0
CVT_COPY MOVE.B   (A2)+,(A1)+
         SUBQ.W   #1,D0
         BGT      CVT_COPY
CVT_NR   MOVE.W   (A0)+,D1
         MOVEQ    #4,D2
         BSR      ITOD_W
         MOVE.B   #' ',(A1)+
         MOVE.B   #' ',(A1)+
         ADDQ.W   #1,A0
         CMPI.B   #$80,(A0)
         BEQ.S    CVT_PRN
CVT_CNAM MOVEQ    #$7F,D1
         AND.B    (A0),D1
         MOVE.B   D1,(A1)+
         TST.B    (A0)+
         BPL      CVT_CNAM
CVT_PRN  MOVE.L   A1,D2
         LEA      OUTBUF(A6),A1
         SUB.L    A1,D2
         MOVE.L   CONCHAN(A6),A0
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVEM.L  (A7)+,D1-D3/A0-A2
         RTS

PROCESS  MOVE.L   A7,ERR_SP(A6)
         MOVE.W   CURRZONE,D7
         MOVE.W   CURRNET,D6
PROC_ASK MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Current net/region is '}
         MOVE.W   D7,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         MOVEQ    #':',D1
         QDOS     IO.SBYTE
         MOVE.W   D6,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' - '}
         MOVE.W   D6,D1
         SWAP     D1
         CLR.W    D1
         MOVE.W   D7,D2
         BSR      LOOK_NL
         BNE.S    ASK2
         BSR      DISPNODE
ASK2     MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Enter node number, net/node number or zone:net/node number',LF}
         PRINT    {'Enter Z<zone number> or N<net number> to change current zone or net',LF}
         PRINT    {'Enter Z to list zones, N to list nets/regions or L to list nodes',LF}
         MOVEQ    #16,D2
         MOVEQ    #-1,D3
         LEA      INPUT(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE      ASK2
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BEQ.S    ASK_RTS
         BSR.S    PROC_SUB
         BRA      PROC_ASK
ASK_RTS  RTS

PROC_SUB MOVEQ    #$DF-256,D1
         AND.B    (A1),D1
         CMPI.B   #'L',D1
         BEQ      LST_NODE
         CMPI.B   #'N',D1
         BEQ      LST_NET
         CMPI.B   #'Z',D1
         BEQ      LST_ZONE
         MOVE.W   D7,D2
         MOVE.W   D6,D3
READZNN  BSR      READNUM
         BNE.S    BAD_NUM
         MOVE.B   (A1)+,D0
         CMPI.B   #LF,D0
         BEQ.S    RZ_END
         CMPI.B   #':',D0
         BNE.S    RZ_NET
         MOVE.W   D1,D2
         BRA      READZNN
RZ_NET   CMPI.B   #'/',D0
         BNE.S    BAD_NUM
         MOVE.W   D1,D3
         BRA      READZNN
RZ_END   SWAP     D1
         MOVE.W   D3,D1
         SWAP     D1
         BSR      LOOK_NL
         MOVE.L   CONCHAN(A6),A0
         BNE.S    RZ_NOTFD
         MOVE.W   D2,D7
         MOVE.W   D1,D0
         SWAP     D1
         MOVE.W   D1,D6
         TST.W    D0
         BEQ.S    RZ_DISP
         MOVE.W   D1,-(A7)
         MOVE.W   D2,D1
         MOVE.W   UT_MINT,A4
         JSR      (A4)
         MOVEQ    #':',D1
         QDOS     IO.SBYTE
         MOVE.W   (A7)+,D1
         MOVE.W   UT_MINT,A4
         JSR      (A4)
         MOVEQ    #'/',D1
         QDOS     IO.SBYTE
RZ_DISP  BRA      DISPNODE
BAD_NUM  MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Bad node address!',LF}
         RTS
RZ_NOTFD MOVE.L   D1,-(A7)
         MOVE.W   D2,-(A7)
         PRINT    {LF,'WARNING: Node '}
         MOVE.W   (A7)+,D1
         MOVE.W   UT_MINT,A4
         JSR      (A4)
         MOVEQ    #':',D1
         QDOS     IO.SBYTE
         MOVE.W   (A7)+,D1
         JSR      (A4)
         MOVEQ    #'/',D1
         QDOS     IO.SBYTE
         MOVE.W   (A7)+,D1
         JSR      (A4)
         PRINT    {' does not exist!',LF}
         RTS
LST_ZONE ADDQ.W   #1,A1
         BSR      READNUM
         BNE.S    GO_LZ
         MOVE.W   D1,D4
         BSR      FINDZONE
         BNE.S    LZ_NOTFD
         MOVE.W   D4,D6
         MOVE.W   D4,D7
         RTS
LZ_NOTFD MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Invalid zone number!',LF}
         RTS
GO_LZ    PRINT    {LF,'List of Zones',LF,LF}
         MOVEQ    #4,D1
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         MOVE.L   -(A1),D5
LZ_LOOP  MOVE.L   D5,D1
         QDOS     FS.POSAB
         MOVEQ    #10,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         MOVEQ    #-6,D1
         QDOS     FS.POSRE
         MOVE.L   D1,D5
         LEA      BUFFER(A6),A1
         MOVEQ    #0,D4
         MOVE.W   2(A1),D4
         MOVE.W   (A1),D1
         MOVE.W   #ZONE,(A1)+
         MOVE.W   D1,(A1)+
         MOVEQ    #2,D1
         ADD.L    (A1),D1
         QDOS     FS.POSAB
         BSR      GETNODE
         BSR      DISPNODE
         ADD.L    D4,D5
         TST.L    D4
         BNE      LZ_LOOP
         RTS

LST_NET  LEA      1(A1),A2
         MOVE.W   D7,D4
         BSR      FINDZONE
         BNE      LZ_NOTFD
         EXG      A1,A2
         BSR      READNUM
         EXG      A1,A2
         BNE.S    LR_LIST
         MOVE.W   D1,D4
         BSR      FINDNET
         BNE.S    LR_NOTFD
         MOVE.W   D4,D6
         RTS
LR_NOTFD MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Invalid net or region number!',LF}
         RTS
LR_LIST  MOVE.L   A1,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'List of nets and regions in zone '}
         MOVE.W   D7,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {LF,LF}
         MOVEQ    #0,D1
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         QDOS     FS.POSRE
         MOVE.L   (A7),A1
         MOVE.L   D1,(A7)
         BRA.S    LR_DISP
LR_LOOP  MOVE.L   (A7),D1
         ADDQ.L   #4,(A7)
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
LR_DISP  MOVE.L   -4(A1),D4
         SWAP     D4
         MOVE.L   D5,D1
         QDOS     FS.POSAB
         MOVEQ    #2,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         MOVE.W   D4,(A1)+
         BSR      GETNODE
         BSR      DISPNODE
         CLR.W    D4
         SWAP     D4
         ADD.L    D4,D5
         TST.L    D4
         BNE      LR_LOOP
         ADDQ.W   #4,A7
         RTS

LST_NODE MOVE.W   D7,D4
         BSR      FINDZONE
         BNE      LZ_NOTFD
         MOVE.W   D6,D4
         BSR      FINDNET
         BNE      LR_NOTFD
         MOVE.L   A1,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'List of nodes in net/region '}
         MOVE.W   D7,D1
         MOVE.W   UT_MINT,A4
         JSR      (A4)
         MOVEQ    #':',D1
         QDOS     IO.SBYTE
         MOVE.W   D6,D1
         JSR      (A4)
         PRINT    {LF,LF}
         MOVE.L   (A7)+,A1
         BRA.S    LN_DISP
LN_LOOP  BSR      GETNODE
LN_DISP  BSR      DISPNODE
         MOVEQ    #2,D2
         LEA      BUFFER(A6),A1
         BSR      FSTRG
         MOVE.W   -2(A1),D1
         BGT.S    LN_LOOP
         CMPI.W   #HUB,D1
         BGT.S    LN_END
         BSR      FSTRG
         BRA      LN_LOOP
LN_END   RTS

         SECTION  MSG
CVT_TBL  DC.W     CVT_ZONE-CVT_TBL
         DC.W     CVT_REG-CVT_TBL
         DC.W     CVT_NET-CVT_TBL
CVT_ZONE STRING$  {'ZONE'}
CVT_REG  STRING$  {'REGION'}
CVT_NET  STRING$  {'NET   '}

         DC.W     0
         END
