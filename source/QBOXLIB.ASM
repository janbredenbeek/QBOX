* QBOX LIBRARY ROUTINES

* MARCH 28, 1987

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         XREF     GETCHAR,DO_OUTP,TXCHAR,TXCRLF,TXSTR

         DATA     0

         SECTION  CODE

         XDEF     WRITE$,WRITEL$

WRITE$   SF       -(A7)
         BRA.S    WRITE2
WRITEL$  ST       -(A7)
WRITE2   MOVEM.L  D0/A0,-(A7)
         MOVE.L   14(A7),A0
         MOVE.W   (A0)+,D0
         TST.B    8(A7)
         BEQ.S    WRITE4
         MOVE.W   D0,(A1)+
         BRA.S    WRITE4
WRITE3   MOVE.B   (A0)+,(A1)+
WRITE4   DBF      D0,WRITE3
         MOVEM.L  (A7)+,D0/A0
         ADDQ.L   #2,A7
         MOVE.L   (A7)+,(A7)
         RTS

* Skip spaces at (A1). Return EQ if at end of line

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

* Get line input
* Entry: D2 buffer length, A1 buffer. GETLIN1: D1 existing line length
* Exit:  D0 error code, D1 line length, A1 past line

         XDEF     GETLINE,GETLIN1

GETLINE  MOVEQ    #0,D1
GETLIN1  MOVE.L   D4,-(A7)
         MOVE.W   D1,D4
GTLIN_LP CMP.W    D2,D4
         BGE.S    GTLIN_OV
         JSR      GETCHAR
         CMPI.B   #BS,D1
         BEQ.S    GTLIN_BS
         CMPI.B   #DEL,D1
         BEQ.S    GTLIN_BS
         CMPI.B   #CR,D1
         BEQ.S    GTLIN_CR
         CMPI.B   #$20,D1
         BLT      GTLIN_LP
         MOVE.B   D1,(A1)+
         ADDQ.W   #1,D4
         TST.B    ECHOPNT(A6)
         IF NE THEN
            MOVEQ    #'*',D1
         ENDIF
         JSR      TXCHAR
         BRA      GTLIN_LP
GTLIN_BS TST.W    D4
         BEQ      GTLIN_LP
         MOVEQ    #8,D1
         JSR      TXCHAR
         MOVEQ    #' ',D1
         JSR      TXCHAR
         MOVEQ    #8,D1
         JSR      TXCHAR
         SUBQ.W   #1,A1
         SUBQ.W   #1,D4
         BRA      GTLIN_LP
GTLIN_CR MOVE.B   #CR,(A1)+
         ADDQ.W   #1,D4
         JSR      TXCRLF
         MOVEQ    #0,D0
         BRA.S    GTLIN_EN
GTLIN_OV MOVEQ    #ERR.BO,D0
GTLIN_EN MOVE.W   D4,D1
         MOVE.L   (A7)+,D4
         TST.L    D0
         RTS

* Get prompted input
* Entry: D2 buffer length, A0 prompt string, A1 buffer
* Exit:  D1 line length, A1 preserved

         XDEF     INPUT

INPUT    MOVE.L   A1,-(A7)
         MOVE.L   A0,D0
         IF NE THEN
            MOVE.L   A0,A1
            JSR      TXSTR
            MOVE.L   (A7),A1
         ENDIF
         MOVEQ    #0,D1
IN_AGAIN BSR      GETLIN1
         BEQ.S    INP_END
         SUBQ.W   #1,D1
         SUBQ.W   #1,A1
         MOVE.L   A1,-(A7)
         TXSTR    {BS,' ',BS,BELL}
         MOVE.L   (A7)+,A1
         BRA      IN_AGAIN
INP_END  MOVE.L   (A7)+,A1
         RTS

* Get name string (capitalised by routine)
* GETNAM1: Only 1 word allowed, GETNAM2: Two or more words allowed
* Entry: D0 <>0 if no empty input allowed, D2 max. length
* Exit: A1 ptr to BUFFER(A6), D1 name length, D0.L = LT if more than 1 word

         XDEF     GETNAM1,GETNAM2

GETNAM1  MOVE.L   D4,-(A7)
         MOVEQ    #0,D4
         BRA.S    GETNAM3
GETNAM2  MOVE.L   D4,-(A7)
         MOVEQ    #1,D4
GETNAM3  MOVEM.L  D0/D2/D4/A0,-(A7)
GTNAM_AG MOVEM.L  4(A7),D2/D4/A0
         ADDQ.W   #1,D2
         LEA      BUFFER+1(A6),A1
         BSR      INPUT
         LEA      BUFFER(A6),A0
GT2NDNAM BSR      SKIPSPC
         BEQ.S    GTNAM_EN
         MOVE.B   (A1)+,D1
         BSR      TOUPPER
         MOVE.B   #' ',(A0)+
         MOVE.B   D1,(A0)+
GETNAMLP MOVE.B   (A1)+,D1
         CMPI.B   #CR,D1
         BEQ.S    GTNAM_EN
         CMPI.B   #' ',D1
         BNE.S    GN_NOSPC
         BSR      SKIPSPC
         BEQ.S    GTNAM_EN
         BSET     #31,D4
         BRA      GT2NDNAM
GN_NOSPC CMPI.B   #'A',D1
         BLO.S    GN_STORE
         CMPI.B   #'Z',D1
         BHI.S    GN_STORE
         ADDI.B   #'a'-'A',D1
GN_STORE MOVE.B   D1,(A0)+
         BRA      GETNAMLP
GTNAM_EN LEA      BUFFER(A6),A1
         MOVE.L   A0,D1
         SUB.L    A1,D1
         SUBQ.W   #1,D1
         BGT.S    GN_NONUL
         TST.B    3(A7)
         BNE.S    GN_NOINP
         MOVEQ    #0,D1
GN_NONUL MOVE.B   D1,(A1)
         MOVE.L   D4,D0
         BGE.S    GTNAM_OK
         TST.B    D0
         BEQ.S    GN_1WORD
GTNAM_OK ADDQ.W   #4,A7
         MOVEM.L  (A7)+,D2/D4/A0
         MOVE.L   (A7)+,D4
         TST.W    D1
         RTS
GN_NOINP LOAD$    {'Please respond!',CR,LF}
         BRA.S    GTNAMREP
GN_1WORD LOAD$    {'Must be only one word!',CR,LF}
GTNAMREP JSR      TXSTR
         BRA      GTNAM_AG

* Compare name (A1) against (A2)
* Exit: Z flag set if match, all regs preserved

         XDEF     CMPNAME

CMPNAME  MOVEM.L  D0-D2/A1-A2,-(A7)
         MOVEQ    #0,D0
         MOVEQ    #0,D1
         MOVEQ    #0,D2
         MOVE.B   (A1)+,D0
         CMP.B    (A2)+,D0
         BRA.S    CMPNAM_N
CMPNAMLP MOVE.B   (A1)+,D1
         MOVE.B   UCASETBL(PC,D1.W),D1
         MOVE.B   (A2)+,D2
         CMP.B    UCASETBL(PC,D2.W),D1
CMPNAM_N DBNE     D0,CMPNAMLP
         MOVEM.L  (A7)+,D0-D2/A1-A2
         RTS

* Compare characters at (A1) against string (A0)
* Exit: Z flag set if match, D0/D1/A0 smashed
*       A1 preserved if no match, else advanced past string

         XDEF     COMPSTR

COMPSTR  MOVE.L   A1,-(A7)
         MOVE.W   (A0)+,D0
         SUBQ.W   #1,D0
         MOVEQ    #0,D1
CS_LOOP  MOVE.B   (A1)+,D1
         MOVE.B   UCASETBL(PC,D1.W),D1
         CMP.B    (A0)+,D1
         DBNE     D0,CS_LOOP
         BEQ.S    CS_MATCH
         MOVE.L   (A7)+,A1
         RTS
CS_MATCH ADDQ.W   #4,A7
         RTS

* Convert D1 to upper case

         XDEF     TOUPPER

TOUPPER  ANDI.W   #$FF,D1
         MOVE.B   UCASETBL(PC,D1.W),D1
         RTS

         XDEF     UCASETBL

UCASETBL DC.B     0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20
         DC.B     21,22,23,24,25,26,27,28,29,30,31
         DC.B     ' !"#$%&''()*+,-./0123456789:;<=>?'
         DC.B     '@ABCDEFGHIJKLMNOPQRSTUVWXYZ',$5B,'\]^_'
         DC.B     '`ABCDEFGHIJKLMNOPQRSTUVWXYZ{|}~'
         DC.B     128,129,130,131,132,133,134,135,136,137,138,139
         DC.B     140,141,142,143,144,145,146,147,148,149
         DC.B     150,151,152,153,154,155,156,157,158,159
         DC.B     160,161,162,163,164,165,166,167,168,169
         DC.B     170,171,172,173,174,175,176,177,178,179
         DC.B     180,181,182,183,184,185,186,187,188,189
         DC.B     190,191,192,193,194,195,196,197,198,199
         DC.B     200,201,202,203,204,205,206,207,208,209
         DC.B     210,211,212,213,214,215,216,217,218,219
         DC.B     220,221,222,223,224,225,226,227,228,229
         DC.B     230,231,232,233,234,235,236,237,238,239
         DC.B     240,241,242,243,244,245,246,247,248,249
         DC.B     250,251,252,253,254,255

* Copy name from (A1) to (A2)

         XDEF     COPYNAME

COPYNAME MOVEQ    #0,D0
         MOVE.B   (A1),D0
COPYNMLP MOVE.B   (A1)+,(A2)+
         DBF      D0,COPYNMLP
         RTS

* Write name from (A0) to (A1)

         XDEF     WRNAME

WRNAME   MOVEQ    #0,D0
         MOVE.B   (A0)+,D0
         BRA.S    WRNAM_E
WRNAM_L  MOVE.B   (A0)+,(A1)+
WRNAM_E  DBF      D0,WRNAM_L
         RTS

         XDEF     PRINTNAM,PRINTNM1

PRINTNAM MOVEQ    #0,D2
         MOVE.B   (A1)+,D2
         MOVEQ    #SP.SSTRG,D0
         JMP      DO_OUTP

PRINTNM1 MOVEQ    #0,D2
         MOVE.B   (A1)+,D2
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         RTS

         XDEF     YESNO,NOYES

YESNO    MOVEM.L  D1-D3/A1,-(A7)
         TXSTR    {'? (Y/n) '}
         MOVEQ    #'Y',D2
         BRA.S    YESNO_2
NOYES    MOVEM.L  D1-D3/A1,-(A7)
         TXSTR    {'? (y/N) '}
         MOVEQ    #'N',D2
YESNO_2  MOVEQ    #CR,D3
         REPEAT
            JSR      GETCHAR
            BSR      TOUPPER
            IF D1 EQ.B D3 THEN
               MOVE.B   D2,D1
            ENDIF
            MOVE.B   D1,D0
         UNTIL D0 EQ.B #'Y' OR D0 EQ.B #'N'
         MOVE.B   D0,D2
         JSR      TXCHAR
         JSR      TXCRLF
         CMPI.B   #'Y',D2
         MOVEM.L  (A7)+,D1-D3/A1
         RTS

* Convert Zone:Net/Node.Point to decimal
* Entry: A2 ptr to binary values, A1 ptr to result buffer
* Exit:  A1 past ASCII, D2 length

         XDEF     ZNNP2A

ZNNP2A   MOVE.L   A1,-(A7)
         MOVEQ    #0,D2
         MOVE.W   (A2)+,D1
         BEQ.S    Z2D_NET
         BSR.S    ITOD.W
         MOVE.B   #':',(A1)+
Z2D_NET  MOVE.W   (A2)+,D1
         BSR.S    ITOD.W
         MOVE.B   #'/',(A1)+
         MOVE.W   (A2)+,D1
         BSR.S    ITOD.W
         MOVE.W   (A2)+,D1
         IF NE THEN
            MOVE.B   #'.',(A1)+
            BSR.S    ITOD.W
         ENDIF
         MOVE.L   A1,D2
         SUB.L    (A7)+,D2
         RTS

* CONVERT D1.W TO DECIMAL
* D2 = NUMBER OF CHARACTERS
* D3 = FILL CHARACTER
* A1 = LOCATION OF BUFFER

         XDEF     ITOD.W

ITOD.W   MOVEM.L  D1/D2,-(A7)
         CMPI.W   #10,D1
         BGE.S    ITODW.1
ITODW.F  SUBQ.W   #1,D2
         BLE.S    ITODW.S
         MOVE.B   D3,(A1)+
         BRA.S    ITODW.F
ITODW.1  ANDI.L   #$FFFF,D1
         DIVU     #10,D1
         SUBQ.W   #1,D2
         BSR.S    ITOD.W
         SWAP     D1
ITODW.S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D1/D2
         RTS

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

* CONVERT D1.L TO DECIMAL WITH D3 LEADING SPACES

         XDEF     ITOD.L

ITOD.L   MOVEM.L  D0-D3,-(A7)
         MOVEQ    #10,D2
         CMP.L    D2,D1
         BHS.S    ITODL_1
ITODL_F  SUBQ.W   #1,D3
         BLE.S    ITODL_S
         MOVE.B   #' ',(A1)+
         BRA      ITODL_F
ITODL_1  BSR.S    DIVLONG
         SUBQ.W   #1,D3
         BSR.S    ITOD.L
         MOVE.B   D0,D1
ITODL_S  ADDI.B   #'0',D1
         MOVE.B   D1,(A1)+
         MOVEM.L  (A7)+,D0-D3
         RTS

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

* DATE CONVERSION ROUTINE
* ENTRY: D1 = QDOS DATE
* EXIT: D0L = MONTH, D0H = DAY OF WEEK, D1L = DAY OF MONTH
*       D2L = YEAR, D2H = HOURS, D3L = MINS, D3H = SECS

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
         SUBQ.W   #1,D1
         IF D1 GT.W #12 THEN
            SUBI.W   #12,D1
            ADDQ.W   #1,D2
         ENDIF
         MOVE.W   D1,D0
         CLR.W    D1
         SWAP     D1
         DIVU     D4,D1
         ADDQ.W   #1,D1
         RTS

* CONVERT DATE INTO "DD-MM-YYYY" FORMAT
* ENTRY: D1 QDOS DATE, A1 START OF BUFFER
* EXIT: A1 PAST BUFFER, D2 LENGTH OF STRING

         XDEF     DATE

DATE     MOVEM.L  D1/D3-D4/A2,-(A7)
         BSR      GETDATE
         MOVE.W   D2,D4
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         BSR      ITOD.W
         MOVE.B   #'-',(A1)+
         MOVE.W   D0,D1
         BSR      ITOD.W
         MOVE.B   #'-',(A1)+
         MOVEQ    #0,D1
         MOVE.W   D4,D1
         DIVU     #100,D1
         SWAP     D1
         BSR      ITOD.W
         MOVEM.L  (A7)+,D1/D3-D4/A2
         MOVEQ    #8,D2
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
         BSR      ITOD.W
         MOVE.B   D3,(A1)+
         SWAP     D0
         SUBQ.W   #1,D0
         LEA      MONTHTBL,A2
         ADDA.W   D0,A2
         ADD.W    D0,D0
         ADDA.W   D0,A2
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVEQ    #5,D2
         MOVE.W   D5,D1
         BSR      ITOD.W
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
         BSR      ITOD.W
         MOVE.B   #':',(A1)+
         MOVE.W   D6,D1
         BSR      ITOD.W
         MOVE.B   #':',(A1)+
         SWAP     D6
         MOVE.W   D6,D1
         BSR      ITOD.W
         MOVE.W   D4,D2
         MOVEM.L  (A7)+,D1/D3-D6/A2
         RTS

         SECTION  MSG
DAYTBL   DC.B     'SunMonTueWedThuFriSat'
MONTHTBL DC.B     'JanFebMarAprMayJunJulAugSepOctNovDec'
         DC.W     0
         SECTION  CODE

         END
