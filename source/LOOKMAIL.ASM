* QBOX MAILSCAN UTILITY
* November 16, 1988

version  SETSTR   1.19

         INCLUDE  FLP1_QDOS_IN_MAC

CR       EQU      $0D
LF       EQU      $0A
MS_TOUSR EQU      32
MS_ATTR  EQU      20
MS..RECD EQU      2
MAXAREA  EQU      256

         OFFSET   0

US_NAME  DS.B     1+36
US_NMAIL DS.B     1+MAXAREA
US_LEN   EQU      *

BLOKSIZE EQU      16
BLOCKLEN EQU      BLOKSIZE*US_LEN+4

         OFFSET   0

SCRCHAN  DS.L     1
AREACHAN DS.L     1
MAILLIST DS.L     1
SYSDIR   DS.B     2+48
AREALINE DS.B     2+127

         SECTION  CODE

         BRA.S    JOBSTART
         DC.W     $4AFB,$4AFB,$4AFB
         STRING$  'LOOKMAIL'
SCR1DEF  STRING$  'SCR_448X192A32X16'
         DS.W     0
SCR1COL  DC.B     0,0,4,0
SCR2DEF  STRING$  'SCR_444X180A34X27'
         DS.W     0
SCR2COL  DC.B     0,0,0,7
AREAFNAM STRING$  'MAREAS_BBS'
MSG_FNAM STRING$  'MESSAGES_BBS'
NMAILFNM STRING$  'NEWMAIL_BBS'

JOBSTART ADDA.L   A4,A6
         LEA      SCR1DEF,A0
         LEA      SCR1COL,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         PRINT    {' LOOKMAIL v[version]   1988-91 Jan Bredenbeek'}
         LEA      SCR2DEF,A0
         LEA      SCR2COL,A1
         MOVE.W   UT_WINDW,A2
         JSR      (A2)
         MOVE.L   A0,SCRCHAN(A6)
         MOVE.W   (A7)+,D0
         LSL.W    #2,D0
         LEA      (A7,D0.W),A0
         TST.W    (A0)
         BNE.S    COPYDIR
         QDOS     MT.INF
         MOVE.L   $AC(A0),A0
         MOVE.L   A0,D0
         BNE.S    COPYDIR
         SUBA.L   A0,A0
         PRINT    {'LOOKMAIL: Unable to find QBOX system directory',LF}
         BRA      QUIT
COPYDIR  LEA      SYSDIR+2(A6),A1
         MOVE.W   (A0)+,D4
         MOVE.W   D4,D0
         BRA.S    COPYDIR3
COPYDIR2 MOVE.B   (A0)+,(A1)+
COPYDIR3 DBF      D0,COPYDIR2
         LEA      AREAFNAM,A2
         MOVE.W   (A2)+,D0
         LEA      SYSDIR(A6),A0
         MOVE.W   D0,(A0)
         ADD.W    D4,(A0)
COPYDIR4 MOVE.B   (A2)+,(A1)+
         SUBQ.W   #1,D0
         BNE      COPYDIR4
         MOVEQ    #-1,D1
         MOVEQ    #1,D3
         QDOS     IO.OPEN
         TST.L    D0
         BNE      ERR_EXIT
         MOVE.L   A0,AREACHAN(A6)
         MOVE.W   D4,SYSDIR(A6)
         CLR.L    MAILLIST(A6)
         MOVEQ    #-1,D7
NXTAREA  ADDQ.W   #1,D7
         CMPI.W   #MAXAREA,D7
         BGE      END_AREA
         MOVEQ    #127,D2
         MOVEQ    #-1,D3
         MOVE.L   AREACHAN(A6),A0
         LEA      AREALINE+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE      END_AREA
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BLE      NXTAREA
         MOVEQ    #-1,D0
FINDSPC  ADDQ.W   #1,D0
         CMPI.B   #' ',(A1)+
         DBEQ     D1,FINDSPC
         SUBQ.W   #1,A1
         LEA      MSG_FNAM,A0
         MOVE.W   (A0)+,D1
         ADD.W    D1,D0
         MOVE.W   D0,AREALINE(A6)
COPYDIR5 MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D1
         BNE      COPYDIR5
         MOVE.L   SCRCHAN(A6),A0
         PRINT    {'Scanning message area #'}
         MOVE.W   D7,D1
         ADDQ.W   #1,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {'...',LF}
         MOVEQ    #-1,D1
         MOVEQ    #1,D3
         LEA      AREALINE(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    OMSG_OK
         MOVE.L   D0,-(A7)
         MOVE.L   SCRCHAN(A6),A0
         PRINT    {'*** Can''t open MESSAGES_BBS: '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA      NXTAREA
OMSG_OK  MOVEQ    #-1,D3
         BSR      FBYTE
         MOVEQ    #0,D6
         MOVE.B   D1,D6
         MOVEQ    #1,D5
         BRA.S    RMSG_NXT
RMSG_LP  MOVE.L   D5,D1
         ADDQ.L   #4,D5
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         SUBA.W   D2,A7
         MOVE.L   A7,A1
         BSR      FSTRG
         MOVE.L   (A7)+,D1
         BLT.S    RMSG_NXT
         MOVEQ    #MS_ATTR+1,D0
         ADD.L    D0,D1
         QDOS     FS.POSAB
         BSR      FBYTE
         BTST     #MS..RECD,D1
         BNE.S    RMSG_NXT
         MOVEQ    #MS_TOUSR-(MS_ATTR+2),D1
         QDOS     FS.POSRE
         BSR.S    FBYTE
         MOVEQ    #0,D2
         MOVE.B   D1,D2
         LEA      AREALINE(A6),A1
         MOVE.B   D1,(A1)+
         BSR.S    FSTRG
         BSR      ADD_MSG
RMSG_NXT DBF      D6,RMSG_LP
         QDOS     IO.CLOSE
         BRA      NXTAREA
END_AREA MOVE.L   SCRCHAN(A6),A0
         PRINT    {LF,'Writing out NEWMAIL_BBS...',LF}
         LEA      SYSDIR(A6),A0
         MOVE.W   (A0),D0
         LEA      2(A0,D0.W),A1
         LEA      NMAILFNM,A2
         MOVE.W   (A2)+,D0
         ADD.W    D0,(A0)
COPYFNAM MOVE.B   (A2)+,(A1)+
         SUBQ.W   #1,D0
         BNE      COPYFNAM
         MOVEQ    #-1,D1
         MOVEQ    #3,D3
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    ERR_EXIT
         MOVEQ    #-1,D3
         LEA      MAILLIST(A6),A5
WM_NXTBL MOVE.L   (A5),D0
         BEQ.S    WM_END
         MOVE.L   D0,A5
         LEA      4(A5),A4
         MOVEQ    #BLOKSIZE,D7
WM_ENTRY TST.B    (A4)
         BEQ.S    WM_END
         MOVE.L   A4,A1
         BSR.S    SSTRG
         LEA      US_NMAIL(A4),A1
         BSR.S    SSTRG
         ADDA.W   #US_LEN,A4
         SUBQ.W   #1,D7
         BNE      WM_ENTRY
         BRA      WM_NXTBL
FBYTE    MOVEQ    #IO.FBYTE&$FF,D0
         BRA.S    DOTRP3
FSTRG    MOVEQ    #IO.FSTRG&$FF,D0
         BRA.S    DOTRP3
SSTRG    MOVEQ    #1,D2
         ADD.B    (A1),D2
         MOVEQ    #IO.SSTRG&$FF,D0
DOTRP3   TRAP     #3
         TST.L    D0
         BNE.S    ERR_EXIT
         RTS

WM_END   QDOS     IO.CLOSE
         MOVE.L   SCRCHAN(A6),A0
         PRINT    {'Finished.',LF}
         BRA.S    QUIT

ERR_EXIT MOVE.L   D0,-(A7)
         MOVE.L   SCRCHAN(A6),A0
         PRINT    {'*** ERROR: '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
QUIT     MOVEQ    #100,D3
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         QDOS     MT.FRJOB

ADD_MSG  MOVEM.L  D3/D5-D6/A0,-(A7)
         LEA      MAILLIST(A6),A5
AM_NXBLK MOVE.L   (A5),D0
         BEQ.S    ADDNBLOK
         MOVE.L   D0,A5
         LEA      4(A5),A4
         MOVEQ    #BLOKSIZE,D6
AM_NXNAM TST.B    (A4)
         BEQ.S    ADDNNAME
         LEA      AREALINE(A6),A0
         MOVE.L   A4,A1
         MOVEQ    #0,D0
         MOVE.B   (A0),D0
AM_CMPNM CMPM.B   (A0)+,(A1)+
         DBNE     D0,AM_CMPNM
         BEQ.S    AM_CAREA
         ADDA.W   #US_LEN,A4
         SUBQ.W   #1,D6
         BNE      AM_NXNAM
         BRA      AM_NXBLK
AM_CAREA LEA      US_NMAIL(A4),A1
         MOVEQ    #0,D0
         MOVE.B   (A1),D0
         CMP.B    (A1,D0.W),D7
         BEQ.S    AM_END
         BRA.S    ADDNAREA
ADDNBLOK MOVE.L   #BLOCKLEN,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE      ERR_EXIT
         MOVE.L   A0,(A5)
         LEA      4(A0),A4
ADDNNAME LEA      AREALINE(A6),A0
         MOVE.L   A4,A1
         MOVEQ    #0,D0
         MOVE.B   (A0),D0
AM_NLP   MOVE.B   (A0)+,(A1)+
         DBF      D0,AM_NLP
ADDNAREA ADDA.W   #US_NMAIL,A4
         MOVEQ    #0,D0
         MOVE.B   (A4),D0
         ADDQ.B   #1,(A4)
         MOVE.B   D7,1(A4,D0.W)
AM_END   MOVEM.L  (A7)+,D3/D5-D6/A0
         RTS

         SECTION  MSG
         DC.W     0

         END
