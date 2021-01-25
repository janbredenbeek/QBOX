* SCANMAIL - ARChive routines

         INCLUDE  FLP1_QDOS_IN_MAC

CR       EQU      $0D
LF       EQU      $0A
DLE      EQU      $90
ARCMARK  EQU      $1A
ARCTYPE  EQU      8
MINCDSIZ EQU      9
MAXCDSIZ EQU      12
CLR      EQU      256
FIRSTENT EQU      257
TBLSIZE  EQU      4096
INPBUFSZ EQU      1024
CHECKGAP EQU      10000
NOHIST   EQU      0
SENTCHAR EQU      2
SENDNEWC EQU      4
SENDCNT  EQU      6

         OFFSET   0

H_TYPE   DS.B     1                 Compression type (0 = EOF)
H_NAME   DS.B     13                File name (NULL terminated)
H_SIZE   DS.L     1                 Compressed size
H_DATE   DS.W     1                 Date (DOS format)
H_TIME   DS.W     1                 Time (DOS format)
H_CRC    DS.W     1                 CRC
H_LENGTH DS.L     1                 Uncompressed size
H_LEN    EQU      *
ARCPOS   DS.L     1
INPBFPOS DS.L     1
INPBFLEN DS.W     1
CURR_ENT DS.W     1
FREE_ENT DS.W     1
CHECKLEN DS.W     1
CHECKOPT DS.W     1
CODESIZE DS.W     1
OUTBFPOS DS.W     1
OUTBUF   DS.B     12
INPBUF   DS.B     INPBUFSZ
CHILD    DS.W     TBLSIZE
SIBLING  DS.W     TBLSIZE
SUFFIX   DS.B     TBLSIZE
HEAPSIZE EQU      *

         XDEF     COMP_ALL

         XREF     GETDATE,TOUPPER,LD_LONG,OPEN_2,OPEN_3,MKFNAME,ITOD_W
         XREF.S   BUFFER,DESTDIR,MYZONE,MYNET,MYNODE,MYPOINT,PNTNET
         XREF.S   TEMPDIR,DESTDIR,TDIRCHAN,INPCHAN,OUTCHAN,ERR_SP,BUFFER2

         SECTION  MSG

         DS.W     0
DAYTBL   DC.B     'SUMOTUWETHFRSA'

         SECTION  CODE

ZNN_TO_H MOVE.L   D1,-(A7)
         MOVE.W   D2,D1
         BSR.S    ITOH_W
         MOVE.L   (A7)+,D1
NN_TO_H  SWAP     D1
         BSR.S    ITOH_W
         SWAP     D1
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

HTOI_L   MOVEQ    #7,D2
         MOVEQ    #0,D0
HTOI_LP  MOVE.B   (A1)+,D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BLS.S    HTOI_2
         SUBI.B   #'A'-'0',D0
         CMPI.B   #'F'-'A',D0
         BHI.S    HTOI_ERR
         ADDI.B   #10,D0
HTOI_2   LSL.L    #4,D1
         OR.B     D0,D1
         DBF      D2,HTOI_LP
         MOVEQ    #0,D0
         RTS
HTOI_ERR MOVEQ    #ERR.XP,D0
         RTS

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
         BEQ.S    IO_OK
IO_ERROR MOVE.L   ERR_SP(A6),A7
IO_OK    RTS

SKIP_ARC MOVEQ    #-1,D3
         MOVE.L   OUTCHAN(A6),A0
         QDOS     IO.PEND
         CMPI.L   #ERR.EF,D0
         BEQ.S    IO_OK
         BSR      FBYTE
         MOVEQ    #ERR.FF,D0
         CMPI.B   #ARCMARK,D1
         BNE      IO_ERROR
         BSR      FBYTE
         LEA      H_TYPE(A5),A1
         MOVE.B   D1,(A1)+
         BEQ.S    GH_END
         MOVEQ    #H_LEN-1,D2
         SUBQ.B   #1,D1
         BNE.S    GH_2
         SUBQ.W   #4,D2
GH_2     BSR      FSTRG
         MOVE.L   H_SIZE(A5),D1
         ROL.W    #8,D1
         SWAP     D1
         ROL.W    #8,D1
         QDOS     FS.POSRE
         BRA      SKIP_ARC
GH_END   MOVEQ    #-2,D1
         QDOS     FS.POSRE
         RTS

GETBYTE  SUBQ.W   #1,INPBFLEN(A5)
         BLT.S    GB_NBUF
         MOVE.L   INPBFPOS(A5),A1
         MOVEQ    #0,D1
         MOVE.B   (A1)+,D1
         MOVE.L   A1,INPBFPOS(A5)
         MOVEQ    #0,D0
         MOVE.B   H_CRC+1(A5),D0
         EOR.B    D1,D0
         ADD.W    D0,D0
         LEA      CRC_TBL,A1
         MOVE.W   (A1,D0.W),D2
         MOVE.B   H_CRC(A5),D0
         EOR.B    D0,D2
         MOVE.W   D2,H_CRC(A5)
         RTS
GB_NBUF  MOVE.W   #INPBUFSZ,D2
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         LEA      INPBUF(A5),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BEQ.S    GB_NBUF2
         CMPI.L   #ERR.EF,D0
         BNE      IO_ERROR
         TST.W    D1
         BEQ.S    GB_EOF
GB_NBUF2 SUBA.W   D1,A1
         MOVE.W   D1,INPBFLEN(A5)
         MOVE.L   A1,INPBFPOS(A5)
         BRA      GETBYTE
GB_EOF   MOVEQ    #-1,D1
         RTS

PUTCODE  MOVEM.L  D1-D2/A1,-(A7)
         MOVEQ    #0,D1
         MOVE.W   D2,D1
         MOVE.W   OUTBFPOS(A5),D0
         MULU     CODESIZE(A5),D0
         MOVEQ    #7,D2
         AND.B    D0,D2
         LSL.L    D2,D1
         ADD.W    CODESIZE(A5),D2
         LSR.W    #3,D0
         LEA      OUTBUF(A5,D0.W),A1
PC_LOOP  OR.B     D1,(A1)+
         LSR.L    #8,D1
         SUBQ.W   #8,D2
         BGT      PC_LOOP
         ADDQ.W   #1,OUTBFPOS(A5)
         CMPI.W   #8,OUTBFPOS(A5)
         BLT.S    PC_END
         BSR.S    FLUSH_OP
PC_END   MOVEM.L  (A7)+,D1-D2/A1
         RTS

FLUSH_OP TST.W    OUTBFPOS(A5)
         BEQ.S    FL_END
         MOVEM.L  D1-D3/A0-A1,-(A7)
         MOVEQ    #0,D2
         MOVE.W   CODESIZE(A5),D2
         ADD.L    D2,H_SIZE(A5)
         ADD.W    D2,CHECKLEN(A5)
         MOVE.L   OUTCHAN(A6),A0
         LEA      OUTBUF(A5),A1
         BSR      SSTRG
         SUBA.W   D1,A1
         CLR.L    (A1)+
         CLR.L    (A1)+
         CLR.L    (A1)+
         CLR.W    OUTBFPOS(A5)
         MOVEM.L  (A7)+,D1-D3/A0-A1
FL_END   RTS

COMP_ALL MOVE.L   #HEAPSIZE,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE      COMP_END
         MOVE.L   A0,A5
         MOVEQ    #IO.DIR,D3
         LEA      TEMPDIR(A6),A0
         JSR      OPEN_3
         BNE      COMP_END
         MOVE.L   A0,TDIRCHAN(A6)
CA_NEXT  MOVE.L   TDIRCHAN(A6),A0
         LEA      BUFFER(A6),A1
         LEA      TEMPDIR(A6),A2
         BSR      READDIR
         BNE      COMP_OK
         CMPI.W   #12,D1
         BNE      CA_NEXT
         BSR      HTOI_L
         BNE      CA_NEXT
         MOVE.L   D1,D7
         JSR      LD_LONG
         CMPI.L   #'_PKT',D1
         BNE      CA_NEXT
         LEA      BUFFER2(A6),A1
         MOVE.W   #12,(A1)+
         MOVE.L   D7,D1
         BSR      NN_TO_H
         MOVE.L   #'_PKT',(A1)+
         MOVEQ    #IO.SHARE,D3
         LEA      BUFFER2(A6),A0
         LEA      TEMPDIR(A6),A1
         JSR      OPEN_2
         BNE      COMP_END
         MOVE.L   A0,INPCHAN(A6)
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         MOVEQ    #0,D4
         CMPI.L   #60,-(A1)
         BLE      CA_CLOSE
         MOVE.L   MYNET(A6),D6
         TST.W    MYPOINT(A6)
         BEQ.S    CA_NPNT
         MOVE.L   PNTNET(A6),D6
CA_NPNT  SUB.W    D7,D6
         SWAP     D6
         SWAP     D7
         SUB.W    D7,D6
         SWAP     D6
         SWAP     D7
         LEA      BUFFER2(A6),A1
         MOVE.W   #16,(A1)+
         MOVE.L   D7,D1
         MOVE.W   MYZONE(A6),D2
         BSR      ZNN_TO_H
         MOVE.L   #'_ATT',(A1)+
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER2(A6),A0
         LEA      DESTDIR(A6),A1
         JSR      OPEN_2
         BEQ.S    RD_ATT
         CMPI.L   #ERR.NF,D0
         BNE      COMP_END
         MOVEQ    #IO.NEW,D3
         LEA      BUFFER(A6),A0
         JSR      OPEN_3
         BNE      COMP_END
         BRA.S    CA_CTNEW
RD_ATT   MOVEQ    #48,D2
         MOVEQ    #-1,D3
         LEA      BUFFER+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    CA_CTNEW
         CMPI.W   #14,D1
         BLT      RD_ATT
         MOVE.W   D1,BUFFER(A6)
         CMPI.B   #';',BUFFER+2(A6)          ; Added in v1.01p 21/10/94
         BEQ      RD_ATT                     ;
         SUBA.W   #14,A1
         CMPI.B   #'_',(A1)+
         BNE      RD_ATT
         BSR      HTOI_L
         BNE      RD_ATT
         CMP.L    D6,D1
         BNE      RD_ATT
         CMPI.B   #'.',(A1)+
         BNE      RD_ATT
         MOVE.B   (A1)+,D1
         LSL.W    #8,D1
         MOVE.B   (A1)+,D1
         MOVEQ    #6,D0
         LEA      DAYTBL,A2
CHK_DAY  CMP.W    (A2)+,D1
         DBEQ     D0,CHK_DAY
         BNE      RD_ATT
         MOVE.B   (A1)+,D1
         SUBI.B   #'0',D1
         CMPI.B   #9,D1
         BHI      RD_ATT
         BRA      OPEN_ARC
CA_CTNEW MOVE.L   A0,A4
         QDOS     MT.RCLCK
         JSR      GETDATE
         SWAP     D0
         ADD.W    D0,D0
         LEA      DAYTBL,A0
         MOVEQ    #0,D4
         MOVE.W   (A0,D0.W),D4
         MOVEQ    #'0',D5
         MOVEQ    #IO.DIR,D3
         LEA      DESTDIR(A6),A0
         JSR      OPEN_3
         BNE      COMP_END
LOOKDEST LEA      BUFFER(A6),A1
         LEA      DESTDIR(A6),A2
         BSR      READDIR
         BNE.S    NEW_ARC
         CMPI.W   #12,D1
         BNE      LOOKDEST
         BSR      HTOI_L
         BNE      LOOKDEST
         CMP.L    D6,D1
         BNE      LOOKDEST
         JSR      LD_LONG
         MOVE.L   D1,-(A7)
         LEA      BUFFER2(A6),A1
         MOVE.W   #12,(A1)+
         MOVE.L   D6,D1
         BSR      NN_TO_H
         MOVE.L   (A7)+,D1
         MOVE.L   D1,(A1)+
         ROR.L    #8,D1
         CMP.W    D4,D1
         BNE.S    CA_DEL
         ROL.L    #8,D1
         MOVE.B   D1,D5
         ADDQ.B   #1,D5
CA_DEL   MOVE.L   A0,-(A7)
         LEA      BUFFER2(A6),A0
         LEA      DESTDIR(A6),A1
         JSR      MKFNAME
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         MOVE.L   (A7)+,A0
NEW_ARC  QDOS     IO.CLOSE
         LEA      BUFFER2(A6),A1
         MOVE.W   #13,(A1)+
         MOVE.L   D6,D1
         BSR      NN_TO_H
         SWAP     D4
         MOVE.B   #'.',D4
         ROR.L    #8,D4
         OR.L     D4,D5
         MOVE.L   D5,(A1)+
         MOVE.B   #LF,(A1)+
         LEA      BUFFER2(A6),A0
         LEA      DESTDIR(A6),A1
         JSR      MKFNAME
         MOVE.L   A0,-(A7)
         MOVEQ    #'#',D1
         MOVEQ    #-1,D3
         MOVE.L   A4,A0
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      COMP_END
OPEN_ARC QDOS     IO.CLOSE
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER(A6),A0
         SUBQ.W   #1,(A0)
         CMPI.B   #'#',2(A0)
         BNE.S    OA_2
         SUBQ.W   #1,(A0)
         MOVE.W   (A0)+,D0
OA_1     MOVE.B   1(A0),(A0)+
         SUBQ.W   #1,D0
         BGT      OA_1
         LEA      BUFFER(A6),A0
OA_2     JSR      OPEN_3
         BEQ.S    STDESTCH
         CMPI.L   #ERR.NF,D0
         BNE.S    COMP_END
         MOVEQ    #IO.NEW,D3
         LEA      BUFFER(A6),A0
         JSR      OPEN_3
         BNE.S    COMP_END
STDESTCH MOVE.L   A0,OUTCHAN(A6)
         MOVEM.L  D5-D7,-(A7)
         BSR.S    COMPRESS
         MOVEM.L  (A7)+,D5-D7
         MOVE.L   D0,D4
         MOVE.L   OUTCHAN(A6),A0
         QDOS     IO.CLOSE
CA_CLOSE MOVE.L   INPCHAN(A6),A0
         QDOS     IO.CLOSE
         LEA      BUFFER2(A6),A1
         MOVE.W   #12,(A1)+
         TST.L    D4
         BEQ.S    ARCH_OK
         MOVE.L   D6,D1
         BSR      NN_TO_H
         MOVE.L   D5,(A1)+
         LEA      DESTDIR(A6),A1
         BRA.S    ARCH_DEL
ARCH_OK  MOVE.L   D7,D1
         BSR      NN_TO_H
         MOVE.L   #'_PKT',(A1)+
         LEA      TEMPDIR(A6),A1
ARCH_DEL LEA      BUFFER2(A6),A0
         JSR      MKFNAME
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         MOVE.L   D4,D0
         BEQ      CA_NEXT
         BRA.S    COMP_END
COMP_OK  MOVEQ    #0,D0
COMP_END TST.L    D0
         RTS

COMPRESS MOVE.L   A7,ERR_SP(A6)
         QDOS     MT.RCLCK
         JSR      GETDATE
         MOVEM.L  D2-D3,-(A7)
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         LEA      BUFFER2(A6),A1
         JSR      ITOD_W
         MOVE.L   (A7)+,D1
         SWAP     D1
         JSR      ITOD_W
         MOVE.L   (A7)+,D1
         JSR      ITOD_W
         SWAP     D1
         JSR      ITOD_W
         MOVE.L   #'.PKT',(A1)+
         BSR      SKIP_ARC
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         ADDQ.L   #1,D1
         MOVE.L   D1,ARCPOS(A5)
         LEA      H_TYPE(A5),A2
         MOVE.B   #ARCTYPE,(A2)+
         MOVEQ    #12,D0
         LEA      BUFFER2(A6),A1
ARC_NAME MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D0
         BGT      ARC_NAME
         CLR.B    (A2)+
         CLR.L    (A2)+
         MOVEQ    #64,D2
         MOVE.L   INPCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         MOVE.L   BUFFER+$34(A6),D1
         JSR      GETDATE
         ADDQ.W   #1,D0
         ROL.W    #5,D0
         SUBI.W   #1980,D2
         ROR.W    #7,D2
         OR.W     D0,D1
         OR.W     D2,D1
         MOVE.W   D1,(A2)+
         SWAP     D2
         MOVE.W   D3,D1
         SWAP     D3
         ROL.W    #5,D1
         ROR.W    #5,D2
         LSR.W    #1,D3
         OR.W     D2,D1
         OR.W     D3,D1
         MOVE.W   D1,(A2)+
         CLR.W    (A2)+
         MOVE.L   BUFFER(A6),(A2)+
         MOVE.L   OUTCHAN(A6),A0
         MOVEQ    #ARCMARK,D1
         BSR      SBYTE
         MOVEQ    #H_LEN,D2
         LEA      H_TYPE(A5),A1
         BSR      SSTRG
         MOVEQ    #MAXCDSIZ,D1
         BSR      SBYTE
         ADDQ.L   #1,H_SIZE(A5)
         CLR.W    INPBFLEN(A5)
         CLR.W    OUTBFPOS(A5)
         LEA      OUTBUF(A5),A1
         CLR.L    (A1)+
         CLR.L    (A1)+
         CLR.L    (A1)+
         MOVE.W   #-1,CURR_ENT(A5)
         BSR      INIT_LZW
         MOVEQ    #NOHIST,D7
         LEA      CHILD(A5),A4
         LEA      SIBLING(A5),A3
         LEA      SUFFIX(A5),A2
COMP_LP  BSR.S    GET_PACK
         TST.W    D1
         BLT.S    COMP_EOF
         BSR      PUT_CRUN
         BRA      COMP_LP
COMP_EOF MOVE.W   CURR_ENT(A5),D2
         BSR      PUTCODE
         MOVE.W   OUTBFPOS(A5),D2
         MULU     CODESIZE(A5),D2
         ADDQ.W   #7,D2
         LSR.W    #3,D2
         ADD.L    D2,H_SIZE(A5)
         MOVE.L   OUTCHAN(A6),A0
         LEA      OUTBUF(A5),A1
         BSR      SSTRG
         MOVEQ    #ARCMARK,D1
         BSR      SBYTE
         MOVEQ    #0,D1
         BSR      SBYTE
         MOVE.L   ARCPOS(A5),D1
         QDOS     FS.POSAB
         LEA      H_SIZE(A5),A1
         BSR.S    SWAP_L
         BSR.S    SWAP_W
         BSR.S    SWAP_W
         BSR.S    SWAP_W
         BSR.S    SWAP_L
         MOVEQ    #H_LEN,D2
         LEA      H_TYPE(A5),A1
         BSR      SSTRG
         MOVEQ    #0,D0
         RTS

SWAP_W   MOVE.W   (A1),D0
         ROL.W    #8,D0
         MOVE.W   D0,(A1)+
         RTS
SWAP_L   MOVE.L   (A1),D0
         ROL.W    #8,D0
         SWAP     D0
         ROL.W    #8,D0
         MOVE.L   D0,(A1)+
         RTS

GET_PACK MOVE.W   STAT_TBL(PC,D7.W),D0
         JMP      STAT_TBL(PC,D0.W)

STAT_TBL DC.W     LNOHIST-STAT_TBL
         DC.W     LSENTCHR-STAT_TBL
         DC.W     LSNEWCHR-STAT_TBL
         DC.W     LSENDCNT-STAT_TBL

LNOHIST  BSR      GETBYTE
         MOVE.W   D1,D6
         MOVEQ    #SENTCHAR,D7
         RTS

LSENTCHR MOVE.W   D6,D1
         BLT.S    SC_EOF
         CMPI.W   #DLE,D6
         BNE.S    NOT_DLE
         MOVEQ    #0,D1
         MOVEQ    #NOHIST,D7
SC_EOF   RTS
NOT_DLE  MOVEQ    #1,D5
LOOK_REP BSR      GETBYTE
         CMP.W    D6,D1
         BNE.S    TEST_REP
         ADDQ.W   #1,D5
         CMPI.W   #255,D5
         BLO      LOOK_REP
TEST_REP MOVE.W   D5,D0
         SUBQ.W   #1,D0
         BNE.S    IS_REP
         MOVE.W   D1,D6
         RTS
IS_REP   EXG      D1,D6
         SUBQ.W   #1,D0
         BEQ.S    REP_END
         MOVE.W   #DLE,D1
         MOVEQ    #SENDCNT,D7
         RTS

LSNEWCHR MOVE.W   D6,D1
         MOVEQ    #SENTCHAR,D7
         RTS

LSENDCNT MOVE.W   D5,D1
REP_END  MOVEQ    #SENDNEWC,D7
         RTS

INIT_LZW MOVEQ    #-1,D0
         MOVE.W   #TBLSIZE-1,D1
         LEA      CHILD(A5),A1
CLRTREE  MOVE.L   D0,(A1)+
         DBF      D1,CLRTREE
         MOVEQ    #0,D1
CLRTREE2 MOVE.B   D1,(A1)+
         ADDQ.B   #1,D1
         BNE      CLRTREE2
         MOVE.W   #FIRSTENT,FREE_ENT(A5)
         MOVE.W   #MINCDSIZ,CODESIZE(A5)
         MOVE.W   #CHECKGAP,D4
         MOVE.W   D4,CHECKOPT(A5)
         CLR.W    CHECKLEN(A5)
         RTS

PUT_CRUN SUBQ.W   #1,D4
         MOVE.W   CURR_ENT(A5),D2
         BLT.S    SET_CURR
         MOVE.W   D2,D0
         ADD.W    D0,D0
         LEA      (A4,D0.W),A1
         MOVE.W   (A1),D0
         BLT.S    CR_NOTFD
CR_LKSUF CMP.B    (A2,D0.W),D1
         BEQ.S    CR_FOUND
         ADD.W    D0,D0
         LEA      (A3,D0.W),A1
         MOVE.W   (A1),D0
         BGE      CR_LKSUF
CR_NOTFD BSR      PUTCODE
         MOVE.W   FREE_ENT(A5),D2
         CMPI.W   #TBLSIZE,D2
         BGE.S    SET_CURR
         ADDQ.W   #1,FREE_ENT(A5)
         MOVE.B   D1,(A2,D2.W)
         MOVE.W   D2,(A1)
         MOVE.W   D2,D0
         SUBQ.W   #1,D0
         AND.W    D2,D0
         BNE.S    SET_CURR
         BSR      FLUSH_OP
         ADDQ.W   #1,CODESIZE(A5)
SET_CURR MOVE.W   D1,CURR_ENT(A5)
         TST.W    D4
         BGT.S    CR_END
         MOVE.W   #CHECKGAP,D4
         MOVE.W   CHECKLEN(A5),D0
         CLR.W    CHECKLEN(A5)
         CMP.W    CHECKOPT(A5),D0
         BLS.S    UPD_OPT
         MOVE.W   #CLR,D2
         BSR      PUTCODE
         BSR      FLUSH_OP
         BRA      INIT_LZW
UPD_OPT  MOVE.W   D0,CHECKOPT(A5)
         RTS
CR_FOUND MOVE.W   D0,CURR_ENT(A5)
CR_END   RTS

         INCLUDE  FLP2_ARCCRC_IN

         SECTION  MSG
         DC.W     0

         END
