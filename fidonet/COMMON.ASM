* QBoxMail routines common to SCANMAIL and TOSSMAIL

         INCLUDE  FLP2_QDOS_IN_MAC
         INCLUDE  FLP2_QBOXMAIL_H

         MODULE   READASCII

         SECTION  CODE

* Read 4-d address
* Entry: D2-D4 current zone:net/node, (A1) ASCII string
* Exit:  D2-D5 updated zone:net/node.point, (A1) updated
* Special values: -1 for "?"

         XDEF     A2ZNNP

A2ZNNP   BSR      SKIPSPC
         CMPI.B   #'.',(A1)
         BEQ.S    R4D_PNT
         MOVEQ    #0,D5
         BSR.S    R4D_NUM
         BNE.S    R4D_ERR
         CMPI.B   #'/',(A1)
         BEQ.S    R4D_NET
         CMPI.B   #':',(A1)
         BNE.S    R4D_NODE
         ADDQ.W   #1,A1
         MOVE.W   D1,D2
         BSR.S    R4D_NUM
         BNE.S    R4D_ERR
R4D_NET  MOVE.W   D1,D3
         CMPI.B   #'/',(A1)
         BNE.S    R4D_END
         ADDQ.W   #1,A1
         BSR.S    R4D_NUM
         BNE.S    R4D_ERR
R4D_NODE MOVE.W   D1,D4
         CMPI.B   #'.',(A1)
         BNE.S    R4D_END
R4D_PNT  ADDQ.W   #1,A1
         BSR.S    R4D_NUM
         BNE.S    R4D_ERR
         MOVE.W   D1,D5
R4D_END  MOVEQ    #0,D0
         RTS
R4D_ERR  MOVEQ    #ERR.XP,D0
         RTS

R4D_NUM  CMPI.B   #'?',(A1)
         BNE.S    READNUM
         ADDQ.W   #1,A1
         MOVEQ    #-1,D1
         MOVEQ    #0,D0
         RTS

* Read decimal number
* Entry: (A1) ptr to number
* Exit : D0 error code, D1.W result

         XDEF     READNUM

READNUM  CMPI.B   #'0',(A1)
         BLT.S    RN_ERR
         CMPI.B   #'9',(A1)
         BGT.S    RN_ERR
         MOVEQ    #0,D0
         MOVEQ    #0,D1
RN_LOOP  MOVE.B   (A1),D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    RN_END
         MULU     #10,D1
         ADD.W    D0,D1
         ADDQ.W   #1,A1
         BRA      RN_LOOP
RN_END   MOVEQ    #0,D0
         RTS
RN_ERR   MOVEQ    #ERR.XP,D0
         RTS

* Read nodes from ASCII nodelist
* Entry: D3 max. nr of entries, D4 net nr, A1 ptr to ASCII nodelist, A4 ptr to buffer
* Exit:  D2 number of entries found, D4 updated net nr, A1 and A4 updated

         XDEF     READNODE,RDNODE_2

READNODE MOVEQ    #4,D5
RDNODE_2 MOVEQ    #0,D2
RL_NEXT  BSR      SKIPSPC
         BEQ.S    RL_END
         BSR      READNUM
         BNE.S    RL_END
         CMPI.B   #' ',(A1)
         BEQ.S    RL_NODE
         CMPI.B   #CR,(A1)
         BEQ.S    RL_NODE
         CMPI.B   #LF,(A1)
         BEQ.S    RL_NODE
         CMPI.B   #'/',(A1)+
         BNE.S    RL_ERR
         MOVE.W   D1,D4
         BSR      READNUM
         BNE.S    RL_END
RL_NODE  CMP.W    D3,D2
         BGE.S    RL_2MANY
         ADDQ.W   #1,D2
         MOVE.W   D4,(A4)
         MOVE.W   D1,2(A4)
         ADDA.W   D5,A4
         BRA      RL_NEXT
RL_ERR   MOVEQ    #ERR.XP,D0
         BRA.S    RL_END
RL_2MANY MOVEQ    #1,D0
RL_END   RTS

         MODULE   WRITEASCII

         SECTION  CODE

* DIVIDE D1.L BY D2.W
* QUOTIENT IN D1.L, REMAINDER IN D0.W

         XDEF     DIVLONG

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

* TIME CONVERSION ROUTINE
* ENTRY: D1 = QDOS DATE
* EXIT: D2L = DAYS, D2H = HOURS, D3L = MINS, D3H = SECS

         XDEF     GETTIME

GETTIME  MOVEQ    #60,D2
         BSR      DIVLONG
         MOVE.W   D0,D3
         SWAP     D3
         BSR      DIVLONG
         MOVE.W   D0,D3
         DIVU     #24,D1
         MOVE.L   D1,D2
         RTS

* Date conversion routine
* Entry: D1 QDOS date
* Exit: D0L month-1, D1L day of month, D2L year, D2H hours, D3L mins, D3H secs
*       D0H day of week (Sun=0)

         XDEF     GETDATE

GETDATE  BSR      GETTIME
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

* CONVERT DATE INTO "DD DD MMM YYYY, HH.MM:SS" FORMAT
* ENTRY: D1 QDOS DATE, A1 START OF BUFFER
* EXIT: D2 LENGTH OF STRING, A1 PAST BUFFER

         XDEF     DATE$

DATE$    MOVEM.L  D1/D3-D6/A2,-(A7)
         BSR      GETDATE
         MOVE.L   D2,D5
         MOVE.L   D3,D6
         SWAP     D0
         LEA      DAYTBL,A2
         ADDA.W   D0,A2
         ADD.W    D0,D0
         ADDA.W   D0,A2
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVEQ    #3,D2
         MOVEQ    #' ',D3
         BSR      ITOD_W
         MOVE.B   D3,(A1)+
         SWAP     D0
         LEA      MONTHTBL,A2
         ADDA.W   D0,A2
         ADD.W    D0,D0
         ADDA.W   D0,A2
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVEQ    #5,D2
         MOVE.W   D5,D1
         BSR      ITOD_W
         MOVE.B   #',',(A1)+
         MOVE.B   D3,(A1)+
         MOVEQ    #25,D4
         BRA.S    CNTIME2

* CONVERT TIME TO "HH.MM:SS" FORMAT

         XDEF     TIME$

TIME$    MOVEM.L  D1/D3-D6/A2,-(A7)
         BSR      GETTIME
         MOVE.L   D2,D5
         MOVE.L   D3,D6
         MOVEQ    #8,D4
CNTIME2  MOVEQ    #2,D2
         SWAP     D5
         MOVE.W   D5,D1
         MOVEQ    #'0',D3
         BSR      ITOD_W
         MOVE.B   #':',(A1)+
         MOVE.W   D6,D1
         BSR      ITOD_W
         MOVE.B   #':',(A1)+
         SWAP     D6
         MOVE.W   D6,D1
         BSR      ITOD_W
         MOVE.W   D4,D2
         MOVEM.L  (A7)+,D1/D3-D6/A2
         RTS

         SECTION  MSG
DAYTBL   DC.B     'SunMonTueWedThuFriSat'
         SECTION  CODE

* Convert D1.W to decimal; D2 field width, D3 fill character

         XDEF     ITOD_W

ITOD_W   MOVEM.L  D1-D2,-(A7)
         CMPI.W   #9,D1
         BHI.S    ITODW_2
ITODW_L  SUBQ.W   #1,D2
         BLE.S    ITODW_S
         MOVE.B   D3,(A1)+
         BRA      ITODW_L
ITODW_2  ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         SUBQ.W   #1,D2
         BSR      ITOD_W
         SWAP     D1
ITODW_S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D1-D2
         RTS

* Convert D1.L to decimal; D2 field width, D3 fill char

         XDEF     ITOD_L

ITOD_L   MOVEM.L  D0-D2,-(A7)
         MOVEQ    #10,D2
         CMP.L    D1,D2
         BLS.S    ITODL_2
         MOVE.L   8(A7),D2
ITODL_L  SUBQ.W   #1,D2
         BLE.S    ITODL_S
         MOVE.B   D3,(A1)+
         BRA      ITODL_L
ITODL_2  BSR      DIVLONG
         MOVE.L   8(A7),D2
         SUBQ.W   #1,D2
         BSR      ITOD_L
         MOVE.B   D0,D1
ITODL_S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D0-D2
         RTS

* Convert Zone:Net/Node.Point to decimal
* Entry: A2 ptr to binary values, A1 ptr to result buffer
* Exit:  A1 past ASCII, D2 length

         XDEF     ZNNP2A

ZNNP2A   MOVE.L   A1,-(A7)
         MOVE.W   (A2)+,D1
         MOVEQ    #0,D2
         BSR.S    ITOD_W
         MOVE.B   #':',(A1)+
         MOVE.W   (A2)+,D1
         BSR.S    ITOD_W
         MOVE.B   #'/',(A1)+
         MOVE.W   (A2)+,D1
         BSR.S    ITOD_W
         MOVE.W   (A2)+,D1
         BEQ.S    Z2A_END
         MOVE.B   #'.',(A1)+
         BSR.S    ITOD_W
Z2A_END  MOVE.L   A1,D2
         SUB.L    (A7)+,D2
         RTS

         XDEF     DAYTAB,MONTHTBL

         SECTION  MSG
         DS.W     0
DAYTAB   DC.B     'SUMOTUWETHFRSA'
MONTHTBL DC.B     'JanFebMarAprMayJunJulAugSepOctNovDec'

* Read directory entry
* Entry: A0 directory channel ID, A1 buffer, A2 directory name
* Exit:  D0 error code, D1 length of file name, D2 length of dir name
*        A1 ptr to file name (after directory)

         MODULE   READDIR

         SECTION  CODE

         XDEF     READDIR

READDIR  MOVEM.L  D3-D4/A0-A2,-(A7)
         MOVE.W   (A2)+,D4
         SUBQ.W   #1,D4
RD_SKPDR CMPI.B   #'_',(A2)+
         DBEQ     D4,RD_SKPDR
RD_LOOP  MOVEQ    #64,D2
         MOVEQ    #-1,D3
         MOVEM.L  8(A7),A0-A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    RD_END
         SUBA.W   D1,A1
         CMPI.B   #-1,5(A1)
         BEQ      RD_LOOP
         LEA      14(A1),A1
         TST.W    (A1)
         BEQ      RD_LOOP
         CMP.W    (A1)+,D4
         BGT      RD_LOOP
         MOVE.W   D4,D2
         BEQ.S    RD_MATCH
         SUBQ.W   #1,D2
         MOVE.L   A2,A0
RD_CMP   MOVE.B   (A0)+,D1
         JSR      TOUPPER
         MOVE.B   D1,D0
         MOVE.B   (A1)+,D1
         JSR      TOUPPER
         CMP.B    D0,D1
         DBNE     D2,RD_CMP
         BNE      RD_LOOP
RD_MATCH MOVEQ    #0,D0
         MOVE.W   D4,D2
RD_END   MOVEM.L  (A7)+,D3-D4/A0-A2
         LEA      14(A1),A1
         MOVE.W   (A1)+,D1
         ADDA.W   D2,A1
         SUB.W    D2,D1
         TST.L    D0
         RTS

         MODULE   STRFUNC

         SECTION  CODE

* Convert D1 to uppercase

         XDEF     TOUPPER

TOUPPER  CMPI.B   #'a',D1
         BLT.S    TU_END
         CMPI.B   #'z',D1
         BGT.S    TU_END
         SUBI.B   #'a'-'A',D1
TU_END   RTS

* Look for matching string (A0) at (A1)

         XDEF     COMPSTR1,COMPSTR

COMPSTR1 CMPI.B   #1,(A1)           Entry point if possible preceedig ^A
         BNE.S    COMPSTR
         MOVE.L   A1,-(A7)
         ADDQ.W   #1,A1
         BRA.S    COMPSTR2
COMPSTR  MOVE.L   A1,-(A7)
COMPSTR2 MOVE.W   (A0)+,D0
         SUBQ.W   #1,D0
CS_LOOP  MOVE.B   (A1)+,D1
         BSR      TOUPPER
         CMP.B    (A0)+,D1
         DBNE     D0,CS_LOOP
         BEQ.S    CS_MATCH
         MOVE.L   (A7)+,A1
         RTS
CS_MATCH ADDQ.W   #4,A7
         RTS

* Execute a command
* Entry: (A1) command, (A2) command list

         XDEF     DO_CMD

DO_CMD   BSR.S    SKIPSPC
         BEQ.S    DC_NOCMD
         CMPI.B   #';',(A1)
         BEQ.S    DC_NOCMD
DC_LOOP  MOVE.W   (A2)+,D2
         BEQ.S    DC_BADCM
         MOVE.L   A2,A0
         BSR      COMPSTR
         BEQ.S    DC_MATCH
         MOVEQ    #3,D0
         ADD.W    (A2),D0
         BCLR     #0,D0
         ADDA.W   D0,A2
         BRA      DC_LOOP
DC_MATCH BSR.S    SKIPSPC
         JMP      -2(A2,D2.W)
DC_NOCMD MOVEQ    #0,D0
         RTS
DC_BADCM MOVEQ    #ERR.BL,D0
         RTS

* Skip spaces at (A1), returns EQ if at end of line

         XDEF     SKIPSPC

SKIPSPC  CMPI.B   #CR,(A1)
         BEQ.S    SKP_END
         CMPI.B   #LF,(A1)
         BEQ.S    SKP_END
         CMPI.B   #' ',(A1)
         BNE.S    SKP_END
         ADDQ.W   #1,A1
         BRA      SKIPSPC
SKP_END  RTS

* Get directory specification
* Entry: (A0) buffer for result, (A1) pointer to dir
* Exit : D1 length of result string

         XDEF     GETDIR

GETDIR   MOVEQ    #0,D0
         MOVEQ    #0,D1
         ADDQ.W   #2,A0
         BSR      SKIPSPC
         CMPI.B   #'-',(A1)
         BEQ.S    GD_END
GD_NXTCH CMPI.B   #LF,(A1)
         BEQ.S    GD_END
         CMPI.B   #' ',(A1)
         BEQ.S    GD_END
         MOVE.B   (A1)+,(A0)+
         ADDQ.W   #1,D1
         CMPI.W   #48,D1
         BLE      GD_NXTCH
         MOVEQ    #ERR.BP,D0
GD_END   SUBA.W   D1,A0
         MOVE.W   D1,-(A0)
         TST.L    D0
         RTS

* Concatenate directory and file name
* Entry: (A0) file name, (A1) directory name, (A2) result buffer
* Exit:  (A0) result, D0 ERR.BN if total >48 chars

         MODULE   MAKEFNAM

         SECTION  CODE

         XDEF     MAKEFNAM

MAKEFNAM MOVE.W   (A0)+,D0
         MOVE.W   (A1)+,D1
         MOVE.W   D0,D2
         ADD.W    D1,D2
         CMPI.W   #48,D2
         BHI.S    MKF_BN
         MOVE.W   D2,(A2)+
         BRA.S    MKF_3
MKF_2    MOVE.B   (A1)+,(A2)+
MKF_3    DBF      D1,MKF_2
         BRA.S    MKF_5
MKF_4    MOVE.B   (A0)+,(A2)+
MKF_5    DBF      D0,MKF_4
         SUBA.W   D2,A2
         LEA      -2(A2),A0
         MOVEQ    #-1,D1
         MOVEQ    #0,D0
         RTS
MKF_BN   MOVEQ    #ERR.BN,D0
         RTS

         SECTION  MSG
         DC.W     0

         END

ALL      STRING$  'ALL'

N_OR_ALL MOVE.L   A0,-(A7)
         LEA      ALL,A0
         JSR      COMPSTR
         MOVE.L   (A7)+,A0
         BEQ.S    N_ALL
         JMP      READNUM
N_ALL    MOVEQ    #-1,D1
         MOVEQ    #0,D0
         RTS

READZNN  JSR      SKIPSPC
         BEQ.S    ZNN_END
         BSR      N_OR_ALL
         BNE.S    ZNN_ERR
         CMPI.B   #LF,(A1)
         BEQ.S    ZNN_ALL
         CMPI.B   #' ',(A1)
         BEQ.S    ZNN_ALL
         CMPI.B   #'/',(A1)
         BEQ.S    ZNN_NET
         CMPI.B   #':',(A1)
         BNE.S    ZNN_ERR
         MOVE.W   D1,D2
         BLT.S    ZNN_ERR
         ADDQ.W   #1,A1
         BSR      N_OR_ALL
         BNE.S    ZNN_ERR
         TST.W    D1
         BLT.S    ZNN_NET
         CMPI.B   #'/',(A1)
         BNE.S    ZNN_ERR
ZNN_NET  MOVE.W   D1,D3
         BLT.S    ZNN_STO
         ADDQ.W   #1,A1
         BSR      N_OR_ALL
         BNE.S    ZNN_ERR
         BRA.S    ZNN_STO
ZNN_ALL  TST.W    D1
         BGE.S    ZNN_STO
         MOVEQ    #-1,D2
ZNN_STO  SWAP     D1
         MOVE.W   D3,D1
         SWAP     D1
         MOVEQ    #0,D0
         RTS
ZNN_END  MOVEQ    #1,D0
         RTS
ZNN_ERR  MOVEQ    #ERR.XP,D0
         RTS

CMDROUTE DC.W     SEND_TO-*
         STRING$  'SEND_TO'
         DC.W     ROUTE_TO-*
         STRING$  'ROUTE_TO'
         DC.W     ACPT_FRM-*
         STRING$  'ACCEPT_FROM'
         DC.W     ACPT_FRM-*
         STRING$  'FORWARD_FOR'
         DC.W     HOLD-*
         STRING$  'HOLD'
         DC.W     PICKUP-*
         STRING$  'PICKUP'
         DC.W     POLL-*
         STRING$  'POLL'
         DC.W     NO_ROUTE-*
         STRING$  'NO_ROUTE'
         DC.W     RECVONLY-*
         STRING$  'RECV_ONLY'
         DC.W     SENDONLY-*
         STRING$  'SEND_ONLY'
         DC.W     0

RECVONLY ST       RX_ONLY(A6)
         BRA.S    RC_OK
SENDONLY ST       TX_ONLY(A6)
RC_OK    MOVEQ    #0,D0
         RTS

SEND_TO  LEA      TGT_LIST(A6),A4
         BRA.S    SET_LIST
ROUTE_TO LEA      RTO_LIST(A6),A4
         BRA.S    SET_LIST
ACPT_FRM LEA      FWD_LIST(A6),A4
         BRA.S    SET_LIST
HOLD     LEA      HLD_LIST(A6),A4
         BRA.S    SET_LIST
PICKUP   LEA      PKP_LIST(A6),A4
         BRA.S    SET_LIST
POLL     LEA      POL_LIST(A6),A4
         BRA.S    SET_LIST
NO_ROUTE LEA      NRT_LIST(A6),A4
SET_LIST MOVEM.W  MYZONE(A6),D2-D3
         MOVEQ    #0,D4
         LEA      BUFFER(A6),A1
SL_LOOP1 BSR      READZNN
         BLT.S    SL_END
         BGT.S    SL_ALLOC
         ADDQ.W   #1,D4
         BRA      SL_LOOP1
SL_ALLOC MOVEQ    #6,D1
         MULU     D4,D1
         ADDQ.L   #6,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE.S    SL_END
SL_SKIP  TST.L    (A4)
         BEQ.S    SL_ENTER
         MOVE.L   (A4),A4
         BRA      SL_SKIP
SL_ENTER MOVE.L   A0,(A4)
         CLR.L    (A0)+
         MOVE.W   D4,(A0)+
         MOVEM.W  MYZONE(A6),D2-D3
         LEA      BUFFER(A6),A1
SL_LOOP2 BSR      READZNN
         BNE.S    SL_OK
         MOVE.W   D2,(A0)+
         MOVE.L   D1,(A0)+
         BRA      SL_LOOP2
SL_OK    MOVEQ    #0,D0
SL_END   RTS

LOOKLIST TST.L    (A0)
         BEQ.S    LL_NOTFD
         MOVE.L   (A0),A0
         LEA      4(A0),A1
         BSR.S    LOOKLST2
         BNE      LOOKLIST
         RTS
LOOKLST2 MOVE.W   (A1)+,D0
         BEQ      LL_NOTFD
         SUBQ.W   #1,D0
         MOVE.L   D1,D3
         SWAP     D3
LL_LOOP  TST.W    (A1)
         BLT.S    LL_FOUND
         CMP.W    (A1)+,D2
         BNE.S    LL_NXT1
         TST.W    (A1)
         BLT.S    LL_FOUND
         CMP.W    (A1)+,D3
         BNE.S    LL_NXT2
         TST.W    (A1)
         BLT.S    LL_FOUND
         CMP.W    (A1)+,D1
         BNE.S    LL_NXT3
LL_FOUND MOVEQ    #0,D0
         RTS
LL_NXT1  ADDQ.W   #2,A1
LL_NXT2  ADDQ.W   #2,A1
LL_NXT3  DBF      D0,LL_LOOP
LL_NOTFD MOVEQ    #ERR.NF,D0
         RTS

* Open or create packet file

OPEN_PKT MOVEM.L  D1-D5/A1-A2,-(A7)
         SUBA.W   #18,A7
         MOVE.L   A7,A1
         MOVE.W   #16,(A1)+
         JSR      PKTNAME
         MOVE.L   #'_PKT',(A1)
         MOVEQ    #IO.EXCL,D3
         MOVE.L   A7,A0
         LEA      DIR_OTBD(A6),A1
         LEA      FNAMBUF(A6),A2
         JSR      OPENSUB
         BEQ      OP_MARK
         CMPI.L   #ERR.NF,D0
         BNE      OP_END
         MOVEQ    #-1,D1
         MOVEQ    #IO.NEW,D3
         QDOS     IO.OPEN
         TST.L    D0
         BNE      OP_END
         LEA      XMODBUF(A6),A1
         MOVEQ    #60+32,D0
CLR_PKHD CLR.L    (A1)+
         SUBQ.W   #4,D0
         BGT      CLR_PKHD
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         BSR      GETDATE
         LEA      XMODBUF+32(A6),A1
         MOVE.L   MYNET(A6),D4
         MOVE.L   18(A7),D5
         ROL.W    #8,D4
         ROL.W    #8,D5
         MOVE.W   D4,(A1)
         MOVE.W   D5,2(A1)
         ROL.W    #8,D2
         MOVE.W   D2,4(A1)
         SUBQ.W   #1,D0
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
         MOVEQ    #60+32,D2
         MOVEQ    #-1,D3
         LEA      XMODBUF(A6),A1
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
OP_END   ADDA.W   #18,A7
         MOVEM.L  (A7)+,D1-D5/A1-A2
         TST.L    D0
         RTS

EX_SCHD  PRLOG    {'EXECUTING SCHEDULE '}
         MOVE.B   D1,SCHEDULE(A6)
         MOVEQ    #-1,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     IO.SBYTE
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         CLR.L    TGT_LIST(A6)
         CLR.L    RTO_LIST(A6)
         CLR.L    FWD_LIST(A6)
         CLR.L    HLD_LIST(A6)
         CLR.L    PKP_LIST(A6)
         CLR.L    POL_LIST(A6)
         CLR.L    NRT_LIST(A6)
         SF       TX_ONLY(A6)
         SF       RX_ONLY(A6)
         LEA      BUFFER(A6),A0
         MOVE.W   #7,(A0)
         MOVE.L   #'ROUT',2(A0)
         MOVE.W   #'E_',6(A0)
         MOVE.B   SCHEDULE(A6),8(A0)
         LEA      SYSDIR(A6),A1
         JSR      OP_FIN
         BEQ.S    ES_DOCMD
         PRLOG    {'NO ROUTE FILE - RECEIVE-ONLY SCHEDULE',LF}
         ST       RX_ONLY(A6)
         RTS
ES_DOCMD MOVE.W   #BUFLEN,D2
         LEA      BUFFER(A6),A1
         LEA      CMDROUTE,A2
         JSR      EX_CMDF
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         MOVE.L   (A7)+,D0
         BEQ.S    ES_PACK
         PRLOG    {'ERROR IN ROUTE FILE: '}
         MOVE.L   LOGCHAN(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA      CLR_SCHD
ES_PACK  JSR      SETNAREA
         BNE      NO_NAREA
         MOVEQ    #IO.EXCL,D3
         LEA      MSG_FNAM,A0
         LEA      DIRBUF(A6),A1
         LEA      FNAMBUF(A6),A2
         JSR      OPENSUB
         BNE      NO_NAREA
         MOVE.L   A0,DIRCHAN(A6)
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         MOVE.B   D1,D7
         MOVEQ    #0,D6
         BRA.S    ES_PKLP
ES_PKNXT ADDQ.B   #1,D6
ES_PKLP  CMP.B    D6,D7
         BLS      ES_PKEND
         BSR      GET_MSGH
         BNE      ES_PKNXT
         MOVE.W   BUFFER+MS_ATTR(A6),D5
         BTST     #MS..PAKD,D5
         BNE      ES_PKNXT
         BTST     #MS..LOC,D5
         BNE.S    ES_TSTCR
         BTST     #MS..TRNS,D5
         BEQ      ES_PKNXT
         BTST     #MS..FATT,D5
         BEQ      ES_PKNXT
         BTST     #MS..CRSH,D5
         BNE      ES_PKNXT
         MOVE.W   BUFFER+MS_OZONE(A6),D2
         MOVE.L   BUFFER+MS_ONET(A6),D1
         LEA      FWD_LIST(A6),A0
         BSR      LOOKLIST
         BEQ.S    ES_TSTCR
         BSET     #MS..ORPH,BUFFER+MS_ATTR+1(A6)
         BSR      MARK_ATR
         BRA      ES_PKNXT
ES_TSTCR MOVE.W   BUFFER+MS_DZONE(A6),D2
         MOVE.L   BUFFER+MS_DNET(A6),D1
         BTST     #MS..CRSH,D5
         BNE.S    ES_CHKTG
         BTST     #MS..FATT,D5
         BNE.S    ES_CHKTG
         LEA      NRT_LIST(A6),A0
         BSR      LOOKLIST
         BEQ.S    ES_CHKTG
         LEA      RTO_LIST(A6),A0
ES_RTO_L TST.L    (A0)
         BEQ.S    ES_DEFRT
         MOVE.L   (A0),A0
         LEA      4(A0),A1
         BSR      LOOKLST2
         BNE      ES_RTO_L
         MOVE.W   6(A0),D2
         MOVE.L   8(A0),D1
         BRA.S    ES_CHKTG
ES_DEFRT
