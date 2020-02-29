* User maintenance and message/file area select routines

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         DATA     0

         XREF     LOG,LOG1,OP_FILE,OP_FIN,OP_ERROR,TXNUMBER,ITOD.W,ITOD.L
         XREF     IO_ERROR,FCLOSE,DIRCLOSE,TYPE,TXSTR,TXCRLF,TXLF,READNUM
         XREF     TXCHAR,TOUPPER,LOOKCHAR,GETCHAR,INDEXER,TXTIME,LOG0
         XREF     INPUT,GETNAM1,GETNAM2,CMPNAME,COPYNAME,PRINTNAM,CHKTIME
         XREF     YESNO,NOYES,GETLIN1,TXLINE,PAUSE,DATE$,OP_ERROR,WRITEERR
         XREF     USLSTFNM,MSG_FNAM,SKIPSPC,A2ZNNP,ASK_ENTR,WRNAME,SPEEDS
         XREF     WRITE$,WRITEL$,TMSGFNAM

         SECTION  CODE

OPU_FILE LEA      OP_FILE,A2
         BRA.S    OPU_F1
OPU_FIN  LEA      OP_FIN,A2
OPU_F1   LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      (A2)
         BEQ.S    OPU_OK
OP_ERR2  TXSTR    {CR,LF,'*** USERS_BBS access error',CR,LF}
         JMP      OP_ERROR
OPU_OK   RTS

         XDEF     USERPARM

USERPARM LOG      {'Change user settings',LF}
         LEA      USERBUF(A6),A1
         LEA      USERBUF2(A6),A2
         MOVEQ    #US_LEN/4,D0
         REPEAT
            MOVE.L   (A1)+,(A2)+
            SUBQ.W   #1,D0
         UNTIL    LE
         MOVEQ    #-1,D6      Current record
UP_NEW   SF       D7          No updates yet
UP_AGAIN TXSTR    {FF,'Change user settings',CR,LF,LF}
         TST.W    D6
         IF PL THEN
            TXSTR    {'Record number: '}
            MOVE.W   D6,D1
            JSR      TXNUMBER
            TXSTR    {CR,LF}
         ENDIF
         TXSTR             {'Name                  : '}
         LEA      USERBUF2+US_NAME(A6),A1
         JSR      PRINTNAM
         TXSTR       {CR,LF,'City                  : '}
         LEA      USERBUF2+US_CITY(A6),A1
         JSR      PRINTNAM
         MOVEQ    #US.LEVEL,D1
         AND.B    USERBUF+US_LEVEL(A6),D1
         IF D1 HS.B #LV.COSYS THEN
            IF D1 HS.B #LV.SYSOP THEN
               TXSTR    {CR,LF,'Password              : '}
               LEA      USERBUF2+US_PASSW(A6),A1
               JSR      PRINTNAM
            ENDIF
            TXSTR    {CR,LF,'Security level        : '}
            MOVEQ    #US.LEVEL,D1
            AND.B    USERBUF2+US_LEVEL(A6),D1
            LEA      USLVTBL,A1
            ADD.W    D1,D1
            ADDA.W   (A1,D1.W),A1
            JSR      TXSTR
            TXSTR    {CR,LF,'Message area groups   : '}
            MOVE.L   USERBUF2+US_MACCS(A6),D1
            BSR      TXGROUPS
            TXSTR    {CR,LF,'File area groups      : '}
            MOVE.L   USERBUF2+US_FACCS(A6),D1
            BSR      TXGROUPS
         ENDIF
         TXSTR       {CR,LF,'Help level            : '}
         MOVE.B   USERBUF2+US_HELPL(A6),D1
         LSR.B    #4,D1
         LEA      HELPLTBL,A1
         ADD.W    D1,D1
         ADDA.W   (A1,D1.W),A1
         JSR      TXSTR
         TXSTR       {CR,LF,'Screen width          : '}
         MOVEQ    #0,D1
         MOVE.B   USERBUF2+US_WIDTH(A6),D1
         ADDQ.W   #1,D1
         JSR      TXNUMBER
         TXSTR       {CR,LF,'Number of screen lines: '}
         MOVEQ    #$7F,D1
         AND.B    USERBUF2+US_LINES(A6),D1
         JSR      TXNUMBER
         TXSTR       {CR,LF,'"More?"               : '}
         TST.B    USERBUF2+US_MORE(A6)
         IF MI THEN
            TXSTR    {'ON'}
         ELSE
            TXSTR    {'OFF'}
         ENDIF
         TXSTR       {CR,LF,'Number of logons      : '}
         MOVE.W   USERBUF2+US_CALLS(A6),D1
         JSR      TXNUMBER
         JSR      TXCRLF
         MOVEQ    #US.LEVEL,D1
         AND.B    USERBUF+US_LEVEL(A6),D1
         IF D1 HS.B #LV.COSYS THEN
            TXSTR          {'Last logon            : '}
            MOVE.L   USERBUF2+US_LSTLG(A6),D1
            JSR      TXTIME
         ENDIF
         TXSTR             {'Time online today     : '}
         QDOS     MT.RCLCK
         MOVE.L   D1,D0
         SUB.L    USERBUF2+US_LSTLG(A6),D0
         DIVU     #60,D0
         MOVE.W   USERBUF2+US_DAYTM(A6),D1
         TST.L    D6
         IF LT THEN
            ADD.W    D0,D1
         ENDIF
         JSR      TXNUMBER
         TXSTR    {' minutes',CR,LF}
CH_USER  LEA      CHUSRTBL,A1
         JSR      INDEXER
         ST       D7
         BRA      UP_AGAIN

TXGROUPS SUBA.W   #28,A7
         MOVE.L   A7,A1
         CLR.W    (A1)+
         MOVEQ    #'A',D0
         REPEAT
            LSR.L    #1,D1
            IF CS THEN
               MOVE.B   D0,(A1)+
               ADDQ.W   #1,(A7)
            ENDIF
            ADDQ.B   #1,D0
         UNTIL    D0 HI.B #'Z'
         MOVE.L   A7,A1
         JSR      TXSTR
         ADDA.W   #28,A7
         RTS

         XDEF     USLVTBL

USLVTBL  DC.W     TWIT-USLVTBL
         DC.W     DISGR-USLVTBL
         DC.W     NORM-USLVTBL
         DC.W     SPEC-USLVTBL
         DC.W     EXTRA-USLVTBL
         DC.W     0,0,0
         DC.W     COSYS-USLVTBL
         DC.W     SYSOP-USLVTBL
TWIT     STRING$  'TWIT'
DISGR    STRING$  'DISGRACE'
NORM     STRING$  'NORMAL'
SPEC     STRING$  'SPECIAL'
EXTRA    STRING$  'EXTRA'
COSYS    STRING$  'COSYSOP'
SYSOP    STRING$  'SYSOP'

HELPLTBL DC.W     NOVICE-HELPLTBL
         DC.W     REGULAR-HELPLTBL
         DC.W     EXPERT-HELPLTBL
NOVICE   STRING$  'NOVICE'
REGULAR  STRING$  'REGULAR'
EXPERT   STRING$  'EXPERT'

CHUSRTBL STRING$  {'Commands'}
         STRING$  {LV.COSYS,'B',$5B,'B]ack'}
         DC.W     PREVUSER-*
         STRING$  {LV.COSYS,'F',$5B,'F]orward'}
         DC.W     NEXTUSER-*
         STRING$  {LV.COSYS,'S',$5B,'S]earch'}
         DC.W     SEARCH-*
         STRING$  {LV.COSYS,'U',$5B,'U]serlist'}
         DC.W     CH_ULIST-*
         STRING$  {LV.COSYS,'K',$5B,'K]ill'}
         DC.W     US_KILL-*
         STRING$  {LV.COSYS,'N',$5B,'N]ame'}
         DC.W     CH_NAME-*
         STRING$  {LV.DISGR,'C',$5B,'C]ity'}
         DC.W     CH_CITY-*
         STRING$  {LV.DISGR,'P',$5B,'P]assword'}
         DC.W     CH_PASSW-*
         STRING$  {LV.DISGR,'W',$5B,'W]idth'}
         DC.W     CH_WIDTH-*
         STRING$  {LV.DISGR,'T',$5B,'T]erminal lines'}
         DC.W     CH_LINES-*
         STRING$  {LV.COSYS,'L',$5B,'L]evel'}
         DC.W     CH_LEVEL-*
         STRING$  {LV.COSYS,'A',$5B,'A]rea groups'}
         DC.W     CH_AREA-*
         STRING$  {LV.DISGR,'H',$5B,'H]elp level'}
         DC.W     CH_HELP-*
         STRING$  {LV.DISGR,'M',$5B,'M]ore'}
         DC.W     CH_MORE-*
         STRING$  {LV.DISGR,'R',$5B,'R]eturn without updating'}
         DC.W     CH_ABORT-*
         STRING$  {LV.DISGR,'Q',$5B,'Q]uit & update'}
         DC.W     CH_QUIT-*
         DC.W     0

CH_ABORT TXSTR    {CR,LF,'Settings not altered',CR,LF}
         ADDQ.W   #4,A7
CHNAMEND RTS

US_KILL  TXSTR    {'Kill user'}
         JSR      NOYES
         IF EQ THEN
            CLR.B    USERBUF2+US_NAME(A6)
         ENDIF
         RTS
CH_NAME  MOVEQ    #US.NMAX+1,D2
         LEA      BUFFER+1(A6),A1
         INPUT    {'New name: '}
         SUBQ.B   #1,D1
         BLE.S    CHC_END
         MOVE.B   D1,-(A1)
         LEA      USERBUF2+US_NAME(A6),A2
         JSR      CMPNAME
         BEQ.S    CHN_OK
         BSR      OPU_FIN
         LEA      BUFFER(A6),A1
         LEA      US_LEN(A1),A2
         BSR      FINDUSER
         MOVE.L   D0,D4
         JSR      FCLOSE
         TST.L    D4
         IF EQ THEN
            TXSTR    {'Already exists',CR,LF}
            MOVEQ    #50,D3
            JMP      PAUSE
         ENDIF
CHN_OK   LEA      BUFFER(A6),A1
         LEA      USERBUF2+US_NAME(A6),A2
CHN_END  JMP      COPYNAME

CH_CITY  LOG      {'Changing city',LF}
         MOVEQ    #US.CMAX,D2
         SF       D0
         GETNAM2  {'City: '}
         BEQ.S    CHC_END
         LEA      USERBUF2+US_CITY(A6),A2
         JMP      COPYNAME
CHC_END  RTS

CH_PASSW LOG      {'Changing password',LF}
         MOVEQ    #3,D4
         ST       ECHOPNT(A6)
         MOVEQ    #US.PMAX,D2
CHECKPWD SF       D0
         GETNAM1  {'Enter your OLD password: '}
         BEQ.S    PWD_FAIL
         LEA      USERBUF2+US_PASSW(A6),A2
         JSR      CMPNAME
         BEQ.S    CH_PW2
         TXSTR    {'Incorrect, try again',CR,LF,LF}
         SUBQ.B   #1,D4
         BNE      CHECKPWD
PWD_FAIL TXSTR    {'Password not changed',CR,LF,LF}
         SF       ECHOPNT(A6)
         RTS
CH_PW2   SF       D0
         GETNAM1  {'Enter your NEW password: '}
         BEQ      PWD_FAIL
         LEA      BUFFER+US.PMAX+1(A6),A2
         JSR      COPYNAME
         SF       D0
         GETNAM1  {'Please re-enter for verification: '}
         BEQ      PWD_FAIL
         LEA      BUFFER+US.PMAX+1(A6),A2
         JSR      CMPNAME
         BEQ.S    PWD_OK
         TXSTR    {'Passwords do not match!',CR,LF}
         BRA      PWD_FAIL
PWD_OK   TXSTR    {'Password change successful',CR,LF,LF}
         SF       ECHOPNT(A6)
         LEA      BUFFER(A6),A1
         LEA      USERBUF2+US_PASSW(A6),A2
         JMP      COPYNAME

CH_MORE  BCHG     #7,USERBUF2+US_MORE(A6)
         RTS

LEVMENU  STRING$  {'New user level'}
         STRING$  {LV.COSYS,'T',$5B,'T]wit'}
         DC.W     LV_TWIT-*
         STRING$  {LV.COSYS,'D',$5B,'D]isgrace'}
         DC.W     LV_DISGR-*
         STRING$  {LV.COSYS,'N',$5B,'N]ormal'}
         DC.W     LV_NORM-*
         STRING$  {LV.COSYS,'S',$5B,'S]pecial'}
         DC.W     LV_SPEC-*
         STRING$  {LV.COSYS,'E',$5B,'E]xtra'}
         DC.W     LV_EXTRA-*
         STRING$  {LV.SYSOP,'C',$5B,'C]osysop'}
         DC.W     LV_COSYS-*
         STRING$  {LV.SYSOP,'O','sys',$5B,'O]p'}
         DC.W     LV_SYSOP-*
         DC.W     0

LV_TWIT  MOVEQ    #LV.TWIT,D1
         RTS
LV_DISGR MOVEQ    #LV.DISGR,D1
         RTS
LV_NORM  MOVEQ    #LV.NORM,D1
         RTS
LV_SPEC  MOVEQ    #LV.SPEC,D1
         RTS
LV_EXTRA MOVEQ    #LV.EXTRA,D1
         RTS
LV_COSYS MOVEQ    #LV.COSYS,D1
         RTS
LV_SYSOP MOVEQ    #LV.SYSOP,D1
         RTS

CH_LEVEL LEA      LEVMENU,A1
         JSR      INDEXER
         MOVEQ    #US_LEVEL,D4
         MOVEQ    #US.LEVEL,D5
         BRA.S    LEV_ENT

CH_WIDTH LEA      WIDTHMSG,A0
         MOVEQ    #US_WIDTH,D4
         MOVEQ    #-1,D5
         BRA.S    CH_SCRSZ
CH_LINES LEA      LINESMSG,A0
         MOVEQ    #US_LINES,D4
         MOVEQ    #$7F,D5
CH_SCRSZ MOVEQ    #4,D2
         LEA      BUFFER(A6),A1
         JSR      INPUT
         JSR      READNUM
         IF NE THEN
            TXSTR    {'Invalid number',CR,LF,LF}
            BRA      CH_SCRSZ
         ENDIF
         IF D1 LO.B #10 THEN
            TXSTR    {'Minimum is 10',CR,LF,LF}
            BRA      CH_SCRSZ
         ENDIF
LEV_ENT  LEA      USERBUF2(A6),A1
         IF D4 EQ.W #US_WIDTH THEN
            SUBQ.B   #1,D1
         ENDIF
         AND.B    D5,D1
         NOT.B    D5
         AND.B    D5,(A1,D4.W)
         OR.B     D1,(A1,D4.W)
         RTS

CH_HELP  TXSTR    {'Help level:',CR,LF,LF}
         TXSTR    {'1. Novice  - full menus',CR,LF}
         TXSTR    {'2. Regular - brief menus',CR,LF}
         TXSTR    {'3. Expert  - no menus',CR,LF,LF}
         TXSTR    {'Enter 1, 2 or 3: '}
         JSR      GETCHAR
         MOVE.B   D1,D2
         JSR      TXCRLF
         SUBI.B   #'1',D2
         CMPI.B   #2,D2
         BHI      CH_HELP
         LSL.B    #4,D2
         ANDI.B   #US.LEVEL,USERBUF2+US_HELPL(A6)
         OR.B     D2,USERBUF2+US_HELPL(A6)
         RTS

         SECTION  MSG
M_AREAS  STRING$  {'Message area groups: '}
F_AREAS  STRING$  {'File area groups   : '}
         SECTION  CODE

CH_AREA  LEA      M_AREAS,A0
         MOVEQ    #US_MACCS,D4
         BSR.S    CH_A_SUB
         LEA      F_AREAS,A0
         MOVEQ    #US_FACCS,D4
CH_A_SUB MOVEQ    #27,D2
         LEA      BUFFER(A6),A1
         JSR      INPUT
         SUBQ.W   #1,D1
         BLE.S    AR_END
         MOVEQ    #0,D0
CH_A_LP  MOVE.B   (A1)+,D1
         CMPI.B   #CR,D1
         BEQ.S    AR_OK
         JSR      TOUPPER
         SUBI.B   #'A',D1
         CMPI.B   #'Z'-'A',D1
         BHI      CH_A_LP
         BSET     D1,D0
         BRA      CH_A_LP
AR_OK    LEA      USERBUF2(A6),A1
         MOVE.L   D0,(A1,D4.W)
AR_END   RTS

SEARCH   BSR      WR_USER1
         MOVEQ    #US.NMAX,D2
         SF       D0
         GETNAM2  {'Search for name: '}
         BEQ      AR_END
         BSR      OPU_FIN
         LEA      BUFFER(A6),A1
         LEA      BUFFER+US_LEN(A6),A2
         BSR      FINDUSER
         BEQ.S    LD_USER
         JSR      FCLOSE
         TXSTR    {'Not found'}
         MOVEQ    #50,D3
         JMP      PAUSE

PREVUSER MOVEQ    #-1,D4
         BRA.S    GETUSER
NEXTUSER MOVEQ    #1,D4
GETUSER  BSR.S    WR_USER1
         ADD.W    D4,D6
         IF LT THEN
            MOVEQ    #0,D6
            TXSTR    {'Start of user file'}
            MOVEQ    #50,D3
            JSR      PAUSE
         ENDIF
         BSR      OPU_FIN
         MOVEQ    #-1,D3
         MOVE.L   D6,D1
         MULU     #US_LEN,D1
         QDOS     FS.POSAB
         TST.L    D0
         IF NE THEN
            MOVE.L   #-US_LEN,D1
            QDOS     FS.POSRE
            TXSTR    {'End of user file'}
            MOVEQ    #50,D3
            JSR      PAUSE
         ENDIF
LD_USER  MOVEQ    #0,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSRE
         MOVE.L   D1,D6
         MOVE.W   #US_LEN,D2
         DIVU     D2,D6
         LEA      USERBUF2(A6),A1
         QDOS     IO.FSTRG
         JSR      FCLOSE
         ADDQ.W   #4,A7
         BRA      UP_NEW

CH_ULIST BSR      USERLIST
         JMP      ASK_ENTR

CH_QUIT  ADDQ.W   #4,A7
WR_USER1 TST.B    D7
         BEQ.S    NOCHANGE
         MOVE.W   D6,D1
         IF LT THEN
            LEA      USERBUF2(A6),A1
            LEA      USERBUF(A6),A2
            MOVEQ    #US_LEN/4,D0
            REPEAT
               MOVE.L   (A1)+,(A2)+
               SUBQ.W   #1,D0
            UNTIL    EQ
            MOVE.W   USERPOS(A6),D1
         ENDIF
         LEA      USERBUF2(A6),A1
         BSR.S    WR_USER
         IF NE THEN
            LEA      LOGBUF(A6),A1
            WRITE$   {'? Can''t update USERS_BBS: '},A1
            JSR      WRITEERR
            CLR.B    -1(A1)
            JSR      LOG0
         ENDIF
NOCHANGE RTS

* Locate user by name
* Entry: USERS_BBS open, A1 name to search, A2 buffer loc
* Exit : D0 status, D1 USERS_BBS rec, D2 record length, D3=-1, A1-A2 preserved

         XDEF     FINDUSER

FINDUSER MOVE.L   INPCHAN(A6),A0
         MOVE.W   #US_LEN,D2
         MOVEQ    #-1,D3
         MOVE.L   A1,-(A7)
FU_LOOP  MOVE.L   A2,A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    FU_END
         MOVE.L   (A7),A1
         JSR      CMPNAME
         BNE      FU_LOOP
         MOVE.L   #-US_LEN,D1
         QDOS     FS.POSRE
         DIVU     D2,D1
FU_END   MOVE.L   (A7)+,A1
         TST.L    D0
         RTS

* Write user record
* Entry: D1 USERS_BBS rec, A1 ptr to record

         XDEF     WR_USER

WR_USER  MOVEM.L  D1/A1,-(A7)
         LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FILE
         BNE.S    WR_U_RTS
         MOVE.L   (A7)+,D1
         MOVE.W   #US_LEN,D2
         MULU     D2,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVE.L   (A7)+,A1
         TST.L    D0
         IF EQ THEN
            QDOS     IO.SSTRG
         ENDIF
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         MOVE.L   (A7)+,D0
WR_U_RTS RTS

         SECTION  MSG
WIDTHMSG STRING$  {'New screen width: '}
LINESMSG STRING$  {'Number of lines: '}
         SECTION  CODE

* STRING SEARCH ROUTINE (A1 INSTR A2)

         XDEF     FINDSTR1,FINDSTR2

FINDSTR1 MOVEM.L  D1-D5/A2-A4,-(A7)
         MOVE.B   (A1)+,D1
         MOVE.B   (A2)+,D2
         BRA.S    FINDSTR
FINDSTR2 MOVEM.L  D1-D5/A2-A4,-(A7)
FINDSTR  TST.B    D1
         BEQ.S    FS_MATCH
         SUB.B    D1,D2
         BCS.S    FS_NOMAT
         ANDI.W   #$FF,D2
         MOVEQ    #$DF,D5
         SUBQ.B   #1,D1
         MOVEQ    #0,D4
         MOVE.B   D1,D4
FS_CMP   MOVE.W   D4,D3
         MOVE.L   A1,A3
         MOVE.L   A2,A4
FS_CLOOP MOVE.B   (A3)+,D0
         MOVE.B   (A4)+,D1
         EOR.B    D0,D1
         AND.B    D5,D1
         DBNE     D3,FS_CLOOP
         BEQ.S    FS_MATCH
         ADDQ.W   #1,A2
         DBF      D2,FS_CMP
FS_NOMAT MOVEQ    #-1,D0
         BRA.S    FS_END
FS_MATCH MOVE.L   A2,A1
         MOVEQ    #0,D0
FS_END   MOVEM.L  (A7)+,D1-D5/A2-A4
         TST.L    D0
         RTS

         XDEF     USERLIST

USERLIST LOG      {'Users list',LF}
         MOVEQ    #US.NMAX,D2
         LEA      BUFFER+71(A6),A1
         INPUT    {'Name or part of name to match (<ENTER> = all): '}
         SUBQ.W   #1,D1
         MOVE.B   D1,-(A1)
         BSR      OPU_FIN
         JSR      TXCRLF
         MOVEQ    #0,D5
         REPEAT
            MOVE.L   INPCHAN(A6),A0
            LEA      BUFFER+110(A6),A1
            MOVE.W   #US_LEN,D2
            MOVEQ    #-1,D3
            QDOS     IO.FSTRG
            TST.L    D0
            EXITIF   NE
            SUBA.W   D2,A1
            TST.B    (A1)
            IF NE THEN
               MOVE.L   A1,A2
               LEA      BUFFER+70(A6),A1
               BSR      FINDSTR1
               IF EQ THEN
                  MOVE.L   A2,A1
                  LEA      BUFFER(A6),A2
                  MOVEQ    #26,D1
                  BSR.S    COPYSPC
                  LEA      BUFFER+110+US_CITY(A6),A1
                  MOVEQ    #18,D1
                  BSR.S    COPYSPC
                  MOVE.L   BUFFER+110+US_LSTLG(A6),D1
                  MOVE.L   A2,A1
                  JSR      DATE$
                  LEA      BUFFER(A6),A1
                  MOVEQ    #26+18,D1
                  ADD.W    D2,D1
                  REPEAT
                     JSR      TXLINE
                     BLT.S    UL_END
                  UNTIL LE
               ENDIF
            ENDIF
         FOREVER
UL_END   JMP      FCLOSE

         XDEF     COPYSPC

COPYSPC  MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         SUB.W    D0,D1
         BGE.S    COPYSPC3
         ADD.W    D1,D0
         MOVEQ    #0,D1
         BRA.S    COPYSPC3
COPYSPC2 MOVE.B   (A1)+,(A2)+
COPYSPC3 DBF      D0,COPYSPC2
         BRA.S    COPYSPC5
COPYSPC4 MOVE.B   #' ',(A2)+
COPYSPC5 DBF      D1,COPYSPC4
         RTS

         XDEF     SELMAREA,SELFAREA

SELMAREA MOVEM.L  D2-D7/A0-A3,-(A7)
         LEA      MAREAMSG,A2
         LEA      USERBUF+US_MAREA(A6),A3
         MOVE.L   USERBUF+US_MACCS(A6),D7
         BRA.S    SA_PRMPT
SELFAREA MOVEM.L  D2-D7/A0-A3,-(A7)
         LEA      FAREAMSG,A2
         LEA      USERBUF+US_FAREA(A6),A3
         MOVE.L   USERBUF+US_FACCS(A6),D7
SA_PRMPT MOVE.W   (A2),D0
         LEA      (A2,D0.W),A0
         LEA      BUFFER(A6),A1
         MOVEQ    #4,D2
         JSR      INPUT
         SUBQ.B   #1,D1
         BLE      SEL_A_EN
         JSR      READNUM
         BNE.S    SA_LIST
         BSR      SET_AREA
         BNE      SA_PRMPT
         MOVE.B   D1,(A3)
         SUBQ.B   #1,(A3)
         BRA      SEL_A_EN
SA_LIST  MOVE.W   2(A2),D0
         LEA      (A2,D0.W),A1
         JSR      TXSTR
         MOVE.W   4(A2),D0
         LEA      (A2,D0.W),A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BNE      OP_ERR2
         MOVEQ    #1,D4
         MOVEQ    #2,D5
SA_LOOP  MOVEQ    #127,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    SA_D_END
         SUBQ.W   #1,D1
         BEQ.S    SA_NEXT
         MOVE.L   A1,D6
         BSR      CHK_AREA
         BNE.S    SA_NEXT
         MOVE.B   #' ',-(A1)
         MOVE.B   #'.',-(A1)
         MOVE.B   #'.',-(A1)
         MOVE.B   #'.',-(A1)
         MOVE.B   #' ',-(A1)
         MOVE.W   D4,D1
         MOVEQ    #3,D2
         SUBA.W   D2,A1
         MOVEQ    #' ',D3
         JSR      ITOD.W
         SUBA.W   D2,A1
         MOVE.L   D6,D1
         SUB.L    A1,D1
         SUBQ.W   #1,D1
         MOVE.W   D4,-(A7)
SA_DLP   JSR      TXLINE
         BGT.S    SA_DLP
         MOVE.W   (A7)+,D4
         TST.L    D0
         BLT.S    SA_D_END
SA_NEXT  ADDQ.W   #1,D4
         CMPI.W   #MAXAREA,D4
         BLE      SA_LOOP
SA_D_END JSR      FCLOSE
         JSR      TXCRLF
         BRA      SA_PRMPT
SEL_A_EN MOVEM.L  (A7)+,D2-D7/A0-A3
         RTS

         XDEF     SETMAREA,SETFAREA

SETMAREA LEA      MAREAMSG,A2
         LEA      USERBUF+US_MAREA(A6),A3
         MOVE.L   USERBUF+US_MACCS(A6),D7
         BRA.S    SA_2
SETFAREA LEA      FAREAMSG,A2
         LEA      USERBUF+US_FAREA(A6),A3
         MOVE.L   USERBUF+US_FACCS(A6),D7
SA_2     MOVEQ    #0,D1
         MOVE.B   (A3),D1
         ADDQ.W   #1,D1
         BSR.S    SET_AREA
         BEQ.S    SMA_STO
         MOVEQ    #1,D1
         MOVEQ    #-1,D7
         BSR.S    SET_AREA
SMA_STO  MOVE.B   D1,(A3)
         SUBQ.B   #1,(A3)
         RTS

* Select message- or file area
* Entry: D1 area number, D7 group flags, A2 pointer to msg/file description
* Exit:  D0 <> 0 if invalid area

         XDEF     SET_AREA

SET_AREA MOVE.W   D1,D6
         CMPI.W   #MAXAREA,D1
         BHI      SA_INV
         MOVE.W   D1,D4
         MOVE.W   4(A2),D0
         LEA      (A2,D0.W),A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BNE      OP_ERR2
         MOVEQ    #127,D2
         MOVEQ    #-1,D3
SA_LOOP2 LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         CMPI.L   #ERR.EF,D0
         BEQ      SA_INV2
         TST.L    D0
         BNE      IO_ERROR
         SUBQ.W   #1,D4
         BGT      SA_LOOP2
         SUBQ.W   #1,D1
         BEQ      SA_INV2
         JSR      FCLOSE
         BSR      CHK_AREA
         BNE      SA_INV
         MOVE.B   D1,A_GROUP(A6)
         MOVE.L   S_MYADDR(A6),MYZONE(A6)
         MOVE.L   S_MYADDR+4(A6),MYNODE(A6)
         LEA      BUFFER(A6),A1
         LEA      DIRBUF+2(A6),A0
SA_COPY1 MOVE.B   (A1),D0
         CMPI.B   #' ',D0
         BLE.S    SA_STDIR
         ADDQ.W   #1,A1
         MOVE.B   D0,(A0)+
         BRA      SA_COPY1
SA_STDIR MOVE.L   A0,D0
         LEA      DIRBUF+2(A6),A0
         SUB.L    A0,D0
         MOVE.W   D0,-(A0)
         SF       ISNET(A6)
         SF       ISECHO(A6)
         SF       ISPRIV(A6)
         SF       ALT_DIR(A6)
SA_FLOOP JSR      SKIPSPC
         BEQ.S    SA_DESC
         CMPI.B   #'-',(A1)
         BEQ.S    SA_FLAG
         CMPI.B   #'/',(A1)
         BNE.S    SA_DESC
SA_FLAG  MOVE.B   1(A1),D1
         JSR      TOUPPER
         CMPI.B   #'N',D1
         BNE.S    SA_ECHO
         ST       ISNET(A6)
         BRA.S    SA_SKIP
SA_ECHO  CMPI.B   #'E',D1
         BNE.S    SA_PRIV
         ST       ISECHO(A6)
         BRA.S    SA_SKIP
SA_PRIV  CMPI.B   #'P',D1
         BNE.S    SA_ADDR
         ST       ISPRIV(A6)
         BRA.S    SA_SKIP
SA_ADDR  CMPI.B   #'A',D1
         BNE.S    SA_SKIP
         ADDQ.W   #2,A1
         CMPI.B   #'=',(A1)
         BNE.S    SA_SKIP
         ADDQ.W   #1,A1
         MOVEM.W  MYZONE(A6),D2-D5
         JSR      A2ZNNP
         MOVEM.W  D2-D5,MYZONE(A6)
SA_SKIP  CMPI.B   #' ',(A1)
         BLE.S    SA_FLOOP
         ADDQ.W   #1,A1
         BRA      SA_SKIP
SA_DESC  LEA      AREANAME+2(A6),A0
         MOVEQ    #0,D1
SA_COPY2 MOVE.B   (A1)+,D0
         CMPI.B   #LF,D0
         BEQ.S    SA_STLEN
         MOVE.B   D0,(A0)+
         ADDQ.W   #1,D1
         CMPI.W   #60,D1
         BLT      SA_COPY2
SA_STLEN MOVE.W   D1,AREANAME(A6)
         MOVE.W   D6,D1
         MOVE.W   D1,CUR_AREA(A6)
         MOVE.W   6(A2),D0
         LEA      (A2,D0.W),A0
         LEA      LOGBUF(A6),A1
         WRITE$
         MOVEQ    #0,D2
         JSR      ITOD.W
         CLR.B    (A1)
         JSR      LOG0
         MOVEQ    #0,D0
         RTS
SA_INV2  JSR      FCLOSE
SA_INV   MOVEQ    #-1,D0
         RTS

* Check area group
* Entry: D7 group flags, BUFFER containing ?AREAS_BBS record
* Exit:  D0.B <> 0 if no access, D1 group letter (uppercased)
*        A1 start of area description

         XDEF     CHK_AREA

CHK_AREA LEA      BUFFER(A6),A1
         MOVEQ    #0,D0
CHK_SKIP MOVEQ    #0,D1
         CMPI.B   #LF,(A1)
         BEQ.S    CHK_OK
         CMPI.B   #' ',(A1)+
         BNE      CHK_SKIP
         JSR      SKIPSPC
         BEQ.S    CHK_OK
         CMPI.B   #'-',(A1)
         BEQ.S    CHK_G
         CMPI.B   #'/',(A1)
         BNE.S    CHK_OK
CHK_G    TST.B    D0
         BNE      CHK_SKIP
         MOVE.B   1(A1),D1
         JSR      TOUPPER
         CMPI.B   #'G',D1
         BNE      CHK_SKIP
         CMPI.B   #'=',2(A1)
         BNE      CHK_SKIP
         MOVE.B   3(A1),D1
         JSR      TOUPPER
         MOVE.B   D1,D0
         SUBI.B   #'A',D0
         CMPI.B   #'Z'-'A',D0
         BHI.S    CHK_SKIP
         BTST     D0,D7
         SEQ      D0
         BRA      CHK_SKIP
CHK_OK   TST.B    D0
         RTS

* Process commandline for external programs (called from EXEC)

         XDEF     EXT_CMDL

EXT_CMDL MOVE.L   A0,-(A7)
         MOVE.L   A1,A4
         LEA      BUFFER+6(A6),A1
         LEA      $7FFA(A1),A5
         MOVE.B   #' ',(A1)+
         MOVEQ    #0,D5
         MOVE.W   D1,D7
EL_LOOP  SUBQ.W   #1,D7
         BLT.S    EL_END1
         MOVE.B   (A4)+,D1
         CMPI.B   #'%',D1
         BEQ.S    EL_TRANS
EL_COPY  MOVE.B   D1,(A1)+
         BRA      EL_LOOP
EL_TRANS SUBQ.W   #1,D7
         BLT.S    EL_END1
         MOVEQ    #0,D1
         MOVE.B   (A4)+,D1
         LEA      TRANSTAB-2,A0
EL_TLP   ADDQ.L   #2,A0
         MOVE.W   (A0)+,D0
         BEQ      EL_COPY
         CMP.B    D0,D1
         BNE      EL_TLP
         ADDA.W   (A0),A0
         JSR      (A0)
         BRA      EL_LOOP
EL_END1  MOVE.B   #LF,(A1)+
         MOVE.L   A1,D1
         LEA      BUFFER(A6),A1
         MOVE.W   D5,-(A5)
         MOVE.L   A5,(A1)+
         SUB.L    A1,D1
         SUBQ.W   #2,D1
         MOVE.W   D1,(A1)
         MOVE.L   A1,A2
         LOG      {'+ External program: '}
         MOVE.L   (A7)+,A1
         JSR      LOG1
         MOVE.L   A2,A1
         JSR      LOG1
         LEA      3(A2),A1
         SUBQ.W   #2,D1
         MOVEQ    #0,D0
         RTS

TRANSTAB DC.W     ' <'
         DC.W     T_OPENIN-*
         DC.W     ' >'
         DC.W     T_OPENOU-*
         DC.W     ' a'
         DC.W     T_MAREA-*
         DC.W     ' A'
         DC.W     T_FAREA-*
         DC.W     ' b'
         DC.W     T_BAUD-*
         DC.W     ' c'
         DC.W     T_CITY-*
         DC.W     ' e'
         DC.W     T_PWD-*
         DC.W     ' f'
         DC.W     T_FFILE-*
         DC.W     ' j'
         DC.W     T_ONLINE-*
         DC.W     ' l'
         DC.W     T_SCRLEN-*
         DC.W     ' m'
         DC.W     T_MORE-*
         DC.W     ' n'
         DC.W     T_NAME-*
         DC.W     ' N'
         DC.W     T_SYSTEM-*
         DC.W     ' s'
         DC.W     T_SYSOP-*
         DC.W     ' t'
         DC.W     T_TMLEFT-*
         DC.W     ' u'
         DC.W     T_RECNUM-*
         DC.W     ' w'
         DC.W     T_WIDTH-*
         DC.W     ' W'
         DC.W     T_WRKFIL-*
         DC.W     ' x'
         DC.W     T_XINFO-*
         DC.W     0

T_MAREA  MOVE.B   USERBUF+US_MAREA(A6),D1
         BRA.S    T_PLUS1
T_FAREA  MOVE.B   USERBUF+US_FAREA(A6),D1
         BRA.S    T_PLUS1
T_ONLINE MOVEQ    #0,D0
         JSR      CHKTIME
         BRA.S    T_NUM
T_SCRLEN MOVEQ    #$7F,D1
         AND.B    USERBUF+US_LINES(A6),D1
         BRA.S    T_NUM
T_TMLEFT MOVEQ    #0,D0
         JSR      CHKTIME
         MOVE.W   D0,D1
         BRA.S    T_NUM
T_RECNUM MOVE.W   USERPOS(A6),D1
         BRA.S    T_NUM
T_WIDTH  MOVE.B   USERBUF+US_WIDTH(A6),D1
T_PLUS1  ADDQ.W   #1,D1
T_NUM    MOVEQ    #0,D2
         JMP      ITOD.W

T_CITY   LEA      USERBUF+US_CITY(A6),A0
         BRA.S    T_STR1
T_PWD    LEA      USERBUF+US_PASSW(A6),A0
         BRA.S    T_STR1
T_NAME   LEA      USERBUF+US_NAME(A6),A0
T_STR1   JMP      WRNAME

T_BAUD   MOVEQ    #-1,D1
         TST.B    LOCALMOD(A6)
         BNE.S    T_BAUD2
         MOVE.B   BPS(A6),D1
T_BAUD2  EXT.W    D1
         ADD.W    D1,D1
         LEA      SPEEDS,A0
         ADDA.W   (A0,D1.W),A0
         BRA.S    T_STR2
T_SYSTEM LEA      S_SYSNAM(A6),A0
         BRA.S    T_STR2
T_SYSOP  LEA      S_SYSOP(A6),A0
         BRA.S    T_STR2
T_WRKFIL LEA      S_MSGTMP(A6),A0
         BSR.S    T_STR2
         LEA      TMSGFNAM,A0
         BRA.S    T_STR2
T_XINFO  MOVE.L   CON_XTRA(A6),A0
         MOVE.L   A0,D0
         BNE.S    T_STR2
         LOAD$    {'/NONE'},A0
         BRA.S    T_STR2
T_MORE   MOVEQ    #$80-$100,D1
         AND.B    USERBUF+US_MORE(A6),D1
T_ONOFF  LOAD$    {'ON'},A0
         TST.B    D1
         BNE.S    T_STR2
         LOAD$    {'OFF'},A0
T_STR2   WRITE$
         RTS


T_FFILE  LEA      DIRBUF(A6),A0
         WRITE$
         TST.B    FXBATCH(A6)
         BNE.S    TF_BATCH
         LEA      FILENAME(A6),A0
         WRITE$
         BRA.S    TF_END
TF_BATCH MOVE.L   FILE_Q(A6),A2
         MOVE.L   A2,D0
         BNE.S    TF_BLP2
         BRA.S    TF_END
TF_BLP   MOVE.L   (A2),A2
         MOVE.B   #' ',(A1)+
         LEA      DIRBUF(A6),A0
         WRITE$
TF_BLP2  LEA      14(A2),A0
         WRITE$
         TST.L    (A2)
         BNE      TF_BLP
TF_END   RTS

T_OPENIN TST.W    D7
         BLE.S    T_INCHAN
         MOVEQ    #IO.SHARE,D3
         CMPI.B   #' ',(A4)
         BHS.S    T_FNAME
T_INCHAN MOVE.L   COM_IN(A6),-(A5)
         BRA.S    T_CHAN

T_OPENOU TST.W    D7
         BLE.S    T_OCHAN
         MOVEQ    #IO.OVER,D3
         CMPI.B   #' ',(A4)
         BEQ.S    T_OCHAN
         CMPI.B   #'>',(A4)
         BNE.S    T_FNAME
         SUBQ.W   #1,D7
         ADDQ.L   #1,A4
         MOVEQ    #IO.EXCL,D3
T_FNAME  MOVEQ    #0,D2
         MOVE.L   A4,A0
T_FNAMLP SUBQ.W   #1,D7
         BLT.S    T_FNAMEN
         ADDQ.W   #1,D2
         CMPI.B   #' ',(A4)+
         BNE      T_FNAMLP
         ADDQ.W   #1,D7
         SUBQ.W   #1,D2
         SUBQ.L   #1,A4
T_FNAMEN TST.W    D2
         BEQ.S    T_OCHAN
         CMPI.W   #3,D2
         BNE.S    T_FNAM2
         MOVEQ    #0,D1
         MOVE.B   (A0),D1
         LSL.W    #8,D1
         MOVE.B   1(A0),D1
         LSL.L    #8,D1
         MOVE.B   2(A0),D1
         ORI.L    #$20202020,D1
         CMPI.L   #' log',D1
         BNE.S    T_FNAM2
         MOVE.L   LOGFILE(A6),-(A5)
         BRA.S    T_CHAN
T_FNAM2  MOVEQ    #3,D1
         ADD.W    D2,D1
         BCLR     #0,D1
         SUBA.W   D1,A5
         MOVE.L   A5,A2
         MOVE.B   D3,(A2)+
         MOVE.B   D2,(A2)+
T_FNAM3  MOVE.B   (A0)+,(A2)+
         SUBQ.W   #1,D2
         BGT      T_FNAM3
         BRA.S    T_INC
T_OCHAN  MOVE.L   COM_OUT(A6),-(A5)
T_CHAN   MOVE.W   #-1,-(A5)
T_INC    ADDQ.W   #1,D5
         RTS

         XDEF     EXT_CHAN

EXT_CHAN MOVE.L   BUFFER(A6),A4
         MOVE.W   (A4)+,D4
         ADD.W    D4,D5
         MOVE.W   D4,D0
         LSL.W    #2,D0
         SUBA.W   D0,A5
         MOVE.L   A5,A3
         BRA.S    EC_NEXT
EC_LOOP  MOVE.B   (A4),D3
         BPL.S    EC_FILE
         ADDQ.L   #2,A4
         MOVE.L   (A4)+,(A3)+
         BRA.S    EC_NEXT
EC_FILE  CLR.B    (A4)
         MOVE.L   A4,A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    EC_OK
         CMPI.L   #ERR.NF,D0
         BNE.S    EC_ERR
         CMPI.B   #IO.EXCL,D3
         BNE.S    EC_ERR
         MOVEQ    #IO.NEW,D3
         MOVE.L   A4,A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    EC_ERR
         BRA.S    EC_CHAN
EC_OK    CMPI.B   #IO.EXCL,D3
         BNE.S    EC_CHAN
         MOVE.L   D1,-(A7)
         MOVE.L   #9999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVE.L   (A7)+,D1
EC_CHAN  MOVE.L   A0,(A3)+
         MOVE.W   (A4)+,D0
         ADDQ.W   #1,D0
         BCLR     #0,D0
         ADDA.W   D0,A4
EC_NEXT  DBF      D4,EC_LOOP
         MOVEQ    #0,D0
         RTS
EC_ERR   LEA      LOGBUF(A6),A1
         WRITE$   {'? Can''t open file '},A1
         MOVE.L   A4,A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      WRITEERR
         CLR.B    -1(A1)
         JMP      LOG0

         XDEF     EXT_RET

EXT_RET  LEA      LOGBUF(A6),A1
         WRITE$   {'+ Returned from external program ('}
         TST.L    D0
         BGT.S    EXT_R2
         BLT.S    EXT_R3
         WRITE$   'OK'
         BRA.S    EXT_R4
EXT_R2   MOVE.L   D0,D1
         MOVEQ    #0,D3
         JSR      ITOD.L
         BRA.S    EXT_R4
EXT_R3   JSR      WRITEERR
         SUBQ.L   #1,A1
EXT_R4   MOVE.B   #')',(A1)+
         CLR.B    (A1)+
         JSR      LOG0
         TST.L    D0
         RTS

         SECTION  MSG

         XDEF     MAREAMSG

MAREAMSG DC.W     MAREA_M1-MAREAMSG
         DC.W     MAREA_M2-MAREAMSG
         DC.W     MAREA_M3-MAREAMSG
         DC.W     MAREA_M4-MAREAMSG
MAREA_M1 STRING$  {'Message area ("?" for list): '}
MAREA_M2 STRING$  {CR,LF,'----- MESSAGE AREAS -----',CR,LF}
MAREA_M3 STRING$  'MAREAS_BBS'
MAREA_M4 STRING$  {'Message area '}
FAREAMSG DC.W     FAREA_M1-FAREAMSG
         DC.W     FAREA_M2-FAREAMSG
         DC.W     FAREA_M3-FAREAMSG
         DC.W     FAREA_M4-FAREAMSG
FAREA_M1 STRING$  {'File area ("?" for list): '}
FAREA_M2 STRING$  {CR,LF,'----- FILE AREAS -----',CR,LF}
FAREA_M3 STRING$  'FAREAS_BBS'
FAREA_M4 STRING$  {'File area '}

         END
