* SEENBY Utility
* September 11, 1989

         INCLUDE  FLP1_QDOS_IN_MAC

CR       EQU      $0D
LF       EQU      $0A

MAXSBY   EQU      256
MAXNODES EQU      64

* Stored message offsets

MS_DATE  EQU      0        Date & time of entry (QDOS format)
MS_OZONE EQU      4        Origination zone
MS_ONET  EQU      6                    net
MS_ONODE EQU      8                    node
MS_OPNT  EQU      10                   point
MS_DZONE EQU      12       Destination zone (or -1 if Echomail msg)
MS_DNET  EQU      14       Dest. net (or ptr to SEEN-BY lines)
MS_DNODE EQU      16       Dest. node (or ptr to product banner)
MS_DPNT  EQU      18       Dest. point
MS_ATTR  EQU      20       Attribute bits
MS_COST  EQU      22       Cost
MS_REPTO EQU      24       Msg # to which this msg replies
MS_NXREP EQU      25       Msg # which is reply to this msg
MS_NREAD EQU      26       Times read
MS_UPDAT EQU      28       Update date & time
MS_TOUSR EQU      32       Start of TOUSER field

         OFFSET   0

MSGCHAN  DS.L     1
MSG_BASE DS.L     1
MSG_END  DS.L     1
MSG_MAX  DS.L     1
ERR_SP   DS.L     1
MAXMSG   DS.B     1
MSGPNT   DS.B     1
         DS.W     0
ADDNODES DS.W     1+2*MAXNODES
REMNODES DS.W     1+2*MAXNODES
SBYNODES DS.W     1+2*MAXSBY
BUFFER   DS.B     4096

         DATA     8*1024

         SECTION  CODE

         BRA.S    START
         DC.L     0
         DC.W     $4AFB
         STRING$  'SEENBY'
SEEN_BY  STRING$  {'SEEN-BY:'}
START    ADDA.L   A4,A6
         CMPI.W   #1,(A7)+
         BNE.S    BADPARAM
         MOVE.L   (A7)+,MSGCHAN(A6)
         MOVE.L   A7,A0
         LEA      BUFFER(A6),A1
         MOVE.W   (A0)+,D0
         BNE.S    OPT_N
BADPARAM SUBA.L   A0,A0
         PRINT    {'Use EW SEENBY,<msg file>;"<nodes>"',LF}
         MOVEQ    #ERR.BP,D0
         BRA.S    KILL_JOB
OPT_L    MOVE.B   (A0)+,(A1)+
OPT_N    DBF      D0,OPT_L
         MOVE.B   #LF,(A1)+
         BSR      PROCESS
KILL_JOB MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

LD_WORD  MOVE.B   (A1)+,D1
         LSL.W    #8,D1
         MOVE.B   (A1)+,D1
         TST.W    D1
         RTS

STO_WORD ROR.W    #8,D1
         MOVE.B   D1,(A1)+
         ROR.W    #8,D1
         MOVE.B   D1,(A1)+
         RTS

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
* Exit:  D2 number of entries found, D3 updated net nr, A1 and A4 updated

READNODE MOVEQ    #0,D2
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
         MOVE.W   D4,(A4)+
         MOVE.W   D1,(A4)+
         BRA      RL_NEXT
RL_ERR   MOVEQ    #ERR.XP,D0
         BRA.S    RL_END
RL_2MANY MOVEQ    #1,D0
RL_END   RTS

LBYTES   MOVEQ    #IO.FSTRG&$FF,D4
         BRA.S    LSBYTES
SBYTES   MOVEQ    #IO.SSTRG&$FF,D4
LSBYTES  MOVE.L   D2,-(A7)
         CMPI.L   #$7FFE,D2
         BLS.S    LSB_2
         MOVE.L   #$7FFE,D2
LSB_2    MOVE.B   D4,D0
         MOVEQ    #-1,D3
         TRAP     #3
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    LSB_ERR
         ANDI.L   #$7FFF,D1
         SUB.L    D1,D2
         BHI      LSBYTES
         RTS
LSB_ERR  MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'SEENBY: Message file I/O Error',LF}
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
         RTS

INSERT   MOVEM.L  A0-A2,-(A7)
         MOVE.L   MSG_END(A6),A0
         LEA      (A0,D1.L),A2
         CMPA.L   MSG_MAX(A6),A2
         BHI.S    ERR_BF
         MOVE.L   A2,MSG_END(A6)
         TST.L    D1
         BEQ.S    INS_END
         BLT.S    INS_DEL
INS_LOOP MOVE.B   -(A0),-(A2)
         CMPA.L   A1,A0
         BHI      INS_LOOP
         BRA.S    INS_LEN
INS_DEL  MOVE.L   A1,A0
         SUBA.L   D1,A0
INS_DLP  MOVE.B   (A0)+,(A1)+
         CMPA.L   A2,A1
         BLO      INS_DLP
INS_LEN  LEA      MS_TOUSR(A5),A1
         MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.L   D1,D0
         BSR      LD_WORD
         ADD.W    D0,D1
         SUBQ.W   #2,A1
         BSR      STO_WORD
         MOVE.L   D0,D1
         MOVE.L   MSG_BASE(A6),A0
         MOVEQ    #0,D0
         MOVE.B   MSGPNT(A6),D0
         LSL.W    #2,D0
INS_PADJ CMPI.W   #4*255,D0
         BGE.S    INS_END
         TST.L    (A0,D0.W)
         BLT.S    INS_NXT
         ADD.L    D1,(A0,D0.W)
INS_NXT  ADDQ.W   #4,D0
         BRA      INS_PADJ
INS_END  MOVEM.L  (A7)+,A0-A2
         RTS
ERR_BF   SUBA.L   A0,A0
         PRINT    {'SEENBY: Workspace overflow',LF}
         MOVEQ    #ERR.BO,D0
         MOVE.L   ERR_SP(A6),A7
         RTS

COPYSTR  MOVE.W   (A1)+,D1
COPYSTR2 MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      COPYSTR2
         RTS

LOOK_SBY LEA      SBYNODES(A6),A1
         MOVE.W   (A1)+,D0
         SUBQ.W   #1,D0
         BLT.S    LSBY_END
LSBY_LP  CMP.L    (A1)+,D1
         DBEQ     D0,LSBY_LP
LSBY_END RTS

TOUPPER  CMPI.B   #'a',D1
         BLT.S    TU_END
         CMPI.B   #'z',D1
         BGT.S    TU_END
         SUBI.B   #'a'-'A',D1
TU_END   RTS

COMPSTR1 CMPI.B   #1,(A1)
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

SKIPSPC  CMPI.B   #CR,(A1)
         BEQ.S    SKP_END
         CMPI.B   #LF,(A1)
         BEQ.S    SKP_END
         CMPI.B   #' ',(A1)
         BNE.S    SKP_END
         ADDQ.W   #1,A1
         BRA      SKIPSPC
SKP_END  RTS

PROCESS  MOVE.L   A7,ERR_SP(A6)
         LEA      BUFFER(A6),A1
         CLR.W    ADDNODES(A6)
         CLR.W    REMNODES(A6)
PROC_RN  BSR      SKIPSPC
         BEQ.S    LOADMSGS
         LEA      ADDNODES(A6),A0
         CMPI.B   #'+',(A1)
         BEQ.S    SKIPSIGN
         CMPI.B   #'-',(A1)
         BNE.S    GETNET
         LEA      REMNODES(A6),A0
SKIPSIGN ADDQ.W   #1,A1
GETNET   BSR      READNUM
         BNE.S    SYNTXERR
         MOVE.W   D1,D2
         CMPI.B   #'/',(A1)+
         BNE.S    SYNTXERR
         BSR      READNUM
         BNE.S    SYNTXERR
         MOVE.W   (A0),D0
         CMPI.W   #MAXNODES,D0
         BGE.S    TOOMANY
         ADDQ.W   #1,(A0)+
         LSL.W    #2,D0
         ADDA.W   D0,A0
         MOVE.W   D2,(A0)+
         MOVE.W   D1,(A0)+
         BRA      PROC_RN
SYNTXERR SUBA.L   A0,A0
         PRINT    {'SEENBY: Syntax error in node list',LF}
         MOVEQ    #ERR.XP,D0
         RTS
TOOMANY  SUBA.L   A0,A0
         PRINT    {'SEENBY: Too many nodes specified',LF}
         MOVEQ    #ERR.OR,D0
RET_ERR  RTS
LOADMSGS MOVEQ    #4,D2
         MOVEQ    #-1,D3
         MOVE.L   MSGCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      RET_ERR
         QDOS     IO.FBYTE
         TST.L    D0
         BNE      RET_ERR
         MOVE.B   D1,MAXMSG(A6)
         ANDI.W   #$FF,D1
         MULU     ADDNODES(A6),D1
         LSL.L    #3,D1
         ADD.L    BUFFER(A6),D1
         ADDI.L   #1024,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE      RET_ERR
         MOVE.L   A0,MSG_BASE(A6)
         LEA      -16(A0,D1.L),A0
         MOVE.L   A0,MSG_MAX(A6)
         MOVE.L   BUFFER(A6),D2
         SUBQ.L   #1,D2
         MOVEQ    #-1,D3
         MOVE.L   MSGCHAN(A6),A0
         MOVE.L   MSG_BASE(A6),A1
         MOVE.L   A1,MSG_END(A6)
         ADD.L    D2,MSG_END(A6)
         BSR      LBYTES
         CLR.B    MSGPNT(A6)
NEXT_MSG MOVEQ    #0,D0
         MOVE.B   MSGPNT(A6),D0
         CMP.B    MAXMSG(A6),D0
         BHS      MSG_DONE
         ADDQ.B   #1,MSGPNT(A6)
         MOVE.L   MSG_BASE(A6),A5
         LSL.W    #2,D0
         MOVE.L   (A5,D0.W),D0
         BLT      NEXT_MSG
         LEA      -1(A5,D0.L),A5
         LEA      MS_DZONE(A5),A1
         BSR      LD_WORD
         BGE      NEXT_MSG
         BSR      LD_WORD
         MOVE.W   D1,D2
         LEA      MS_TOUSR(A5),A1
         MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         BSR      LD_WORD
         MOVEQ    #0,D7
         MOVE.W   D1,D7
         ADD.L    A1,D7
         LEA      (A1,D2.W),A3
         MOVE.L   A3,A1
         LEA      SBYNODES(A6),A4
         CLR.W    (A4)+
         MOVEQ    #0,D4
COPY_EIN CMP.L    A1,D7
         BLS.S    NODESCAN
         LEA      SEEN_BY,A0
         BSR      COMPSTR1
         BNE.S    NODESCAN
         MOVE.W   #MAXSBY,D3
         SUB.W    SBYNODES(A6),D3
         BSR      READNODE
         BLT      SB_ERROR
         BGT      SB_2MANY
         ADD.W    D2,SBYNODES(A6)
         ADDQ.W   #1,A1
         BRA      COPY_EIN
NODESCAN MOVE.L   A1,D6
         LEA      REMNODES(A6),A4
         MOVE.W   (A4)+,D4
         BEQ.S    NSCAN_2
DEL_NODE MOVE.L   (A4)+,D1
         BSR      LOOK_SBY
         BNE.S    DN_NEXT
         LEA      -4(A1),A0
         BRA.S    DN_DBF
DN_LOOP  MOVE.L   (A1)+,(A0)+
DN_DBF   DBF      D0,DN_LOOP
         SUBQ.W   #1,SBYNODES(A6)
DN_NEXT  SUBQ.W   #1,D4
         BGT      DEL_NODE
NSCAN_2  LEA      ADDNODES(A6),A4
         MOVE.W   (A4)+,D4
         BEQ.S    SBY_SORT
ADD_NODE MOVE.L   (A4)+,D1
         BSR      LOOK_SBY
         BEQ.S    AN_NEXT
         CMPI.W   #MAXSBY,SBYNODES(A6)
         BEQ.S    SBY_SORT
         MOVE.L   D1,(A1)
         ADDQ.W   #1,SBYNODES(A6)
AN_NEXT  SUBQ.W   #1,D4
         BGT      ADD_NODE
SBY_SORT SF       D0
         LEA      SBYNODES(A6),A4
         MOVE.W   (A4)+,D4
         BRA.S    SSORT_NX
SSORT_CP MOVE.L   (A4)+,D1
         CMP.L    (A4),D1
         BLS.S    SSORT_NX
         MOVE.L   (A4),-4(A4)
         MOVE.L   D1,(A4)
         ST       D0
SSORT_NX SUBQ.W   #1,D4
         BGT      SSORT_CP
         TST.B    D0
         BNE      SBY_SORT
         BSR.S    GEN_SNBY
         MOVE.L   A2,D2
         LEA      BUFFER(A6),A2
         SUB.L    A2,D2
         MOVE.L   D2,D1
         SUB.L    A3,D6
         SUB.L    D6,D1
         MOVE.L   A3,A1
         BSR      INSERT
RSTO_LP  MOVE.B   (A2)+,(A3)+
         SUBQ.L   #1,D2
         BGT      RSTO_LP
         BRA      NEXT_MSG

SB_ERROR SUBA.L   A0,A0
         PRINT    {'SEENBY: Syntax error in SEEN-BY list msg #'}
         BRA.S    SKIPMSG
SB_2MANY SUBA.L   A0,A0
         PRINT    {'SEENBY: Too many nodes in SEEN-BY list msg #'}
SKIPMSG  MOVEQ    #1,D1
         ADD.B    MSGPNT(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' - message skipped',LF}
         BRA      NEXT_MSG

GEN_SNBY SUBA.L   A0,A0
         LEA      BUFFER(A6),A2
         LEA      SBYNODES(A6),A4
         MOVE.W   (A4)+,D4
SB_NEXT  SUBQ.W   #1,D4
         BLT.S    SB_END
         MOVE.L   A0,D0
         BEQ.S    SB_FIRST
         MOVE.L   A2,D0
         SUB.L    A0,D0
         CMPI.W   #64,D0
         BLS.S    SB_GEN
         MOVE.B   #CR,(A2)+
SB_FIRST MOVE.L   A2,A0
         LEA      SEEN_BY,A1
         BSR      COPYSTR
         MOVE.B   #' ',(A2)+
         MOVE.L   A2,A1
         MOVEQ    #-1,D3
SB_GEN   MOVE.W   (A4)+,D1
         CMP.W    D3,D1
         BEQ.S    SB_NODE
         MOVE.W   D1,D3
         BSR.S    ITOD_W
         MOVE.B   #'/',(A1)+
SB_NODE  MOVE.W   (A4)+,D1
         BSR.S    ITOD_W
         MOVE.B   #' ',(A1)+
         MOVE.L   A1,A2
         BRA      SB_NEXT
SB_END   MOVE.B   #CR,(A2)+
         RTS

ITOD_W   MOVE.L   D1,-(A7)
         CMPI.W   #9,D1
         BLS.S    ITODW_S
         ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         BSR      ITOD_W
         SWAP     D1
ITODW_S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVE.L   (A7)+,D1
         RTS

MSG_DONE MOVEQ    #1,D1
         MOVEQ    #-1,D3
         MOVE.L   MSGCHAN(A6),A0
         QDOS     FS.POSAB
         MOVE.L   MSG_BASE(A6),A1
         MOVE.L   MSG_END(A6),D2
         SUB.L    A1,D2
         BSR      SBYTES
         QDOS     FS.TRUNC
         MOVEQ    #0,D0
         RTS

         SECTION  MSG
         DC.W     0

         END
