* CVTUSER

* Converts USERS_BBS file of QBOX v1.14 to USERS_BBS & LASTREAD_BBS of v1.19

         INCLUDE  FLP1_MACRO_LIB
         INCLUDE  FLP1_QDOS_IN_MAC
         INCLUDE  FLP2_QBOX_H

         OFFSET   0

CONCHAN  DS.L     1
USERSBBS DS.L     1
LSTRDBBS DS.L     1
DIRLEN   DS.W     1
FILENAME DS.B     50
USBBSREC DS.B     US_LEN
LSTRDBUF DS.W     MAXAREA
MAREAGRP DS.B     32
FAREAGRP DS.B     32

         DATA     1024

         SECTION  CODE

         BRA.S    START
         DC.W     $4AFB,$4AFB,$4AFB
JOBNAME  STRING$  {'CVTUSER'}
         DS.W     0
BANNER   DC.B     4,1,4,0
         DC.W     448,62,32,70
WINDOW   DC.B     0,0,0,7
         DC.W     444,50,34,81

START    ADDA.L   A4,A6
         TST.W    (A7)+
         BEQ.S    NOREDIR
         MOVE.L   (A7)+,A0
         BRA.S    SIGNON
NOREDIR  LEA      BANNER,A1
         MOVE.W   UT_SCR,A2
         JSR      (A2)
         BNE      EXIT
         LEA      JOBNAME,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         LEA      WINDOW,A1
         MOVE.W   UT_CON,A2
         JSR      (A2)
         BNE      EXIT
SIGNON   MOVE.L   A0,CONCHAN(A6)
         PRINT    {'QBOX USERS_BBS Conversion Utility',LF}
         PRINT    {'Converts v1.14 USERS_BBS to v1.19 format',LF}
         CLR.W    DIRLEN(A6)
         QDOS     MT.INF
         MOVE.L   $AC(A0),A0
         MOVE.L   A0,D0
         BEQ.S    ASKDIR
         MOVE.W   (A0)+,D0
         MOVE.W   D0,DIRLEN(A6)
         LEA      FILENAME+2(A6),A1
         REPEAT
            MOVE.B   (A0)+,(A1)+
            SUBQ.W   #1,D0
         UNTIL    LE
ASKDIR   MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Please enter QBOX system directory: '}
         MOVEQ    #0,D1
         MOVE.W   DIRLEN(A6),D1
         MOVEQ    #36,D2
         MOVEQ    #-1,D3
         LEA      FILENAME+2(A6,D1.W),A1
         QDOS     IO.EDLIN
         TST.L    D0
         BNE      ASKDIR
         SUBQ.W   #1,D1
         BEQ      EXIT
         MOVE.W   D1,DIRLEN(A6)
         SUBQ.W   #1,A1
         WRITE$   {'USERS_BBS'},A1
         ADDI.W   #9,D1
         LEA      FILENAME(A6),A0
         MOVE.W   D1,(A0)
         MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         QDOS     IO.OPEN
         TST.L    D0
         IF NE THEN
            MOVE.L   CONCHAN(A6),A0
            PRINT    {LF,'No USERS_BBS found!',LF}
            BRA      ASKDIR
         ENDIF
         MOVE.L   A0,USERSBBS(A6)
         LOAD$    {'MAREAS_BBS'},A4
         LEA      MAREAGRP(A6),A5
         BSR      CVT_AREA
         LOAD$    {'FAREAS_BBS'},A4
         LEA      FAREAGRP(A6),A5
         BSR      CVT_AREA
         MOVE.W   DIRLEN(A6),D1
         LEA      FILENAME+2(A6,D1.W),A1
         WRITE$   {'LASTREAD_BBS'},A1
         ADDI.W   #12,D1
         LEA      FILENAME(A6),A0
         MOVE.W   D1,(A0)
         MOVEQ    #-1,D1
         MOVEQ    #IO.OVER,D3
         QDOS     IO.OPEN
         TST.L    D0
         IF NE THEN
            MOVE.L   D0,-(A7)
            MOVE.L   CONCHAN(A6),A0
            PRINT    {LF,'Unable to create LASTREAD_BBS',LF}
            MOVE.L   (A7)+,D0
            BRA      EXIT
         ENDIF
         MOVE.L   A0,LSTRDBBS(A6)
         LEA      LSTRDBUF(A6),A1
         MOVE.W   #MAXAREA,D0
         REPEAT
            CLR.L    (A1)+
            SUBQ.W   #2,D0
         UNTIL    LE
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Updating USERS_BBS and creating LASTREAD_BBS...',LF}
LOOP     MOVE.W   #US_LEN,D2
         MOVEQ    #-1,D3
         MOVE.L   USERSBBS(A6),A0
         LEA      USBBSREC(A6),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    EXITLOOP
         MOVE.L   #-US_LEN,D1
         QDOS     FS.POSRE
         LEA      USBBSREC+US_MACCS(A6),A1
         LEA      MAREAGRP(A6),A5
         BSR      GET_GRPS
         LEA      USBBSREC+US_FACCS(A6),A1
         LEA      FAREAGRP(A6),A5
         BSR      GET_GRPS
         LEA      USBBSREC(A6),A1
         SUBQ.B   #1,US_MAREA(A1)
         SUBQ.B   #1,US_FAREA(A1)
         QDOS     IO.SSTRG
         TST.L    D0
         BNE.S    IOERROR
         LEA      LSTRDBUF+64(A6),A2
         MOVEQ    #32,D0
         REPEAT
            MOVE.B   -(A1),-(A2)
            SUBQ.W   #1,A2
            SUBQ.W   #1,D0
         UNTIL    LE
         MOVE.W   #MAXAREA*2,D2
         MOVEQ    #-1,D3
         MOVE.L   LSTRDBBS(A6),A0
         LEA      LSTRDBUF(A6),A1
         QDOS     IO.SSTRG
         TST.L    D0
         BNE.S    IOERROR
         BRA      LOOP

EXITLOOP CMPI.L   #ERR.EF,D0
         BNE.S    IOERROR
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Finished!',LF}
         CLR.L    -(A7)
         BRA.S    CLOSE
IOERROR  MOVE.L   D0,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Disk I/O Error!',LF}
CLOSE    MOVE.L   USERSBBS(A6),A0
         QDOS     IO.CLOSE
         MOVE.L   LSTRDBBS(A6),A0
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0

EXIT     MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

CVT_AREA MOVEQ    #31,D0
CVTA_CLR ST       (A5,D0.W)
         DBF      D0,CVTA_CLR
         MOVE.W   DIRLEN(A6),D1
         MOVE.L   A4,A0
         LEA      FILENAME+2(A6,D1.W),A1
         WRITE$
         ADDI.W   #10,D1
         LEA      FILENAME(A6),A0
         MOVE.W   D1,(A0)
         MOVEQ    #-1,D1
         MOVEQ    #IO.SHARE,D3
         QDOS     IO.OPEN
         TST.L    D0
         IF NE THEN
            MOVE.L   D0,-(A7)
            MOVE.L   CONCHAN(A6),A0
            PRINT    {LF,'Unable to open '}
            MOVE.L   A4,A1
            JSR      (A2)
            MOVEQ    #LF,D1
            QDOS     IO.SBYTE
            MOVE.L   (A7)+,D0
            BRA      EXIT
         ENDIF
         MOVE.L   A0,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Reading '}
         MOVE.L   A4,A1
         JSR      (A2)
         PRINT    {'...',LF}
         MOVE.L   (A7)+,A0
         MOVE.W   #512,D2
         MOVEQ    #-1,D3
         MOVEQ    #31,D7
CVTA_LP  LEA      LSTRDBUF(A6),A1
         QDOS     IO.FLINE
         CMPI.L   #ERR.EF,D0
         BEQ.S    CVTA_END
         TST.L    D0
         IF NE THEN
            MOVE.L   D0,-(A7)
            MOVE.L   CONCHAN(A6),A0
            PRINT    {'I/O Error!',LF}
            MOVE.L   (A7)+,D0
            BRA      EXIT
         ENDIF
         SUBA.W   D1,A1
CVTA_SKP CMPI.B   #' ',(A1)
         BLS.S    CVTA_SK2
         ADDQ.W   #1,A1
         BRA      CVTA_SKP
CVTA_SK2 CMPI.B   #' ',(A1)
         BHI.S    CVTA_LET
         BLO.S    CVTA_NXT
         ADDQ.W   #1,A1
         BRA      CVTA_SK2
CVTA_LET CMPI.B   #'/',(A1)
         BEQ.S    CVTA_G
         CMPI.B   #'-',(A1)
         BNE.S    CVTA_NXT
CVTA_G   MOVEQ    #$DF-256,D1
         AND.B    1(A1),D1
         CMPI.B   #'G',D1
         BNE      CVTA_SKP
         CMPI.B   #'=',2(A1)
         BNE      CVTA_SKP
         MOVE.B   3(A1),D1
         SUBI.B   #'A',D1
         CMPI.B   #'Z'-'A',D1
         BLS.S    CVTA_GRP
         SUBI.B   #'a'-'A',D1
         CMPI.B   #'Z'-'A',D1
         BHI      CVTA_SKP
CVTA_GRP MOVE.B   D1,(A5)
CVTA_NXT ADDQ.W   #1,A5
         DBF      D7,CVTA_LP
CVTA_END QDOS     IO.CLOSE
         RTS

GET_GRPS MOVEQ    #31,D7
         MOVE.L   (A1),D1
         MOVEQ    #0,D4
         MOVEQ    #0,D0
GG_LOOP  BTST     D7,D1
         BEQ.S    GG_NEXT
         MOVE.B   (A5,D7.W),D0
         BMI.S    GG_NEXT
         BSET     D0,D4
GG_NEXT  DBF      D7,GG_LOOP
         MOVE.L   D4,(A1)
         RTS

         SECTION  MSG

         DC.W     0

         END
