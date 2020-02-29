* QBOXMail Mailer; file transfer routines

         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H
         INCLUDE  WIN3_QBDEV_FSC39_H

NL_ID    EQU      'NL01'

ZONE     EQU      -1
REGION   EQU      -2
HOST     EQU      -3
HUB      EQU      -4
PVT      EQU      -5
HOLD     EQU      -6
DOWN     EQU      -7

         XREF     ITOD.W,GETDATE,NDLSTFNM,ZNNP2A,WRITE$,WRITEL$
         XREF     DO_INP,DO_OUTP,TXCHAR,LOG,LOG0,FCLOSE,DIRCLOSE
         XREF     RX_CLINK,TX_CLINK,CALCCRC,FLUSH,TOUPPER

         SECTION  CODE

* Remap 4D-address (in D2-D5) to 3D using pointnet conversion

REMAP3D  MOVEM.L  A0/A1,-(A7)
         TST.W    D2
         BNE.S    R3D_2
         MOVE.W   S_MYADDR(A6),D2
R3D_2    TST.W    D5
         BEQ.S    R3D_END
         MOVEQ    #0,D0
         LEA      S_PNTNET(A6),A0
         LEA      S_MYADDR(A6),A1
R3D_LP   CMP.W    (A1),D2
         BNE.S    R3D_NXT
         CMP.W    (A0),D3
         BEQ.S    R3D_FAKE          Fixes Qscan bug (zone:pointnet/point.point)
         CMP.W    2(A1),D3
         BNE.S    R3D_NXT
         CMP.W    4(A1),D4
         BNE.S    R3D_NXT
         TST.W    (A0)
         BEQ.S    R3D_END
         MOVE.W   (A0),D3
         MOVE.W   D5,D4
R3D_FAKE MOVEQ    #0,D5
         BRA.S    R3D_END
R3D_NXT  ADDQ.L   #2,A0
         ADDQ.L   #8,A1
         ADDQ.W   #1,D0
         CMPI.W   #MAX_AKA,D0
         BLT      R3D_LP
R3D_END  MOVEM.L  (A7)+,A0/A1
         RTS

* Match our own address from remote's zone
* Entry: D2-D5 address to match
* Exit : D2-D5 our zone-matched AKA, or main address if not matched

         XDEF     AKAMATCH

AKAMATCH MOVE.L   A0,-(A7)
         TST.W    D2
         BEQ.S    MA_MAIN
         MOVEQ    #0,D0
         LEA      S_MYADDR(A6),A0
MA_LOOP  CMP.W    (A0),D2
         BEQ.S    MA_MATCH
         ADDQ.L   #8,A0
         ADDQ.W   #1,D0
         CMPI.W   #MAX_AKA,D0
         BLT      MA_LOOP
MA_MAIN  MOVEQ    #0,D0
         LEA      S_MYADDR(A6),A0
MA_MATCH MOVEM.W  (A0),D2-D5
         MOVE.L   (A7)+,A0
         RTS

ZNN_TO_H LEA      BUFFER(A6),A1
         MOVE.W   #16,(A1)+
ZNN2H_2  MOVE.W   D2,-(A7)
         MOVE.W   D2,D1
         BSR.S    ITOH_W
         MOVE.W   D3,D1
         BSR.S    ITOH_W
         MOVE.W   D4,D1
         BSR.S    ITOH_W
         MOVE.W   (A7)+,D2
         RTS
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

* Open new .PKT file with random name

RND_PKT  QDOS     MT.RCLCK
         BSR      GETDATE
         LEA      FILENAME(A6),A1
         MOVE.W   #12,(A1)+
         MOVE.W   #2,D2
         MOVEQ    #'0',D3
         BSR      ITOD.W
         MOVE.L   D2,D1
         SWAP     D1
         BSR      ITOD.W
         MOVE.L   D3,D1
         BSR      ITOD.W
         SWAP     D1
         BSR      ITOD.W
         MOVE.L   #'.PKT',(A1)+
         RTS

OPEN_PKT MOVE.L   #'_PKT',-(A7)
         LEA      INPCHAN(A6),A3
         BRA.S    OP_NAME
OPEN_ATT MOVE.L   #'_ATT',-(A7)
         LEA      DIRCHAN(A6),A3
         BRA.S    OP_NAME
OPEN_FRQ MOVE.L   #'_FRQ',-(A7)
         LEA      DIRCHAN(A6),A3
OP_NAME  MOVEM.W  DESTZONE(A6),D2-D5
         BSR      REMAP3D
         BSR      ZNN_TO_H
         MOVE.L   (A7)+,(A1)+
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER(A6),A0
         LEA      S_OUTBND(A6),A1
         BSR.S    OPEN_2
         BNE.S    OPEN_END
         MOVE.L   A0,(A3)
OPEN_END TST.L    D0
         RTS

OPENSYS  LEA      S_SYSDIR(A6),A1
OPEN_2   BSR.S    MKFNAME
OPEN_3   MOVEQ    #-1,D1
         QDOS     IO.OPEN
         TST.L    D0
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

* Create a _PKT file according to dest. address

         XDEF     MAKE_PKT

MAKE_PKT MOVEM.L  D1-D6/A1-A3,-(A7)
         MOVEQ    #PK_HDLEN,D6
         MOVEM.W  DESTZONE(A6),D2-D5
         BSR      REMAP3D
         BSR      ZNN_TO_H
         MOVE.L   #'_PKT',(A1)+
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER(A6),A0
         LEA      S_OUTBND(A6),A1
         BSR      OPEN_2
         BEQ.S    OP_MARK
         CMPI.L   #ERR.NF,D0
         BNE      OP_END
         ADDQ.W   #2,D6
         MOVEQ    #IO.NEW,D3
         LEA      FNAMBUF(A6),A0
         BSR      OPEN_3
         BNE      OP_END
OP_MARK  LEA      BUFFER(A6),A1
         MOVEQ    #PK_HDLEN+2,D0
CLR_PKHD CLR.L    (A1)+
         SUBQ.W   #4,D0
         BGT      CLR_PKHD
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         JSR      GETDATE
         LEA      BUFFER(A6),A1
         MOVE.L   MYNET(A6),D4
         MOVE.L   DESTNET(A6),D5
         ROL.W    #8,D4
         ROL.W    #8,D5
         MOVE.W   D4,PK_ONODE(A1)
         MOVE.W   D5,PK_DNODE(A1)
         ROL.W    #8,D2
         MOVE.W   D2,PK_YEAR(A1)
         SUBQ.W   #1,D0
         MOVE.B   D0,PK_MONTH(A1)
         MOVE.B   D1,PK_DAY(A1)
         SWAP     D2
         MOVE.B   D2,PK_HOUR(A1)
         MOVE.B   D3,PK_MIN(A1)
         SWAP     D3
         MOVE.B   D3,PK_SEC(A1)
         MOVE.B   #PKTVERS,PK_VERSN(A1)
         SWAP     D4
         ROL.W    #8,D4
         SWAP     D5
         ROL.W    #8,D5
         MOVE.W   D4,PK_ONET(A1)
         MOVE.W   D5,PK_DNET(A1)
         MOVE.B   #QBOXMAIL,PK_PRDCL(A1)
         MOVE.B   #REV_MAJ,PK_PRDRH(A1)
         MOVE.B   #REV_MIN,PK_PRDRL(A1)
         LEA      PASSWORD(A6),A2
         LEA      PK_PWD(A1),A3
         MOVEQ    #7,D0
OP_PWD   MOVE.B   (A2)+,(A3)+
         DBEQ     D0,OP_PWD
         MOVE.W   MYZONE(A6),D0
         ROL.W    #8,D0
         MOVE.W   D0,PK_OZONE(A1)
         MOVE.W   D0,PK_QOZON(A1)
         MOVE.W   DESTZONE(A6),D0
         ROL.W    #8,D0
         MOVE.W   D0,PK_DZONE(A1)
         MOVE.W   D0,PK_QDZON(A1)
         MOVE.W   MYPOINT(A6),D0
         ROL.W    #8,D0
         MOVE.W   D0,PK_OPNT(A1)
         MOVE.W   #CAPWD,D0
         MOVE.W   D0,PK_CAPWD(A1)
         ROL.W    #8,D0
         MOVE.W   D0,PK_CAPVL(A1)
         MOVE.W   D6,D2
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         MOVE.L   D0,D4
         BEQ.S    OP_BACK
         QDOS     IO.CLOSE
         MOVE.L   D4,D0
         BRA.S    OP_END
OP_BACK  MOVEQ    #0,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         CMPI.W   #60,D6
         BNE.S    OP_END
         QDOS     FS.FLUSH
OP_END   MOVEM.L  (A7)+,D1-D6/A1-A3
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
         RTS

FINDZONE MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE.S    FZ_END
         MOVE.L   -(A1),D1
         QDOS     FS.POSAB
FZ_LOOP  MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE.S    FZ_END
         CMP.W    -4(A1),D4
         BEQ.S    FZ_MATCH
         MOVEQ    #0,D1
         MOVE.W   -2(A1),D1
         BEQ.S    FNODE_NF
         QDOS     FS.POSRE
         BRA      FZ_LOOP
FZ_MATCH MOVEQ    #6,D2
         BSR      FSTRG
         BNE.S    FZ_END
         MOVE.L   -6(A1),D5
         MOVE.W   D4,-4(A1)
         MOVEQ    #0,D0
FZ_END   RTS

FINDNET  CMP.W    -4(A1),D4
         BEQ.S    FR_MATCH
         MOVE.W   -2(A1),D0
         BEQ.S    FNODE_NF
         ADD.L    D0,D5
         MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE.S    FNET_END
         BRA      FINDNET
FR_MATCH MOVE.L   D5,D1
         QDOS     FS.POSAB
         MOVEQ    #2,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE.S    FNET_END
         MOVE.W   D4,(A1)+
         BSR.S    GETNODE
         BNE.S    FNET_END
         CMPI.W   #HOST,(A1)
         SEQ      D5
FNODE_OK MOVEQ    #0,D0
FNET_END RTS
FNODE_NF MOVEQ    #ERR.BP,D0
         RTS

FINDNODE TST.W    D4
         BEQ.S    FNODE_OK
FN_LOOP  MOVEQ    #2,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE      FNET_END
         MOVE.W   -2(A1),D1
         BGT.S    FNODE_CP
         CMPI.W   #HUB,D1
         BGT      FNODE_NF
         BSR      FSTRG
         BNE      FNET_END
         MOVE.W   -2(A1),D1
FNODE_CP CMP.W    D4,D1
         SNE      -(A7)
         BSR.S    GETNODE
         BNE.S    FN_ERR
         TST.B    (A7)+
         BNE      FN_LOOP
         RTS
FN_ERR   ADDQ.W   #2,A7
         RTS

GETNODE  MOVEQ    #1,D2
         BSR      FSTRG
         BNE.S    GN_END
         MOVEQ    #0,D2
         MOVE.B   -1(A1),D2
         BSR      FSTRG
         BNE.S    GN_END
         LEA      NODEBUF(A6),A1
         MOVEQ    #0,D0
GN_END   RTS

         XDEF     LOOK_NL

LOOK_NL  MOVEM.L  D1-D2/D4-D5/A0-A2,-(A7)
         MOVEQ    #IO.SHARE,D3
         LEA      NDLSTFNM,A0
         BSR      OPENSYS
         BNE.S    FN_END2
         MOVEQ    #4,D2
         LEA      NODEBUF(A6),A1
         BSR      FSTRG
         BNE.S    FN_END
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
FN_END2  MOVEM.L  (A7)+,D1-D2/D4-D5/A0-A2
         TST.L    D0
         RTS

* Get name & location of remote in A1

         XDEF     DISPNODE

DISPNODE LEA      NODEBUF(A6),A0
         TST.W    (A0)+
         BGT.S    DN_NAME
         ADDQ.W   #2,A0
DN_NAME  ADDQ.W   #1,A0
         CMPI.B   #$80,(A0)
         BEQ.S    DN_NNAME
         MOVE.B   #' ',(A1)+
         MOVE.B   #'-',(A1)+
         MOVE.B   #' ',(A1)+
CVT_CNAM MOVEQ    #$7F,D1
         AND.B    (A0),D1
         MOVE.B   D1,(A1)+
         TST.B    (A0)+
         BPL      CVT_CNAM
         RTS
DN_NNAME ADDQ.W   #1,A0
         RTS

* Set timer

         XDEF     SET1MIN,SETTIMER

SET1MIN  MOVEQ    #60,D1
SETTIMER MOVEM.L  D1-D2/A0,-(A7)
         QDOS     MT.RCLCK
         ADD.L    (A7),D1
         MOVE.L   D1,TIMEOUT(A6)
         MOVEM.L  (A7)+,D1-D2/A0
         RTS

* Check timer (ERR.NC in D0 if timeout)

         XDEF     CHKTIMER

CHKTIMER MOVEM.L  D1-D2/A0,-(A7)
         QDOS     MT.RCLCK
         CMP.L    TIMEOUT(A6),D1
         MOVEM.L  (A7)+,D1-D2/A0
         BHI.S    CHKTIM_2
         MOVEQ    #0,D0
         RTS
CHKTIM_2 MOVEQ    #ERR.NC,D0
         RTS

* Do inbound mail session

         XDEF     DO_INBND

DO_INBND BSR      RECV_FTS
         BNE.S    HANG_UP
         ST       GOTMAIL(A6)
         MOVEM.W  D2-D5,DESTZONE(A6)
         BSR      AKAMATCH
         MOVEM.W  D2-D5,MYZONE(A6)
         LEA      LOGBUF(A6),A1
         WRITE$   {'Received from '},A1
         LEA      DESTZONE(A6),A2
         JSR      ZNNP2A
         BSR      LOOK_NL
         BNE.S    N_UNKN
         BSR      DISPNODE
         CLR.B    (A1)+
         BRA.S    TSTPKUP
N_UNKN   WRITE$   {' (Unlisted system)',0}
TSTPKUP  JSR      LOG0
         MOVEM.W  DESTZONE(A6),D2-D5
         BSR      REMAP3D
         TST.W    D5
         BNE.S    END_SES
         BSR      OPEN_ATT
         BNE.S    NO_ATTS
         JSR      DIRCLOSE
         BRA.S    DO_PKUP
NO_ATTS  BSR      OPEN_PKT
         BNE.S    END_SES
         JSR      FCLOSE
DO_PKUP  LOG      {'Remote has mail waiting',LF}
         BSR.S    SEND_FTS
         BRA.S    HANG_UP
END_SES  MOVEQ    #0,D0
HANG_UP  TST.L    D0
         BLT.S    REP_ERR
         BGT.S    NO_PKUP
         LOG      {'Session successful',LF}
         RTS
NO_PKUP  LOG      {'Remote refused pick-up',LF}
         RTS
REP_ERR  LOG      {'Session failed',LF}
HANGUP2  RTS

* FTS-0001 transmit session

SEND_FTS BSR      SET1MIN
SF_WTCLR MOVEQ    #25,D3
         BSR      GETCHR2
         BLT      SF_END1
         BEQ      SF_WTCLR
         MOVEQ    #30,D1
         BSR      SETTIMER
SF_TSYNC MOVEQ    #TSYNC,D1
         JSR      TXCHAR
         MOVEQ    #2*50,D3
         BSR      GETCHR1
         BLT      SF_END1
         BGT      SF_TSYNC
         CMPI.B   #C,D1
         BEQ.S    SF_SPKT
         CMPI.B   #NAK,D1
         BNE      SF_TSYNC
SF_SPKT  JSR      MAKE_PKT
         BNE      SF_END
         MOVE.L   A0,INPCHAN(A6)
         MOVE.W   D1,-(A7)
         BSR      RND_PKT
         MOVE.W   (A7)+,D1
         LOG      {'Sending mail packet',LF}
         MOVE.W   #1<<WANT_C+1<<XR..SKIP+1,D7
         JSR      TX_CLINK
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         MOVE.L   (A7)+,D0
         BNE      SF_END
         BSR      DEL_PKT
SF_ATT   JSR      OPEN_ATT
         BNE      SF_NFILE
SF_NXTFL MOVEQ    #0,D1
         MOVEQ    #-1,D3
         MOVE.L   DIRCHAN(A6),A0
         QDOS     FS.POSRE
         MOVE.L   D1,D4
         MOVEQ    #49,D2
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BEQ.S    SF_FCHAR
         CMPI.L   #ERR.EF,D0
         BEQ      SF_ENDFL
         MOVE.L   D0,-(A7)
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Error in '}
         MOVEM.W  DESTZONE(A6),D2-D5
         BSR      REMAP3D
         BSR      ZNN2H_2
         WRITE$   {'_ATT: '}
         MOVE.L   (A7),D0
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
         MOVE.L   (A7)+,D0
         BRA      SF_ERROR
SF_FCHAR SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BEQ      SF_NXTFL
         MOVE.B   (A1),D2
         CMPI.B   #';',D2
         BEQ      SF_NXTFL
         CMPI.B   #'^',D2
         BEQ.S    SF_MIN1
         CMPI.B   #'#',D2
         BNE.S    SF_FNAME
SF_MIN1  ADDQ.W   #1,A1
         SUBQ.W   #1,D1
         BEQ      SF_NXTFL
SF_FNAME LEA      FNAMBUF(A6),A0
         MOVE.W   D1,(A0)+
         SF       D3
SF_CLRFN LEA      FILENAME(A6),A2
         CLR.W    (A2)+
SF_CPFNM MOVE.B   (A1)+,D0
         CMPI.B   #'/',D0
         BEQ.S    SF_UND
         CMPI.B   #'\',D0
         BNE.S    SF_STO
SF_UND   ST       D3
         MOVE.B   #'_',(A0)+
         BRA      SF_CLRFN
SF_STO   MOVE.B   D0,(A0)+
         MOVE.B   D0,(A2)+
         ADDQ.W   #1,FILENAME(A6)
         SUBQ.W   #1,D1
         BLE.S    SF_SAVFL
         CMPI.B   #'_',D0
         BNE      SF_CPFNM
         TST.B    D3
         BNE      SF_CPFNM
         CMPI.B   #3,D1
         BLE      SF_CPFNM
         BRA      SF_CLRFN
SF_SAVFL MOVEM.L  D2/D4,-(A7)
         BSR      TX_FILE
         MOVEM.L  (A7)+,D1/D4
         TST.L    D0
         BNE      SF_ERROR
         CMPI.B   #'#',D1
         BEQ.S    SF_TRUNC
         CMPI.B   #'^',D1
         BNE.S    SF_MARK
         MOVEQ    #-1,D1
         LEA      FNAMBUF(A6),A0
         QDOS     IO.DELET
         LEA      FNAMBUF(A6),A0
         LEA      LOGBUF(A6),A1
         WRITE$
         WRITE$   {' deleted',0}
         JSR      LOG0
         BRA.S    SF_MARK
SF_TRUNC MOVEQ    #-1,D1
         MOVEQ    #IO.OVER,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    SF_MARK
         MOVEQ    #-1,D3
         QDOS     FS.TRUNC
         QDOS     IO.CLOSE
         LEA      FNAMBUF(A6),A0
         LEA      LOGBUF(A6),A1
         WRITE$
         WRITE$   {' truncated',0}
         JSR      LOG0

* Mark file as sent in _ATT

SF_MARK  MOVEQ    #0,D1
         MOVEQ    #-1,D3
         MOVE.L   DIRCHAN(A6),A0
         QDOS     FS.POSRE          Remember current pos
         EXG      D1,D4
         QDOS     FS.POSAB          Go back to last file
         MOVEQ    #';',D1           "Comment out" this entry
         QDOS     IO.SBYTE
         EXG      D1,D4
         QDOS     FS.POSAB          Restore former position
         BRA      SF_NXTFL
SF_ENDFL MOVEQ    #0,D0
SF_ERROR MOVE.L   D0,-(A7)
         CLR.W    FNAMBUF(A6)
         BSR      TX_FILE
         JSR      DIRCLOSE
         MOVE.L   (A7)+,D0
         BNE.S    SF_END
         BSR      DEL_ATT
         MOVEQ    #0,D0
         BRA.S    SF_END
SF_NFILE CLR.W    FNAMBUF(A6)
         BSR      TX_FILE
SF_END   TST.L    D0
         RTS
SF_END1  MOVEQ    #1,D0
         RTS

* FTS-0001 receive session
* Exit: D1 prod. code; D2-D5 zone/net/node/point of remote system

RECV_FTS BSR      RND_PKT
         QDOS     MT.RCLCK
         MOVE.L   D1,D6
         MOVEQ    #C,D5
         MOVE.L   #1<<NOCLOSE+1<<XR..SKIP+1,D7
         BSR      SET1MIN
RF_PURGE BSR      PURGE
RF_C     MOVE.B   D5,D1
         JSR      TXCHAR
         MOVE.W   #5*50,D3
         BSR      GETCHR1
         BEQ.S    RF_SOH
         BLT      RF_FAIL
         QDOS     MT.RCLCK
         SUB.L    D6,D1
         CMPI.W   #25,D1
         BLT      RF_C
         MOVEQ    #NAK,D5
         CLR.B    D7
         BRA      RF_C
RF_SOH   CMPI.B   #SOH,D1
         BEQ.S    RF_RECV
         CMPI.B   #SYN,D1
         BNE      RF_PURGE
RF_RECV  LOG      {'Receiving mail packet',LF}
         LEA      S_INBND(A6),A1
         JSR      RX_CLINK
         BEQ.S    RF_GETNN
         CMPI.L   #XR.NOMOR,D0
         BEQ      RF_NNODE
         BRA      RF_END
RF_GETNN MOVEQ    #0,D1
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         QDOS     FS.POSAB
         MOVEQ    #PK_HDLEN,D2
         LEA      BUFFER(A6),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    RF_NNODE
         SUBA.W   D1,A1
         MOVE.W   PK_VERSN(A1),D0
         ROL.W    #8,D0
         CMPI.W   #PKTVERS,D0
         BNE.S    RF_NNODE
         MOVE.W   PK_ONODE(A1),D4
         ROL.W    #8,D4
         MOVE.W   PK_ONET(A1),D3
         ROL.W    #8,D3
         MOVEQ    #0,D1
         MOVE.B   PK_PRDCL(A1),D1
         MOVE.W   PK_CAPWD(A1),D0
         ROL.W    #8,D0
         CMP.W    PK_CAPVL(A1),D0
         BEQ.S    CAPWD_OK
         MOVEQ    #0,D0
CAPWD_OK BTST     #0,D0
         BNE.S    IS2PLUS
         CMPI.B   #FRODO,D1
         BEQ.S    IS2PLUS2
         CMPI.B   #DBRIDGE,D1
         BEQ.S    IS2PLUS2
         CMPI.B   #TOSSCAN,D1
         BEQ.S    IS2PLUS2
         CMPI.B   #XRS,D1
         BEQ.S    IS2PLUS2
         CMPI.B   #QMAIL,D1
         BEQ.S    IS_Q
         CMPI.B   #ZMAILQ,D3
         BEQ.S    IS_Q
         MOVEQ    #0,D2
         MOVEQ    #0,D5
         BRA.S    SET_ZP
IS2PLUS  MOVE.B   PK_PRDCH(A1),D0
         LSL.W    #8,D0
         OR.W     D0,D1
IS2PLUS2 MOVE.W   PK_OZONE(A1),D2
         MOVE.W   PK_OPNT(A1),D5
         BRA.S    SET_ZP
IS_Q     MOVE.W   PK_QOZON(A1),D2
         MOVEQ    #0,D5
SET_ZP   ROL.W    #8,D2
         ROL.W    #8,D5
         BRA.S    RF_FILES
RF_NNODE MOVEQ    #-1,D1
         MOVEQ    #0,D2
         MOVEQ    #0,D3
         MOVEQ    #0,D4
         MOVEQ    #0,D5
RF_FILES MOVEM.W  D1-D5,-(A7)
         JSR      FCLOSE
         LOG      {'Receiving files',LF}
         BSR      RX_BATCH
         MOVEM.W  (A7)+,D1-D5
         BRA.S    RF_END
RF_FAIL  LOG      {'? Unable to establish FTS-1 mail session',LF}
         MOVEQ    #-1,D0
RF_END   TST.L    D0
         RTS

DO_FREQ  JSR      OPEN_FRQ
         BNE      FRQ_END
FRQ_LOOP MOVEQ    #50,D2
         MOVEQ    #-1,D3
         MOVE.L   DIRCHAN(A6),A0
         LEA      BUFFER+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE      FRQ_DEL
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BLE      FRQ_LOOP
         MOVE.W   D1,-(A1)
         LEA      LOGBUF(A6),A1
         WRITE$   {'Requesting '},A1
         LEA      BUFFER(A6),A0
         WRITE$
         CLR.B    (A1)
         JSR      LOG0
         LEA      BUFFER(A6),A0
         LEA      XMODBUF(A6),A1
         MOVE.B   #ACK,(A1)+
         WRITE$
         MOVE.B   #' ',(A1)+
         MOVE.B   #'0',(A1)+
         MOVE.L   A1,D0
         LEA      XMODBUF+1(A6),A1
         SUB.L    A1,D0
         SUBQ.W   #1,D0
         JSR      CALCCRC
         MOVE.B   #ETX,(A1)+
         MOVE.B   D3,(A1)+
         LSR.W    #8,D3
         MOVE.B   D3,(A1)+
         MOVE.L   A1,D2
         SUB.L    A6,D2
         SUBI.W   #XMODBUF,D2
         BSR      SET1MIN
FRQ_SBLK MOVEQ    #SP.SSTRG,D0
         LEA      XMODBUF(A6),A1
         JSR      DO_OUTP
         JSR      FLUSH
FRQ_WTAK MOVE.W   #60*50,D3
         BSR      GETCHR2
         BNE.S    FRQ_ERR
         CMPI.B   #ACK,D1
         BNE      FRQ_SBLK
FRQ_RECV BSR      RX_BATCH
         BNE.S    FRQ_ERR
         BSR      SET1MIN
FRQ_ENQ  MOVE.W   #60*50,D3
         BSR      GETCHR2
         BNE.S    FRQ_ERR
         CMPI.B   #ENQ,D1
         BEQ      FRQ_LOOP
         CMPI.B   #CAN,D1
         BNE      FRQ_ENQ
         LOG      {'Request refused',LF}
FRQ_ERR  LOG      {'Request failed',LF}
         JSR      DIRCLOSE
         BRA.S    FRQ_END
FRQ_DEL  JSR      DIRCLOSE
         BSR      DEL_FRQ
FRQ_END  MOVEQ    #ETB,D1
         JSR      TXCHAR
         RTS

* Write error message D0 at (A1)

         XDEF     WRITEERR

WRITEERR MOVEM.L  D0/A0,-(A7)
         TST.L    D0
         BGE.S    WS_RTS
         ADD.L    D0,D0
         BVC.S    WE_SYSER
         LSR.L    #1,D0
         MOVE.L   D0,A0
         BRA.S    WRITESTR
WE_SYSER NEG.W    D0
         LEA      ERRTAB,A0
         ADDA.W   (A0,D0.W),A0
WRITESTR WRITE$
WS_RTS   MOVEM.L  (A7)+,D0/A0
         RTS

         SECTION  MSG

ERRTAB   DC.W     0
         DC.W     ERR1-ERRTAB
         DC.W     ERR2-ERRTAB
         DC.W     ERR3-ERRTAB
         DC.W     ERR4-ERRTAB
         DC.W     ERR5-ERRTAB
         DC.W     ERR6-ERRTAB
         DC.W     ERR7-ERRTAB
         DC.W     ERR8-ERRTAB
         DC.W     ERR9-ERRTAB
         DC.W     ERR10-ERRTAB
         DC.W     ERR11-ERRTAB
         DC.W     ERR12-ERRTAB
         DC.W     ERR13-ERRTAB
         DC.W     ERR14-ERRTAB
         DC.W     ERR15-ERRTAB
         DC.W     ERR16-ERRTAB
         DC.W     ERR17-ERRTAB
         DC.W     ERR18-ERRTAB
         DC.W     ERR19-ERRTAB
         DC.W     ERR20-ERRTAB
         DC.W     ERR21-ERRTAB

ERR1     STRING$  {'not complete',LF}
ERR2     STRING$  {'invalid job',LF}
ERR3     STRING$  {'out of memory',LF}
ERR4     STRING$  {'out of range',LF}
ERR5     STRING$  {'buffer full',LF}
ERR6     STRING$  {'channel not open',LF}
ERR7     STRING$  {'not found',LF}
ERR8     STRING$  {'already exists',LF}
ERR9     STRING$  {'in use',LF}
ERR10    STRING$  {'end of file',LF}
ERR11    STRING$  {'drive full',LF}
ERR12    STRING$  {'bad name',LF}
ERR13    STRING$  {'Xmit error',LF}
ERR14    STRING$  {'format failed',LF}
ERR15    STRING$  {'bad parameter',LF}
ERR16    STRING$  {'bad or changed medium',LF}
ERR17    STRING$  {'error in expression',LF}
ERR18    STRING$  {'overflow',LF}
ERR19    STRING$  {'not implemented',LF}
ERR20    STRING$  {'read only',LF}
ERR21    STRING$  {'bad line',LF}

         SECTION  CODE

         XDEF     PROGRESS

PROGRESS MOVEM.L  D1-D3/A0-A1,-(A7)
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEM.L  (A7)+,D1-D3/A0-A1
         TST.L    D0
         RTS

RX_BATCH CLR.W    FILENAME(A6)
         MOVE.W   #1<<XR..SKIP+1,D7
         LOAD$    {'Synchronising with sender',LF},A1
         BSR      PROGRESS
         MOVEQ    #20,D2
         MOVEQ    #10,D1
         BSR      SETTIMER
         BSR      PURGE0
RB_TXC   MOVEQ    #C,D1
         JSR      TXCHAR
         MOVEQ    #2*50,D3
         BSR      GETCHR1
         BGT      RB_TXC
         BLT.S    RB_NAK
         TST.B    D1
         BEQ      RB_NULL
         CMPI.B   #EOT,D1
         BEQ      RB_NOMOR
         CMPI.B   #SUB,D1
         BEQ      RB_NOMOR
         CMPI.B   #SOH,D1
         BEQ      RB_RXTEL
         CMPI.B   #SYN,D1
         BEQ      RB_RXTEL
         CMPI.B   #ACK,D1
         BEQ.S    RB_M7REC
         BSR      PURGE
         BRA      RB_TXC
RB_NAK   BSR      SET1MIN
         BSR      PURGE0
RB_TXNAK MOVEQ    #NAK,D1
         JSR      TXCHAR
         MOVE.W   #5*50,D3
         BSR      GETCHR1
         BGT.S    RB_TNNXT
         BLT      RB_END
         TST.B    D1
         BEQ.S    RB_NULL
         CMPI.B   #EOT,D1
         BEQ      RB_NOMOR
         CMPI.B   #SUB,D1
         BEQ      RB_NOMOR
         CMPI.B   #SOH,D1
         BEQ      RB_RXTEL
         CMPI.B   #SYN,D1
         BEQ      RB_RXTEL
         CMPI.B   #ACK,D1
         BEQ.S    RB_NFRST
         BSR      PURGE
RB_TNNXT SUBQ.B   #1,D2
         BGT      RB_TXNAK
         LOG      {'? MODEM7 receive failed',LF}
         MOVEQ    #XR.FAIL,D0
         BRA      RB_END
RB_NULL  LOAD$    {'Remote requested more time',LF}
         BSR      PROGRESS
         MOVEQ    #20,D1
         BSR      SETTIMER
         BRA      RB_TXC
RB_M7REC BSR      SET1MIN
RB_NFRST LOAD$    {'Receiving MODEM7 file name',LF}
         BSR      PROGRESS
         LEA      FILENAME(A6),A2
         CLR.W    (A2)+
         MOVEQ    #0,D4
         MOVEQ    #9,D5
RB_WTCHR MOVEQ    #50,D3
         BSR      GETCHR1
         BNE      RB_TNNXT
         CMPI.B   #'u',D1
         BEQ      RB_TNNXT
         ADD.B    D1,D4
         CMPI.B   #SUB,D1
         BEQ.S    RB_TXCHK
         SUBQ.B   #1,D5
         BNE.S    RB_ST_CH
         MOVE.B   #'.',(A2)+
         ADDQ.W   #1,FILENAME(A6)
RB_ST_CH CMPI.B   #' ',D1
         BEQ.S    RB_TXACK
         MOVE.B   D1,(A2)+
         ADDQ.W   #1,FILENAME(A6)
RB_TXACK BSR      PURGE0
         MOVEQ    #ACK,D1
         JSR      TXCHAR
         BRA      RB_WTCHR
RB_TXCHK BSR      PURGE0
         MOVE.B   D4,D1
         JSR      TXCHAR
         MOVEQ    #50,D3
         BSR      GETCHR1
         BNE      RB_TNNXT
         CMPI.B   #ACK,D1
         BNE      RB_TNNXT
         CMPI.B   #'.',-1(A2)
         BNE.S    RB_NAME
         SUBQ.W   #1,FILENAME(A6)
RB_NAME  MOVEQ    #1,D7
RB_RXTEL LEA      S_INBND(A6),A1
         BSR      RX_CLINK
         BEQ      RX_BATCH
RB_END   LOG      {'? Batch receive failed',LF}
         TST.L    D0
         RTS
RB_NOMOR LOG      {'- Batch receive completed',LF}
         MOVEQ    #0,D0
         RTS

* Transmit file
* Entry: Full QDOS name in FNAMBUF (null if end-of-batch)
*        Transmit filename (excl device & directory) in FILENAME

TX_FILE  LEA      FNAMBUF(A6),A1
         TST.W    (A1)
         BNE.S    TB_ANAME

* End of batch, send EOT in response to C or NAK

*         XDEF     TB_END

TB_END   BSR      SET1MIN
TB_ENDP  MOVE.W   #60*50,D3
         BSR      GETCHR1
         BNE.S    TB_END2
         CMPI.B   #C,D1
         BEQ.S    TB_OK
         CMPI.B   #NAK,D1
         BNE      TB_ENDP
TB_OK    MOVEQ    #EOT,D1
         JSR      TXCHAR
         LOG      {'- Batch send completed',LF}
         MOVEQ    #XR.OK,D0
         RTS
TB_END2  MOVEQ    #EOT,D1
         JSR      TXCHAR
         LOG      {'? No NAK for end-of-batch',LF}
         MOVEQ    #XR.OK,D0
         RTS

* Try opening file

TB_ANAME MOVE.L   A1,A0
         MOVEQ    #-1,D1
         MOVEQ    #IO.SHARE,D3
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    TB_HEADR
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Can''t open '}
         LEA      FNAMBUF(A6),A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         BSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
         MOVEQ    #ERR.NF,D0
         RTS
TB_HEADR MOVE.L   A0,INPCHAN(A6)
         LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D0
         CLR.B    (A1,D0.W)
         LEA      XMODBUF(A6),A2
         MOVEQ    #7,D2

* Construct MODEM7 file name in XMODBUF

M7_NAMLP MOVE.B   (A1),D1
         BEQ.S    M7_NAMSP
         CMPI.B   #'.',D1
         BEQ.S    M7_NAMSP
         ADDQ.W   #1,A1
         JSR      TOUPPER
         BRA.S    M7_STO1
M7_NAMSP MOVEQ    #' ',D1
M7_STO1  MOVE.B   D1,(A2)+
         DBF      D2,M7_NAMLP
         MOVEQ    #2,D2
         CMPI.B   #'.',(A1)
         BNE.S    M7_EXTLP
         ADDQ.W   #1,A1
M7_EXTLP MOVE.B   (A1),D1
         BEQ.S    M7_EXTSP
         ADDQ.W   #1,A1
         JSR      TOUPPER
         BRA.S    M7_STO2
M7_EXTSP MOVEQ    #' ',D1
M7_STO2  MOVE.B   D1,(A2)+
         DBF      D2,M7_EXTLP

* Transmit MODEM7 file name

         LOAD$    {'Waiting for receiver',LF}
         BSR      PROGRESS
         MOVEQ    #1,D6
         MOVE.W   #1<<WANT_C+1<<XR..SKIP+1,D7
         BSR      SET1MIN
M7_WTNAK MOVE.W   #60*50,D3
         BSR      GETCHR1
         BNE      TB_NFAIL
         CMPI.B   #C,D1
         BEQ.S    TB_TXTEL
         CMPI.B   #NAK,D1
         BNE      M7_WTNAK
         LOAD$    {'Sending MODEM7 file name',LF}
         BSR      PROGRESS
         MOVEQ    #ACK,D1
         JSR      TXCHAR
         MOVEQ    #10,D2
         MOVEQ    #SUB,D4
         LEA      XMODBUF(A6),A2
M7_TXCHR BSR      PURGE0
         MOVE.B   (A2)+,D1
         ADD.B    D1,D4
         JSR      TXCHAR
         MOVEQ    #50,D3
         BSR      GETCHR1
         BNE.S    M7_AGAIN
         CMPI.B   #ACK,D1
         BNE.S    M7_AGAIN
         DBF      D2,M7_TXCHR
         BSR      PURGE0
         MOVEQ    #SUB,D1
         JSR      TXCHAR
         MOVEQ    #50,D3
         BSR      GETCHR1
         BNE.S    M7_AGAIN
         CMP.B    D4,D1
         BEQ.S    M7_TXOK
         LOAD$    {'MODEM7 filename checksum error',LF}
         BSR      PROGRESS
M7_AGAIN ADDQ.B   #1,D6
         CMPI.B   #20,D6
         BGT.S    TB_NFAIL
         BSR.S    PURGE0
         MOVEQ    #'u',D1
         JSR      TXCHAR
         BRA      M7_WTNAK
M7_TXOK  MOVEQ    #ACK,D1
         JSR      TXCHAR
         MOVE.W   #1<<WANT_C+1,D7
TB_TXTEL JSR      TX_CLINK
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         MOVE.L   (A7)+,D0
         RTS
TB_NFAIL LOG      {'? Unable to send MODEM7 file name',LF}
         JSR      FCLOSE
         MOVEQ    #XR.NSERR,D0
         RTS

DEL_PKT  MOVE.L   #'_PKT',-(A7)
         BRA.S    TIDY_2
DEL_ATT  MOVE.L   #'_ATT',-(A7)
         BRA.S    TIDY_2
DEL_FRQ  MOVE.L   #'_FRQ',-(A7)
TIDY_2   MOVEM.W  DESTZONE(A6),D2-D5
         BSR      REMAP3D
         BSR      ZNN_TO_H
         MOVE.L   (A7)+,(A1)+
         LEA      BUFFER(A6),A0
         LEA      S_OUTBND(A6),A1
         JSR      MKFNAME
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         RTS

         XDEF     PURGE,PURGE0,PURGE_LP

PURGE0   MOVEQ    #0,D3
         BRA.S    PURGE_LP
PURGE    MOVEQ    #50,D3
PURGE_LP MOVEQ    #SP.FBYTE,D0
         JSR      DO_INP
         BEQ      PURGE_LP
         RTS

         XDEF     GETCHR1,GETCHR2

GETCHR2  MOVE.L   D3,-(A7)
         BSR      PURGE0
         MOVE.L   (A7)+,D3
GETCHR1  BSR      CHKTIMER
         BNE.S    GC2_TIMO
         MOVEQ    #SP.FBYTE,D0
         JSR      DO_INP
         BEQ.S    GC1_END
         ADDQ.L   #1,D0
         BEQ.S    GC1_NC
         SUBQ.L   #1,D0
GC1_END  RTS
GC1_NC   MOVEQ    #1,D0
         RTS
GC2_TIMO MOVEQ    #-1,D0
         RTS

         XDEF     TEST_CAN

TEST_CAN CMPI.B   #CAN,D1
         BNE.S    TC_END
         MOVEQ    #SP.FBYTE,D0
         MOVEQ    #50,D3
         JSR      DO_INP
         BNE.S    TC_NC
         CMPI.B   #CAN,D1
TC_END   RTS
TC_NC    MOVEQ    #-1,D1
         RTS

         END
