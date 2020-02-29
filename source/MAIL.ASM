** QBOX MAILBOX ROUTINES **

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         DATA     0

         XDEF     MAILBOX,LOOKMAIL,WRITEMSG

         XREF     LOG,OP_FILE,OP_FIN,USERLIST,SETMAREA,SELMAREA,COMPSTR
         XREF     IO_ERROR,FCLOSE,TXSTR,TXCRLF,TXLF,TXNUMBER,FLUSH,EXEC,WRNAME
         XREF     TXCHAR,TOUPPER,GETCHAR,INDEXER,GETLINE,DO_OUTP,ASKMORE
         XREF     INPUT,GETNAM1,GETNAM2,CMPNAME,COPYNAME,PRINTNAM,TXLINE2
         XREF     YESNO,NOYES,GETLIN1,TXLINE,DATE$,DATE,ITOD.W,LOGOFF,OPENSUB1
         XREF     FINDUSER,READNUM,USLSTFNM,MSG_FNAM,FINDSTR2,IN_DISPL,IN_LKUP
         XREF     ZNNP2A,MAIN,A2ZNNP,SKIPSPC,LOG0,OP_ERROR,TMSGFNAM,EXT_RET
         XREF     ORIGFNAM,OPEN_SUB,OP_FOVER,STATS,AKAMATCH,EXT_CMDL,EXT_CHAN
         XREF     WRITE$,WRITEL$

         SECTION  CODE

OPM_EXCL LEA      OP_FILE,A2
         BRA.S    OPEN_MSG
OPM_IN   LEA      OP_FIN,A2
OPEN_MSG LEA      MSG_FNAM,A0
         LEA      DIRBUF(A6),A1
         JSR      (A2)
         BNE.S    OPM_ERR
         RTS
OPM_ERR  MOVE.L   D0,-(A7)
         TXSTR    {CR,LF,'*** ERROR: Unable to open message base - please notify sysop!',CR,LF}
         MOVE.L   (A7)+,D0
         JMP      OP_ERROR

LOOKMAIL LOG      {'Mailbox scan',LF}
         TXSTR    {'Scanning messages...',CR,LF,LF}
         JSR      FLUSH
         BSR      OPM_IN
         LEA      BUFFER(A6),A3
         LEA      256(A3),A4
         LEA      256(A4),A5
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         MOVEQ    #0,D6
         MOVEQ    #0,D7
         MOVE.B   D1,D7
         BRA.S    CKMAIL_N
CKMAIL   MOVE.B   D6,D1
         BSR      GET_MSGP
         BLT.S    CKMAIL_N
         QDOS     FS.POSAB
         LEA      MSGHDR(A6),A1
         MOVEQ    #MS_TOUSR,D2
         BSR      CM_FSTRG
         LEA      TOUSER(A6),A1
         BSR      CM_FNAME
         LEA      FROMUSER(A6),A1
         BSR      CM_FNAME
         LEA      TOUSER(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      CMPNAME
         SEQ      D5
         LEA      FROMUSER(A6),A1
         JSR      CMPNAME
         IF EQ THEN
            MOVE.B   D6,(A5)+
         ENDIF
         TST.B    D5
         IF NE THEN
            MOVE.W   MSGHDR+MS_ATTR(A6),D0
            BTST     #MS..RCVD,D0
            IF EQ THEN
               MOVE.B   D6,(A3)+
            ELSE
               MOVE.B   D6,(A4)+
            ENDIF
         ENDIF
CKMAIL_N ADDQ.W   #1,D6
         CMP.W    D7,D6
         BLE      CKMAIL
         CLR.B    (A3)
         CLR.B    (A4)
         CLR.B    (A5)
         JSR      FCLOSE
         TXSTR    {'New messages to you: '}
         LEA      BUFFER(A6),A4
         BSR.S    DISPMAIL
         TXSTR    {'Old messages to you: '}
         LEA      BUFFER+256(A6),A4
         BSR.S    DISPMAIL
         TXSTR    {'Messages you have entered: '}
         LEA      BUFFER+512(A6),A4
DISPMAIL TST.B    (A4)
         BEQ.S    NOMAIL
DMAIL_LP MOVE.B   (A4)+,D1
         BSR      PRINTNUM
         TST.B    (A4)
         BEQ.S    DMAIL_EN
         TXSTR    {', '}
         BRA      DMAIL_LP
NOMAIL   TXSTR    {'NONE'}
DMAIL_EN CLR.L    MSGHDR+MS_DATE(A6)
         JMP      TXCRLF

SAV_ORIG LEA      OF_ADDR(A6),A0
         LEA      FROMUSER(A6),A1
         LEA      ORIGFROM(A6),A2
         JSR      COPYNAME
         MOVE.L   MSGHDR+MS_OZONE(A6),(A0)+
         MOVE.L   MSGHDR+MS_ONODE(A6),(A0)+
         LEA      TOUSER(A6),A1
         LEA      ORIGTO(A6),A2
         JSR      COPYNAME
         MOVE.L   MSGHDR+MS_DZONE(A6),(A0)+
         MOVE.L   MSGHDR+MS_DNODE(A6),(A0)+
         MOVE.L   MSGHDR+MS_DATE(A6),ORIGDATE(A6)
         RTS

GETFROM  TST.B    ISNET(A6)
         BEQ.S    GF_NAME
         MOVEQ    #25,D2
         LEA      BUFFER(A6),A1
         INPUT    {'New origin address (<ENTER> = no change): '}
         SUBQ.W   #1,D1
         BLE.S    GF_NAME
         MOVEM.W  MSGHDR+MS_OZONE(A6),D2-D5
         JSR      A2ZNNP
         BEQ.S    GF_ADDOK
         TXSTR    {CR,LF,'Invalid address!',CR,LF}
         BRA      GETFROM
GF_ADDOK MOVEM.W  D2-D5,MSGHDR+MS_OZONE(A6)
GF_NAME  MOVEQ    #US.NMAX,D2
         LEA      BUFFER+1(A6),A1
         INPUT    {'New "From:" name (<ENTER> = no change): '}
         SUBQ.W   #1,D1
         BLE.S    GF_END
         MOVE.B   D1,-(A1)
         LEA      FROMUSER(A6),A2
         JSR      COPYNAME
GF_END   RTS

GETDEST  MOVEM.L  D1-D5/A0-A2,-(A7)
GD_AGAIN TST.B    ISNET(A6)
         BEQ      GD_NAME
         TXSTR    {'Destination network address'}
         LEA      MSGHDR+MS_DZONE(A6),A2
         TST.L    (A2)
         IF NE THEN
            LEA      BUFFER(A6),A1
            MOVE.B   #' ',(A1)+
            MOVE.B   #$5B,(A1)+
            JSR      ZNNP2A
            MOVE.B   #']',(A1)+
            ADDQ.W   #3,D2
            LEA      BUFFER(A6),A1
            MOVEQ    #SP.SSTRG,D0
            JSR      DO_OUTP
         ENDIF
         TXSTR    {': '}
         MOVEQ    #25,D2
         SUBA.L   A0,A0
         LEA      BUFFER(A6),A1
         JSR      INPUT
         SUBQ.W   #1,D1
         BNE.S    GD_ADDR
         TST.L    MSGHDR+MS_DZONE(A6)
         BEQ      DSTABORT
         BRA.S    GD_NAME
GD_ADDR  MOVEM.W  MSGHDR+MS_DZONE(A6),D2-D5
         TST.W    D2
         IF EQ THEN
            MOVEM.W  MYZONE(A6),D2-D5
         ENDIF
         JSR      A2ZNNP
         BEQ.S    GD_ADDOK
         TXSTR    {CR,LF,'Invalid address!',CR,LF}
         BRA      GD_AGAIN
GD_ADDOK MOVEM.W  D2-D5,MSGHDR+MS_DZONE(A6)
         JSR      AKAMATCH
         MOVEM.W  D2-D5,MSGHDR+MS_OZONE(A6)
GD_NAME  MOVEQ    #US.NMAX,D2
         LEA      BUFFER+82(A6),A1
         WRITE$   {'To user'},A1
         MOVE.L   A1,A0
         LEA      TOUSER(A6),A1
         SF       D0
         LEA      GETNAM2,A2
         BSR      TS_PRMPT
         LEA      BUFFER(A6),A2
         LEA      TOUSER(A6),A1
         TST.B    (A2)
         BNE.S    GD_CHKNM
         TST.B    (A1)
         BEQ      DSTABORT
         JSR      COPYNAME
GD_CHKNM TST.B    ISNET(A6)
         BNE      DEST_OK
         LEA      BUFFER(A6),A1
         CMPI.B   #5,(A1)+
         BNE.S    GD_CHKN2
         LOAD$    {'SYSOP'},A0
         JSR      COMPSTR
         BNE.S    GD_CHKN2
         TXSTR    {'Message routed to system operator '}
         LEA      S_SYSOP+1(A6),A1
         JSR      PRINTNAM
         JSR      TXCRLF
         LEA      S_SYSOP+1(A6),A1
         BRA      DEST_OK2
GD_CHKN2 TST.B    ISNET(A6)
         BNE      DEST_OK
         TST.B    ISECHO(A6)
         BNE      DEST_OK
         TXSTR    {'Checking name...',CR,LF}
         LEA      USLSTFNM,A0
         LEA      S_SYSDIR(A6),A1
         JSR      OP_FIN
         BNE      OPM_ERR
         LEA      BUFFER(A6),A1
         SUBA.W   #US_LEN,A7
         MOVE.L   A7,A2
         JSR      FINDUSER
         ADDA.W   #US_LEN,A7
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         TST.L    (A7)+
         BEQ.S    DEST_OK
         TXSTR    {'*** WARNING ***',CR,LF}
         TXSTR    {'This name is NOT in the user list!',CR,LF}
DST_RPLY TXSTR    {$5B,'A]bort, ',$5B,'R]etry, ',$5B,'I]gnore, ',$5B,'U]ser list: '}
         JSR      GETCHAR
         ANDI.B   #$DF,D1
         MOVE.B   D1,D2
         JSR      TXCHAR
         JSR      TXCRLF
         CMPI.B   #'A',D2
         BEQ.S    DSTABORT
         CMPI.B   #'R',D2
         BEQ      GD_AGAIN
         CMPI.B   #'I',D2
         BEQ.S    DEST_OK
         CMPI.B   #'U',D2
         BNE      DST_RPLY
         JSR      USERLIST
         BRA      GD_NAME
DEST_OK  LEA      BUFFER(A6),A1
DEST_OK2 LEA      TOUSER(A6),A2
         JSR      COPYNAME
         MOVEM.L  (A7)+,D1-D5/A0-A2
         MOVEQ    #0,D0
         RTS
DSTABORT MOVEM.L  (A7)+,D1-D5/A0-A2
         MOVEQ    #-1,D0
         RTS

GET_SUBJ MOVEQ    #72,D2
         LEA      BUFFER+82(A6),A1
         WRITE$   {'Subject'},A1
         MOVE.L   A1,A0
         LEA      SUBJECT(A6),A1
         LEA      INPUT,A2
         BSR.S    TS_PRMPT
         SUBQ.W   #1,D1
         BLE.S    SUBJ_END
         LEA      SUBJECT(A6),A2
         MOVE.B   D1,(A2)+
SUBJCOPY MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      SUBJCOPY
SUBJ_END RTS

TS_PRMPT MOVE.B   (A1)+,D1
         BEQ.S    TSP_2
         MOVE.B   #' ',(A0)+
         MOVE.B   #$5B,(A0)+
TSP_LOOP MOVE.B   (A1)+,(A0)+
         SUBQ.B   #1,D1
         BGT      TSP_LOOP
         MOVE.B   #']',(A0)+
TSP_2    MOVE.B   #':',(A0)+
         MOVE.B   #' ',(A0)+
         MOVE.L   A0,D1
         LEA      BUFFER+82(A6),A0
         SUB.L    A0,D1
         MOVE.W   D1,-(A0)
         LEA      BUFFER(A6),A1
         JMP      (A2)

PRIVMSG2 TST.B    ISECHO(A6)
         BEQ.S    PRIVMSG
         TXSTR    {CR,LF,'This is an ECHOMAIL area.',CR,LF}
         TXSTR    {'Please use another area for PRIVATE messages!',CR,LF}
         RTS
PRIVMSG  TST.B    ISPRIV(A6)
         BNE.S    F_PRIV
         TXSTR    {'Private message'}
         BCLR     #MS..PRIV,MSGHDR+MS_ATTR+1(A6)
         IF NE THEN
            JSR      YESNO
         ELSE
            JSR      NOYES
         ENDIF
         IF EQ THEN
            BSET     #MS..PRIV,MSGHDR+MS_ATTR+1(A6)
            TXSTR    {'(Sysop can read private messages)',CR,LF}
         ENDIF
         RTS
F_PRIV   TXSTR    {'This area allows only PRIVATE messages',LF}
         RTS

REPLYMSG BSR      LOAD_CUR
         BNE      UPD_RTS
         MOVEQ    #-1,D6
         MOVE.W   D1,D6
         TXSTR    {'Adding a reply to #'}
         BSR      PRINTNUM
         JSR      TXCRLF
         LOG      {'Entering reply',LF}
         BSR      SAV_ORIG
         LEA      FROMUSER(A6),A1
         LEA      TOUSER(A6),A2
         JSR      COPYNAME
         LEA      USERBUF+US_NAME(A6),A1
         LEA      FROMUSER(A6),A2
         JSR      COPYNAME
         MOVEM.W  MSGHDR+MS_OZONE(A6),D2-D5
         MOVEM.W  D2-D5,MSGHDR+MS_DZONE(A6)
         TST.B    ISNET(A6)
         IF NE THEN
            JSR      AKAMATCH
         ELSE
            MOVEM.W  MYZONE(A6),D2-D5
         ENDIF
         MOVEM.W  D2-D5,MSGHDR+MS_OZONE(A6)
         ANDI.W   #%0000000000000001,MSGHDR+MS_ATTR(A6)
         ORI.W    #1<<MS..LOC,MSGHDR+MS_ATTR(A6)
         MOVE.B   D6,MSGHDR+MS_REPTO(A6)
         CLR.B    MSGHDR+MS_NXREP(A6)
         LOAD$    {'MSGID:'},A2
GET_ID   CLR.B    REPLY_ID(A6)
         LEA      MSG_BASE(A6),A1
LK_MSGID CMPA.L   A5,A1
         BHS      WM_ENTRY
         CMPI.B   #1,(A1)+
         BNE      WM_ENTRY
         MOVE.L   A2,A0
         JSR      COMPSTR
         BEQ.S    ISMSGID
WM_SKPKL CMPI.B   #CR,(A1)+
         BNE      WM_SKPKL
         BRA      LK_MSGID
ISMSGID  JSR      SKIPSPC
         BEQ      WM_ENTRY
         LEA      REPLY_ID(A6),A0
CP_REPL  MOVE.B   (A1)+,D0
         MOVE.B   D0,(A0)+
         CMPI.B   #CR,D0
         BNE      CP_REPL
         BRA      WM_ENTRY

UPDATMSG BSR      LOAD_CUR
         BNE.S    UPD_RTS
         MOVEQ    #0,D6
         MOVE.W   D1,D6
         BTST     #MS..SENT,MSGHDR+MS_ATTR+1(A6)
         IF NE THEN
            TXSTR    {'Message has been sent, do you want to re-send it'}
            JSR      NOYES
            BNE.S    UPD_RTS
         ENDIF
         TXSTR    {'Updating message #'}
         MOVE.W   D6,D1
         BSR      PRINTNUM
         JSR      TXCRLF
         LOG      {'Updating message',LF}
         BSR      SAV_ORIG
         ANDI.W   #%1111111111110011,MSGHDR+MS_ATTR(A6)
         MOVE.B   D6,MSGHDR+MS_NXREP(A6)
         LOAD$    {'REPLY:'},A2
         BRA      GET_ID
UPD_RTS  RTS
WRITEMSG MOVEQ    #0,D6
         TXSTR    {'Enter message',CR,LF}
         LOG      {'Entering message',LF}
         LEA      USERBUF+US_NAME(A6),A1
         LEA      FROMUSER(A6),A2
         JSR      COPYNAME
         CLR.B    TOUSER(A6)
         CLR.B    SUBJECT(A6)
         LEA      MSGHDR+MS_OZONE(A6),A1
         MOVE.L   MYZONE(A6),(A1)+  MS_OZONE & MS_ONET
         MOVE.L   MYNODE(A6),(A1)+  MS_ONODE & MS_OPNT
         CLR.L    (A1)+             MS_DZONE & MS_DNET
         CLR.L    (A1)+             MS_DNODE & MS_DPNT
         CLR.L    (A1)+             MS_ATTR  & MS_COST
         CLR.W    (A1)              MS_REPTO & MS_NXREP
         CLR.B    REPLY_ID(A6)
WM_ENTRY BSR      OPM_IN
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         JSR      FCLOSE
         ADDQ.B   #1,D1
         IF EQ THEN
            TXSTR    {'Sorry, message file full...',CR,LF}
            BRA      ABORTED
         ENDIF
         QDOS     MT.RCLCK
         MOVE.L   D1,MSGHDR+MS_DATE(A6)
         CLR.W    MSGHDR+MS_COST(A6)
         CLR.L    MSGHDR+MS_RSDAT(A6)
         TXSTR    {'From: '}
         LEA      FROMUSER(A6),A1
         JSR      PRINTNAM
         JSR      TXCRLF
         TST.B    SYSOPMSG(A6)
         BEQ.S    WM_GDEST
         TXSTR    {'  To: '}
         LEA      S_SYSOP+1(A6),A1
         JSR      PRINTNAM
         JSR      TXCRLF
         LEA      S_SYSOP+1(A6),A1
         LEA      TOUSER(A6),A2
         JSR      COPYNAME
         BRA.S    WM_PRIV
WM_GDEST BSR      GETDEST
         BLT      ABORTED
         TST.B    ISECHO(A6)
         BNE.S    ENT_SUBJ
         TST.B    ISPRIV(A6)
         BNE.S    WM_PRIV
         BSR      PRIVMSG
         BRA.S    ENT_SUBJ
WM_PRIV  ORI.W    #1<<MS..PRIV,MSGHDR+MS_ATTR(A6)
ENT_SUBJ BSR      GET_SUBJ
         LEA      MSG_BASE-1(A6),A4
         CLR.B    (A4)+
         TST.L    D6
         BEQ      NEW_MSG
         BLT.S    WM_AQUOT
         TXSTR    {'Do you wish to keep the old text'}
         JSR      YESNO
         BNE      NEW_MSG
         LEA      BUFFER(A6),A1
         WRITE$   {' * Originally dated '},A1
         MOVE.L   ORIGDATE(A6),D1
         JSR      DATE$
         MOVE.L   A1,-(A7)
         LEA      FROMUSER(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      CMPNAME
         MOVE.L   (A7)+,A1
         IF NE THEN
            WRITE$   {CR,' * Updated by '},A1
            MOVE.L   A2,A0
            JSR      WRNAME
         ENDIF
         MOVE.B   #CR,(A1)+
         MOVE.B   #CR,(A1)+
         BRA.S    WM_PREP
WM_AQUOT TXSTR    {'Do you wish to quote existing text'}
         JSR      NOYES
         BNE.S    NEW_MSG
         LEA      ORIGFROM(A6),A1
         LEA      TOUSER(A6),A2
         JSR      CMPNAME
         BNE.S    WM_QHDR
         LEA      ORIGTO(A6),A1
         LEA      FROMUSER(A6),A2
         JSR      CMPNAME
WM_QHDR  LEA      BUFFER(A6),A1
         BEQ.S    WM_QON
         WRITE$   {' * Quoting '},A1
         LEA      ORIGFROM(A6),A0
         JSR      WRNAME
         WRITE$   {' to '},A1
         LEA      ORIGTO(A6),A0
         JSR      WRNAME
         MOVE.B   #CR,(A1)+
         MOVE.B   #CR,(A1)+
WM_QON   MOVE.B   #QON,(A1)+
WM_PREP  BSR      PREP_TXT
         MOVE.L   A1,D1
         LEA      BUFFER(A6),A1
         SUB.L    A1,D1
         BLE.S    TST_ED
         BSR      WM_INSER
         BNE      WM_OFLOW
WM_CHDR  MOVE.B   (A1)+,(A4)+
         SUBQ.W   #1,D1
         BGT      WM_CHDR
         BRA.S    TST_ED
NEW_MSG  MOVE.L   A4,A5
TST_ED   TST.B    LOCALMOD(A6)
         BEQ.S    WM_HIGH
         LEA      S_EDITOR(A6),A0
         TST.B    (A0)
         BEQ.S    WM_HIGH
         BSR      FS_EDIT
         BRA      WM_MENU
WM_HIGH  MOVE.W   #32767,D1
ED_REENT MOVEQ    #0,D6
         MOVEQ    #0,D7
         LEA      MSG_BASE(A6),A4
         CMPA.L   A4,A5
         BLS.S    GET_MSG
         SUBQ.W   #1,D1
         BLE.S    GET_MSG
         BSR      FINDLINE
         MOVE.L   A1,A4
GET_MSG  TXSTR    {'Enter your message, empty line to end',CR,LF}
         TXSTR    {'Words will wrap automatically.',CR,LF,LF}
         MOVEQ    #0,D3
         SF       D5
WM_NXTLN ADDQ.W   #1,D6
         BSR      TX_LINUM
         TST.W    D3
         IF NE THEN
            MOVE.W   D3,D2
            LEA      BUFFER(A6),A0
            REPEAT
               MOVE.B   (A1)+,D1
               MOVE.B   D1,(A0)+
               JSR      TXCHAR
               SUBQ.W   #1,D2
            UNTIL    EQ
         ENDIF
         MOVE.W   D3,D1
         MOVEQ    #0,D2
         MOVE.B   USERBUF+US_WIDTH(A6),D2
         SUBQ.W   #4,D2
         LEA      BUFFER(A6),A1
         ADDA.W   D1,A1
         JSR      GETLIN1
         MOVEQ    #0,D3
         MOVE.W   D1,D4
         TST.L    D0
         BEQ.S    WM_CLINE
         MOVE.L   A1,A0
FINDSPC  CMPI.B   #' ',-(A0)
         BEQ.S    SPCFOUND
         ADDQ.W   #1,D3
         SUBQ.W   #1,D4
         BNE.S    FINDSPC
         MOVEQ    #0,D3
         MOVE.W   D1,D4
         BRA.S    WM_CRLF
SPCFOUND LEA      1(A0),A1
         MOVE.W   D3,D2
         BEQ.S    WM_CRLF
         REPEAT
            MOVEQ    #BS,D1
            JSR      TXCHAR
            SUBQ.W   #1,D2
         UNTIL    EQ
         MOVE.W   D3,D2
         REPEAT
            MOVEQ    #' ',D1
            JSR      TXCHAR
            SUBQ.W   #1,D2
         UNTIL    EQ
WM_CRLF  JSR      TXCRLF
WM_CLINE CMPI.W   #1,D4
         BNE.S    WM_CLIN2
         TST.B    D5
         BEQ      WM_MENU
         CMPI.B   #CR,-1(A4)
         BEQ.S    ENDMSG
WM_CLIN2 MOVE.W   D4,D1
         LEA      BUFFER(A6),A0
         TST.B    D5
         BNE.S    WM_CLIN4
         CMPI.W   #1,D6
         BEQ.S    WM_CLIN3
         CMPI.B   #' ',-1(A4)
         BLO.S    WM_CLIN3
         BEQ.S    WM_INSCR
         MOVE.W   D1,-(A7)
         MOVEQ    #1,D1
         BSR      WM_INSER
         MOVE.W   (A7)+,D1
         TST.L    D0
         BNE.S    WM_OFLOW
         ADDQ.W   #1,A4
WM_INSCR MOVE.B   #CR,-1(A4)
WM_CLIN3 ADD.W    D7,D1
WM_CLIN4 BSR      WM_INSER
         BNE.S    WM_OFLOW
         TST.B    D5
         BNE.S    WM_CLLP
         SUB.W    D7,D1
         MOVE.W   D7,D0
         BRA.S    WM_QOF_E
WM_QOF_L MOVE.B   #QOFF,(A4)+
WM_QOF_E DBF      D0,WM_QOF_L
WM_CLLP  MOVE.B   (A0)+,(A4)+
         SUBQ.W   #1,D1
         BGT      WM_CLLP
         SUBQ.W   #1,D4
         BEQ.S    ENDMSG
         ST       D5
         BRA      WM_NXTLN
WM_OFLOW TXSTR    {CR,LF,'BUFFER FULL!',CR,LF,BELL}
ENDMSG   CMPA.L   A5,A4
         BEQ.S    WM_MENU
         MOVE.W   D7,D1
         BEQ.S    WM_MENU
         BSR      WM_INSER
         BNE.S    WM_MENU
WM_QONLP MOVE.B   #QON,(A4)+
         SUBQ.W   #1,D1
         BGT      WM_QONLP
WM_MENU  LEA      WMTABLE,A1
         JSR      INDEXER
         BRA      WM_MENU

WMTABLE  STRING$  {'Editor command'}
         STRING$  {LV.TWIT,'L',$5B,'L]ist'}
         DC.W     WM_LIST-*
         STRING$  {LV.TWIT,'A',$5B,'A]bort'}
         DC.W     WM_ABORT-*
         STRING$  {LV.EXTRA,'F',$5B,'F]rom'}
         DC.W     GETFROM-*
         STRING$  {LV.NORM,'T',$5B,'T]o'}
         DC.W     GETDEST-*
         STRING$  {LV.TWIT,'J','sub',$5B,'J]ect'}
         DC.W     GET_SUBJ-*
         STRING$  {LV.NORM,'P',$5B,'P]rivate'}
         DC.W     PRIVMSG2-*
         STRING$  {LV.EXTRA,'H',$5B,'H]andling'}
         DC.W     WM_HANDL-*
         STRING$  {LV.TWIT,'C',$5B,'C]ontinue entry'}
         DC.W     WM_CONT-*
         STRING$  {LV.TWIT,'E',$5B,'E]dit a line'}
         DC.W     WM_EDIT-*
         STRING$  {LV.TWIT,'I',$5B,'I]nsert text'}
         DC.W     WM_INSRT-*
         STRING$  {LV.TWIT,'D',$5B,'D]elete line(s)'}
         DC.W     WM_DLINE-*
         STRING$  {LV.COSYS,'R',$5B,'R]ead from file'}
         DC.W     WM_IMPRT-*
         STRING$  {LV.TWIT,'S',$5B,'S]ave message'}
         DC.W     WM_SAVE-*
         DC.W     0

WM_ABORT TXSTR    {CR,LF,'Throw away message'}
         JSR      NOYES
         BNE.S    NO_ABORT
         ADDQ.W   #4,A7
ABORTED  TXSTR    {CR,LF,'Message entry aborted',CR,LF}
         LOG      {'Message entry aborted',LF}
         CLR.L    MSGHDR+MS_DATE(A6)
NO_ABORT RTS
WM_CONT  TXSTR    {CR,LF,'Continue entry',CR,LF}
         MOVE.W   #32767,D1
         BRA.S    WM_REENT
WM_INSRT LOAD$    {'Insert text before line #: '},A0
         BSR.S    ASKLINE
         BEQ      NO_ABORT
WM_REENT ADDQ.W   #4,A7
         BRA      ED_REENT

WM_LIST  JSR      TXCRLF
         ST       LINUMFLG(A6)
         MOVEQ    #5,D5
         BSR      TXMSG_2
         SF       LINUMFLG(A6)
         RTS

ASKLINE  LEA      BUFFER(A6),A1
         MOVEQ    #4,D2
         JSR      INPUT
         SUBQ.W   #1,D1
         BEQ.S    ASKL_RTS
         JSR      READNUM
         BEQ.S    ASKL_RTS
         TXSTR    {'Invalid line number',CR,LF}
         BRA      ASKLINE
ASKL_RTS TST.W    D1
         RTS

* Prepare message text (strip Origin- and kludge lines)

PREP_TXT MOVEM.L  A0-A4,-(A7)
         TXSTR    {'Preparing message text...',CR,LF}
         LEA      MSG_BASE(A6),A1
         MOVE.B   KLUDGE(A6),-(A7)
         ST       KLUDGE(A6)
PT_PA_LP CMPA.L   A5,A1
         BHS.S    PT_END
         BSR      GET_PARA
         CMPI.B   #1,(A1)
         BNE.S    PT_CK_TR
         MOVE.B   #'@',(A1)
         TST.B    (A7)
         BNE.S    PT_CK_TR
         MOVE.L   A1,A4
         BSR      WM_DELET
PT_PA_NX MOVE.L   A4,A1
         BRA      PT_PA_LP
PT_CK_TR MOVE.L   A0,A4
         TST.B    (A7)
         BNE      PT_PA_NX
         LOAD$    {'---'},A0
         JSR      COMPSTR
         BNE      PT_PA_NX
         CMPA.L   A5,A4
         BHS.S    PT_TRUNC
         EXG      A1,A4
         LOAD$    {' * ORIGIN:'},A0
         JSR      COMPSTR
         EXG      A1,A4
         BNE      PT_PA_NX
PT_TRUNC LEA      -3(A1),A5
PT_END   MOVE.B   (A7)+,KLUDGE(A6)
         MOVEM.L  (A7)+,A0-A4
         RTS

* Find a particular line
* Entry: D1 line number
* Exit : D1 line number, D2 length of line, D7 quote depth, A4 start of line
*        D0 0 if valid line number, ERR.NF if not

FINDLINE MOVE.W   D1,-(A7)
         LEA      MSG_BASE(A6),A1
         SF       PRINTLIN(A6)
         ST       LINUMFLG(A6)
         MOVEQ    #0,D6
         MOVEQ    #0,D7
FL_PARA  CMPA.L   A5,A1
         BHS.S    FL_NOTF
         BSR      GET_PARA
         BEQ      FL_PARA
FL_LINE  MOVE.L   A1,A4
         BSR      TXM_LINE
         CMP.W    (A7),D6
         BEQ.S    FL_END
         TST.W    D1
         BNE      FL_LINE
         BRA      FL_PARA
FL_NOTF  MOVEQ    #ERR.NF,D0
         BRA.S    FL_RTS
FL_END   MOVEQ    #0,D0
FL_RTS   ST       PRINTLIN(A6)
         SF       LINUMFLG(A6)
         MOVE.W   (A7)+,D1
         TST.L    D0
         RTS

WM_INSER MOVE.L   A5,D0
         SUB.L    A6,D0
         SUBI.W   #BUFFER,D0
         ADD.W    D1,D0
         CMP.W    BUFSIZE(A6),D0
         BHI.S    WMI_BO
         MOVE.L   A5,A2
         ADDA.W   D1,A5
         MOVE.L   A5,A3
WMI_LP   MOVE.B   -(A2),-(A3)
         CMPA.L   A4,A2
         BHI      WMI_LP
         MOVEQ    #0,D0
         RTS
WMI_BO   MOVEQ    #ERR.BO,D0
         RTS

WM_DLINE LOAD$    {'Delete - starting line #: '},A0
         BSR      ASKLINE
         BEQ.S    WMD_END
         BSR      FINDLINE
         BNE.S    ILL_LINE
         MOVE.L   A4,-(A7)
         MOVE.W   D1,-(A7)
         LOAD$    {'Ending line # (<ENTER> = start line #): '},A0
         BSR      ASKLINE
         IF EQ THEN
            MOVE.W   (A7),D1
         ENDIF
         CMP.W    (A7)+,D1
         BLO.S    BADSEQ
         BSR      FINDLINE
         LEA      (A4,D2.W),A1
         MOVE.L   (A7)+,A4
         BNE.S    ILL_LINE
         MOVE.L   A1,D1
         SUB.L    A4,D1
WM_DELET LEA      (A4,D1.W),A2
         MOVE.L   A4,A3
WMD_LP   MOVE.B   (A2)+,(A3)+
         CMPA.L   A5,A2
         BLO      WMD_LP
         SUBA.W   D1,A5
         LEA      MSG_BASE(A6),A2
WMD_LP2  CMPA.L   A2,A5
         BLS.S    WMD_END
         CMPI.B   #CR,-1(A5)
         BEQ.S    WMD_END
         CMPI.B   #$1F,-1(A5)
         BHI.S    WMD_CR
         SUBQ.W   #1,A5
         BRA      WMD_LP2
WMD_CR   MOVE.B   #CR,(A5)+
WMD_END  RTS

BADSEQ   ADDQ.W   #4,A7
         TXSTR    {'First > last',CR,LF}
         RTS

ILL_LINE TXSTR    {'Invalid line number',CR,LF}
         RTS

WM_GTSTR LEA      BUFFER(A6),A1
         MOVEQ    #64,D2
         JSR      INPUT
         SUBQ.W   #1,D1
         CMPI.B   #'\',-1(A1,D1.W)
         IF EQ THEN
            MOVE.B   #CR,-1(A1,D1.W)
         ENDIF
         RTS

WM_EDIT  LOAD$    {'Edit line #: '},A0
         BSR      ASKLINE
         BEQ.S    WME_END
         BSR.S    DISPLINE
         BNE      ILL_LINE
         LOAD$    {'Search string: '},A0
         MOVE.W   D2,-(A7)
         BSR      WM_GTSTR
         MOVE.W   (A7)+,D2
         MOVE.L   A4,A2
         JSR      FINDSTR2
         BNE.S    WME_NF
         MOVE.W   D1,D4
         MOVE.L   A1,A4
         LOAD$    {'Replace by: '},A0
         BSR      WM_GTSTR
         MOVE.W   D1,D2
         SUB.W    D4,D1
         BEQ.S    WME_COPY
         BLT.S    WME_DEL
         BSR      WM_INSER
         BNE.S    WME_BF
         BRA.S    WME_COPY
WME_DEL  NEG.W    D1
         BSR      WM_DELET
         BRA.S    WME_COPY
WME_COPL MOVE.B   (A1)+,(A4)+
WME_COPY DBF      D2,WME_COPL
         MOVE.W   D6,D1
DISPLINE BSR      FINDLINE
         BNE.S    WME_END
         MOVE.L   A4,A1
         JSR      TXCRLF
         ST       LINUMFLG(A6)
         MOVE.W   D2,D1
         MOVEQ    #0,D5
         MOVE.W   D2,-(A7)
         BSR      TXM_LINE
         MOVE.W   (A7)+,D2
         SF       LINUMFLG(A6)
         SUBQ.W   #1,D6
         MOVEQ    #0,D0
WME_END  RTS
WME_NF   TXSTR    {'Not found',CR,LF}
         RTS
WME_BF   TXSTR    {'Buffer full',CR,LF}
         RTS

WM_SAVE  BSR.S    SAVE_MSG
         ADDQ.W   #4,A7
         RTS
WM_MFULL TXSTR    {'*** Message file full - Message not saved!',CR,LF,BELL}
         JSR      FCLOSE
         LOG      {'? Message area full',LF}
         MOVEQ    #-1,D0
         RTS
SAVE_MSG BSR      OPM_EXCL
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         ADDQ.B   #1,D1
         BCS      WM_MFULL
         MOVE.B   D1,D7
         TXSTR    {'Saving your message (#'}
         BSR      PRINTNUM
         TXSTR    {')...',CR,LF}
         LEA      BUFFER+2(A6),A1
         TST.B    ISNET(A6)
         BNE.S    WM_MSGID
         TST.B    ISECHO(A6)
         BEQ.S    WM_TSTRP
WM_MSGID BSR      GENMSGID
WM_TSTRP MOVE.L   A1,A2
         MOVE.B   MSGHDR+MS_REPTO(A6),D4
         BEQ.S    WMS_GLEN
         LEA      REPLY_ID(A6),A1
         TST.B    (A1)
         IF NE THEN
            EXG      A1,A2
            WRITE$   {1,'REPLY: '},A1
            EXG      A1,A2
            REPEAT
               MOVE.B   (A1)+,D0
               MOVE.B   D0,(A2)+
               CMPI.B   #CR,D0
            UNTIL    EQ
         ENDIF
         TXSTR    {'Adding a reply to #'}
         MOVE.B   D4,D1
         BSR      PRINTNUM
         JSR      TXCRLF
         CLR.B    MSGHDR+MS_REPTO(A6)
WMS_THRD MOVE.B   D4,D1
         BSR      GET_MSGP
         BLT.S    WMS_GLEN
         MOVE.B   D4,MSGHDR+MS_REPTO(A6)
         MOVEQ    #MS_NXREP,D0
         ADD.L    D0,D1
         QDOS     FS.POSAB
         QDOS     IO.FBYTE
         TST.B    D1
         BEQ.S    WMS_GLEN
         MOVE.B   D1,-(A7)
         TXSTR    {'Message #'}
         MOVE.B   D4,D1
         BSR      PRINTNUM
         TXSTR    {' has already a reply #'}
         MOVE.B   (A7)+,D4
         MOVE.B   D4,D1
         BSR      PRINTNUM
         JSR      TXCRLF
         BRA      WMS_THRD
WMS_GLEN MOVE.B   MSGHDR+MS_NXREP(A6),D4
         CLR.B    MSGHDR+MS_NXREP(A6)
         SUBQ.W   #4,A7
         MOVE.L   A7,A1
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         QDOS     FS.HEADR
         TST.L    D0
         BNE      WM_IOERR
         MOVE.L   (A7),D1
         QDOS     FS.POSAB
         MOVEQ    #MS_TOUSR,D2
         LEA      MSGHDR(A6),A1
         TST.B    ISNET(A6)
         IF EQ THEN
            CLR.L    MS_DZONE(A1)
            CLR.L    MS_DNODE(A1)
            TST.B    ISECHO(A6)
            IF NE THEN
               BSR      GEN_ORIG
            ENDIF
         ENDIF
         ORI.W    #1<<MS..LOC,MS_ATTR(A1)
         TST.B    ISPRIV(A6)
         IF NE THEN
            ORI.W    #1<<MS..PRIV,MS_ATTR(A1)
         ENDIF
         CLR.W    MS_NREAD(A1)
         CLR.L    MS_RSDAT(A1)
         BSR      WM_SSTRG
         LEA      TOUSER(A6),A1
         BSR      SENDNAME
         LEA      FROMUSER(A6),A1
         BSR      SENDNAME
         LEA      SUBJECT(A6),A1
         BSR      SENDNAME
         LEA      BUFFER+2(A6),A1
         MOVE.L   A2,D2
         SUB.L    A1,D2
         LEA      MSG_BASE(A6),A2
         MOVE.L   A5,D5
         SUB.L    A2,D5
         MOVE.W   D2,-(A1)
         ADD.W    D5,(A1)
         ADDQ.W   #2,D2
         BSR      WM_SSTRG
         MOVE.W   D5,D2
         MOVE.L   A2,A1
         BSR      WM_SSTRG
         MOVEQ    #0,D1
         QDOS     FS.POSAB
         MOVE.B   D7,D1
         QDOS     IO.SBYTE    WRITE NEW NUMBER OF MESSAGES
         MOVEQ    #0,D1
         MOVE.B   D7,D1
         SUBQ.B   #1,D1
         LSL.L    #2,D1
         QDOS     FS.POSRE
         MOVE.L   A7,A1
         MOVEQ    #4,D2
         QDOS     IO.SSTRG    WRITE NEW MSG'S POINTER
         MOVEQ    #14,D2
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         LEA      BUFFER(A6),A1
         MOVE.L   D1,$0A(A1)
         QDOS     FS.HEADS
         MOVE.B   MSGHDR+MS_REPTO(A6),D1
         BEQ.S    TST_UPDT
         BSR      GET_MSGP
         MOVEQ    #MS_NXREP,D0
         ADD.L    D0,D1
         QDOS     FS.POSAB
         MOVE.B   D7,D1
         QDOS     IO.SBYTE
TST_UPDT JSR      FCLOSE
         LEA      LOGBUF(A6),A1
         WRITE$   {'Saved new message '},A1
         MOVEQ    #0,D1
         MOVE.B   D7,D1
         MOVEQ    #0,D2
         JSR      ITOD.W
         WRITE$   {' in area '},A1
         MOVE.W   CUR_AREA(A6),D1
         JSR      ITOD.W
         CLR.B    (A1)
         JSR      LOG0
         TST.B    D4
         IF NE THEN
            BSR      KILLMSG
         ENDIF
         MOVEQ    #0,D0
         BRA.S    WMS_END
SENDNAME MOVEQ    #1,D2
         ADD.B    (A1),D2
WM_SSTRG MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         TST.L    D0
         BEQ.S    WM_RTS
         MOVE.L   D0,(A7)
         MOVE.L   4(A7),D1
         QDOS     FS.POSAB
         QDOS     FS.TRUNC
         MOVE.L   (A7)+,D0
WM_IOERR MOVE.L   D0,-(A7)
         TXSTR    {'*** Disk I/O Error - Message not saved!',CR,LF,BELL}
         JSR      FCLOSE
         LOG      {'? Disk I/O Error - message not saved',LF}
         MOVE.L   (A7)+,D0
WMS_END  ADDQ.W   #4,A7
         CLR.L    MSGHDR+MS_DATE(A6)
WM_RTS   RTS

GET_MSGP ANDI.L   #$FF,D1
         BEQ.S    GM_INV
         SUBQ.B   #1,D1
         LSL.W    #2,D1
         ADDQ.L   #1,D1
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         SUBA.W   D2,A7
         MOVE.L   A7,A1
         QDOS     IO.FSTRG
         MOVE.L   (A7)+,D1
         RTS
GM_INV   MOVEQ    #-1,D1
         RTS

PRINTNUM ANDI.W   #$FF,D1
         JMP      TXNUMBER

GENMSGID WRITE$   {1,'MSGID: '},A1
         LEA      MSGHDR+MS_OZONE(A6),A2
         JSR      ZNNP2A
         MOVE.B   #' ',(A1)+
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         MOVE.L   A0,D0
         SWAP     D0
         ANDI.B   #$0F,D0
         LSL.L    #4,D1
         OR.B     D0,D1
         MOVEQ    #7,D2
GM_LOOP  ROL.L    #4,D1
         MOVEQ    #$0F,D0
         AND.B    D1,D0
         ADDI.B   #'0',D0
         CMPI.B   #'9',D0
         IF HI THEN
            ADDI.B   #'a'-('9'+1),D0
         ENDIF
         MOVE.B   D0,(A1)+
         DBF      D2,GM_LOOP
         MOVE.B   #CR,(A1)+
         RTS

GEN_ORIG MOVEM.L  D1-D4/A0-A4,-(A7)
         LEA      ORIGFNAM,A0
         LEA      DIRBUF(A6),A1
         LEA      FNAMBUF(A6),A2
         MOVEQ    #IO.EXCL,D3
         JSR      OPEN_SUB
         BEQ.S    GO_TEAR
         LEA      S_SYSDIR(A6),A0
         LEA      FNAMBUF(A6),A1
         WRITEL$
         WRITE$   {'ORIGIN'},A1
         LEA      FNAMBUF(A6),A2
         ADDQ.W   #6,(A2)
         MOVE.B   A_GROUP(A6),D0
         BEQ.S    GO_OPEN
         MOVE.B   #'_',(A1)+
         MOVE.B   D0,(A1)+
         ADDQ.W   #2,(A2)
GO_OPEN  MOVEQ    #IO.EXCL,D3
         JSR      OPENSUB1
         BNE      GO_END
GO_TEAR  MOVE.L   A5,A1
         WRITE$   {CR,'--- QBOX [version]',CR,' * Origin: '},A1
         MOVEQ    #14,D2
         MOVEQ    #-1,D3
         MOVE.L   A1,A3
         MOVE.W   A1,D0
         ANDI.W   #1,D0
         ADDA.W   D0,A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      GO_CLOSE
         SUBA.W   D1,A1
         MOVE.W   8(A1),D4
         BNE.S    GO_RND
         ADDA.W   #14,A1
         MOVEQ    #80,D2
GO_LOOP  QDOS     IO.FLINE
         SUBA.W   D1,A1
         TST.L    D0
         BNE.S    GO_SETCT
         ADDQ.W   #1,D4
         BRA      GO_LOOP
GO_SETCT SUBA.W   #14,A1
         MOVE.W   D4,8(A1)
         BEQ      GO_CLOSE
         QDOS     FS.HEADS
         MOVEQ    #0,D1
         QDOS     FS.POSAB
GO_RND   MOVE.L   A0,-(A7)
         QDOS     MT.INF
         MOVEQ    #0,D1
         MOVE.W   $2E(A0),D1        SV.RAND
         MOVE.L   (A7)+,A0
         DIVU     D4,D1
         SWAP     D1
         MOVE.W   D1,D4
         MOVEQ    #80,D2
         MOVEQ    #-1,D3
GO_LOOP2 MOVE.L   A3,A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    GO_CLOSE
         DBF      D4,GO_LOOP2
         MOVE.B   #' ',-1(A1)
         MOVE.L   A1,A4
         MOVE.B   #'(',(A1)+
         LEA      MYZONE(A6),A2
         JSR      ZNNP2A
         MOVE.B   #')',(A1)+
         MOVE.L   A1,D0
         SUB.L    A3,D0
         SUBI.W   #68,D0
         BLE.S    GO_OPTR
         SUBA.W   D0,A1
         SUBA.W   D0,A4
         ADDQ.W   #2,D2
GO_LOOP3 MOVE.B   (A4,D0.W),(A4)+
         SUBQ.W   #1,D2
         BGT      GO_LOOP3
GO_OPTR  MOVE.B   #CR,(A1)+
         LEA      MSG_BASE(A6),A2
         MOVE.L   A1,D0
         SUB.L    A2,D0
         MOVE.W   D0,MSGHDR+MS_DNET(A6)
         MOVE.L   A5,D0
         ADDQ.L   #1,D0
         SUB.L    A2,D0
         MOVE.W   D0,MSGHDR+MS_DNODE(A6)
         MOVE.L   24(A7),D0
         LEA      BUFFER+2(A6),A2
         SUB.L    A2,D0
         ADD.W    D0,MSGHDR+MS_DNET(A6)
         ADD.W    D0,MSGHDR+MS_DNODE(A6)
         MOVE.W   #-1,MSGHDR+MS_DZONE(A6)
         MOVE.L   A1,A5
GO_CLOSE QDOS     IO.CLOSE
GO_END   MOVEM.L  (A7)+,D1-D4/A0-A4
WMI_END  RTS

WM_IMPRT MOVEQ    #50,D2
         LEA      BUFFER+2(A6),A1
         INPUT    {CR,LF,'File to import message text from: '}
         SUBQ.W   #1,D1
         BLE      WMI_END
         MOVE.W   D1,-(A1)
         MOVE.L   A1,A0

* Import message text from file
* Entry: A0 ptr to filename

IMP_MSG  MOVEQ    #-1,D1
         MOVEQ    #IO.SHARE,D3
         MOVE.L   A0,A2
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    IM_HDR
         TXSTR    {'Unable to open file '}
         MOVE.L   A2,A1
         JSR      TXSTR
         JSR      TXCRLF
         MOVEQ    #ERR.NF,D0
         RTS
IM_HDR   MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      MSG_BASE(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE.S    IM_IOERR
         MOVE.L   -(A1),D2
         CMPI.L   #32000,D2
         BLS.S    IM_READ
         TXSTR    {'File too large!',CR,LF}
         QDOS     IO.CLOSE
         MOVEQ    #ERR.BO,D0
         RTS
IM_READ  QDOS     IO.FSTRG
         MOVE.L   A1,A5
IM_IOERR MOVE.L   D0,D4
         QDOS     IO.CLOSE
         TST.L    D4
         BEQ.S    IM_PROC
         TXSTR    {'File I/O Error!',CR,LF}
         MOVE.L   D4,D0
         RTS
IM_PROC  TXSTR    {'Processing message text... '}
         CMPI.B   #CR,-1(A5)
         BEQ.S    IM_P1
         CMPI.B   #LF,-1(A5)
         BEQ.S    IM_P1
         MOVE.B   #LF,(A5)+
IM_P1    MOVEQ    #' ',D2
         LEA      MSG_BASE(A6),A1
IM_P2    CMPA.L   A5,A1
         BHS.S    IM_DONE
         CMP.B    (A1)+,D2
         BLS      IM_P2
         CMPI.B   #CR,-(A1)
         BEQ.S    IM_CR
         CMPI.B   #LF,(A1)
         BEQ.S    IM_LF
         MOVE.B   #'?',(A1)+
         BRA      IM_P2
IM_CR    MOVE.B   D2,(A1)+
         BRA      IM_P2
IM_LF    MOVE.B   #CR,(A1)+
         BRA      IM_P2
IM_DONE  TXSTR    {'Done!',CR,LF}
         MOVEQ    #0,D0
         RTS

WM_HANDL TXSTR    {CR,LF,'Current Attributes:',CR,LF,LF}
         LEA      ATTR_TAB,A3
         MOVE.L   A3,A2
WMH_LOOP TST.W    (A2)+
         BEQ.S    WMH_ASK
         MOVE.W   (A2)+,A1
         ADDA.L   A3,A1
         JSR      TXSTR
         LOAD$    {'YES',CR,LF},A1
         MOVE.W   MSGHDR+MS_ATTR(A6),D0
         AND.W    (A2)+,D0
         BNE.S    WMH_VAL
         LOAD$    {'NO',CR,LF},A1
WMH_VAL  JSR      TXSTR
         BRA      WMH_LOOP
WMH_ASK  JSR      TXCRLF
         MOVEQ    #17,D2
         LEA      BUFFER(A6),A1
         INPUT    {'Enter attribute(s) to toggle, <ENTER> quits: '}
         SUBQ.W   #1,D1
         BLE.S    WMH_END
WMH_LP2  MOVE.B   (A1)+,D1
         CMPI.B   #CR,D1
         BEQ      WM_HANDL
         JSR      TOUPPER
         CMPI.B   #'A',D1
         BLO      WMH_LP2
         CMPI.B   #'Z',D1
         BHI      WMH_LP2
         MOVE.L   A3,A2
WMH_LP3  MOVE.W   (A2)+,D2
         BEQ.S    WMH_ILL
         ADDQ.L   #2,A2
         MOVE.W   (A2)+,D0
         CMP.B    D1,D2
         BNE      WMH_LP3
         EOR.W    D0,MSGHDR+MS_ATTR(A6)
         BRA      WMH_LP2
WMH_ILL  MOVEQ    #$27,D1
         JSR      TXCHAR
         MOVE.B   -1(A1),D1
         JSR      TXCHAR
         MOVE.L   A1,-(A7)
         TXSTR    {''' is not a valid choice',CR,LF}
         MOVE.L   (A7)+,A1
         BRA      WMH_LP2
WMH_END  RTS

         SECTION  MSG

ATTR_TAB DC.W     ' P',AM_PRIV-ATTR_TAB,$0001
         DC.W     ' C',AM_CRASH-ATTR_TAB,$0002
         DC.W     ' R',AM_RECVD-ATTR_TAB,$0004
         DC.W     ' S',AM_SENT-ATTR_TAB,$0008
         DC.W     ' A',AM_FATT-ATTR_TAB,$0010
         DC.W     ' T',AM_TRNS-ATTR_TAB,$0020
         DC.W     ' O',AM_ORPH-ATTR_TAB,$0040
         DC.W     ' K',AM_KSENT-ATTR_TAB,$0080
         DC.W     ' L',AM_LOCAL-ATTR_TAB,$0100
         DC.W     ' H',AM_HOLD-ATTR_TAB,$0200
         DC.W     ' F',AM_FREQ-ATTR_TAB,$0800
         DC.W     ' Q',AM_RREQ-ATTR_TAB,$1000
         DC.W     ' I',AM_ISRRQ-ATTR_TAB,$2000
         DC.W     ' D',AM_AREQ-ATTR_TAB,$4000
         DC.W     ' U',AM_UREQ-ATTR_TAB,$8000
         DC.W     0

AM_PRIV  STRING$  {$5B,'P]rivate...............: '}
AM_CRASH STRING$  {$5B,'C]rash.................: '}
AM_RECVD STRING$  {$5B,'R]eceived..............: '}
AM_SENT  STRING$  {$5B,'S]ent..................: '}
AM_FATT  STRING$  {'File ',$5B,'A]ttach...........: '}
AM_TRNS  STRING$  {'In ',$5B,'T]ransit............: '}
AM_ORPH  STRING$  {$5B,'O]rphan................: '}
AM_KSENT STRING$  {$5B,'K]ill after mailing....: '}
AM_LOCAL STRING$  {$5B,'L]ocally entered.......: '}
AM_HOLD  STRING$  {$5B,'H]old for pickup.......: '}
AM_FREQ  STRING$  {$5B,'F]ile request..........: '}
AM_RREQ  STRING$  {'Return receipt re',$5B,'Q]uest: '}
AM_ISRRQ STRING$  {$5B,'I]s return receipt.....: '}
AM_AREQ  STRING$  {'Au',$5B,'D]it trail request...: '}
AM_UREQ  STRING$  {'File ',$5B,'U]pdate request...: '}

         SECTION  CODE

FS_EDIT  TXSTR    {CR,LF,'Preparing text for external editor...',CR,LF}
         LEA      TMSGFNAM,A0
         LEA      S_MSGTMP(A6),A1
         JSR      OP_FOVER
         BEQ.S    FSE_2
         TXSTR    {CR,LF,'Unable to open editor workfile!',CR,LF}
         RTS
FSE_2    ST       SPEC_OUT(A6)
         BSR      TXMSG_T
         JSR      TXCRLF
         SF       SPEC_OUT(A6)
         JSR      FCLOSE
         MOVEQ    #32,D6
         MOVEQ    #-1,D7
         LEA      S_EDITOR(A6),A0
         LEA      EXT_CMDL,A2
         LEA      EXT_CHAN,A3
         JSR      EXEC
         JSR      EXT_RET
         LEA      FNAMBUF(A6),A0
         BEQ      IMP_MSG
         MOVE.L   D0,-(A7)
         TXSTR    {CR,LF,'Error return from external editor!',CR,LF}
         MOVE.L   (A7)+,D0
         RTS

DSP_AREA TXSTR    {CR,LF,'Message area '}
         MOVEQ    #0,D1
         MOVE.B   USERBUF+US_MAREA(A6),D1
         ADDQ.W   #1,D1
         JSR      TXNUMBER
         TXSTR    {': '}
         LEA      AREANAME(A6),A1
         JSR      TXSTR
         JMP      TXCRLF

MAILBOX  LOG      {'Mail section',LF}
         JSR      SETMAREA
         BRA.S    TST_SCAN
MB_AREA  JSR      SELMAREA
TST_SCAN CLR.L    MSGHDR+MS_DATE(A6)
         LEA      MSCANNED(A6),A1
         TAS      -1(A1,D1.W)
         BNE.S    MB_LOOP
         BSR      OPM_IN
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         JSR      FCLOSE
         MOVE.L   BUFFER+$0A(A6),D1
         IF EQ THEN
            MOVE.L   BUFFER+$34(A6),D1
         ENDIF
         CMP.L    LASTCALL(A6),D1
         BLS.S    MB_LOOP
         BSR      DSP_AREA
MB_SCAN  BSR      LOOKMAIL
MB_LOOP  BSR      DSP_AREA
         BSR      OPM_IN
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         MOVE.B   D1,D7
         JSR      FCLOSE
         TST.B    D7
         IF EQ THEN
            TXSTR    {'No messages'}
         ELSE
            MOVEQ    #$5B,D1
            JSR      TXCHAR
            BSR      GET_CMSG
            MOVE.B   (A1),D1
            BSR      PRINTNUM
            TXSTR    {']  Highest: '}
            MOVE.B   D7,D1
            BSR      PRINTNUM
         ENDIF
         MOVE.B   USERBUF+US_HELPL(A6),D4
         MOVEQ    #US.LEVEL,D5
         AND.B    D4,D5
         LSR.B    #4,D4
         SUBQ.B   #1,D4
         BRA.S    MB_MENU
MB_FMENU JSR      TXCHAR
         JSR      TXCRLF
         MOVEQ    #-1,D4
MB_MENU  LEA      MBCMDTBL,A1
         JSR      IN_DISPL
         TST.B    D4
         BGE.S    MB_GKEY
MB_ENT   TXSTR    {CR,LF,'Press <ENTER> for '}
         TST.B    USERBUF+US_MBCMD(A6)
         IF NE THEN
            TXSTR    {'previous'}
         ELSE
            TXSTR    {'next'}
         ENDIF
         TXSTR    {' message: '}
MB_GKEY  JSR      GETCHAR
         CMPI.B   #'0',D1
         BLO.S    MB_CMD
         CMPI.B   #'9',D1
         BHI.S    MB_CMD
         JSR      TXCHAR
         LEA      BUFFER(A6),A1
         MOVE.B   D1,(A1)+
         MOVEQ    #1,D1
         MOVEQ    #6,D2
         JSR      GETLIN1
         BNE      MB_LOOP
         SUBA.W   D1,A1
         PEA      MB_LOOP
         JSR      READNUM
         BNE.S    MB_INERR
         MOVEQ    #'N',D6
RM_CURR1 TST.B    D1
         BEQ.S    INVMSG
         CMP.B    D7,D1
         BLS      GETMSG
INVMSG   TXSTR    {'Must be 1 to '}
         MOVE.B   D7,D1
         BSR      PRINTNUM
         TXSTR    {'!',CR,LF}
         RTS
MB_CMD   CMPI.B   #'?',D1
         BEQ      MB_FMENU
         CMPI.B   #CR,D1
         IF EQ THEN
            MOVEQ    #'N',D1
            TST.B    USERBUF+US_MBCMD(A6)
            IF NE THEN
               MOVEQ    #'P',D1
            ENDIF
         ENDIF
         LEA      MBCMDTBL,A1
         JSR      IN_LKUP
         BNE      MB_GKEY
         MOVE.B   D2,D6
         JSR      TXCHAR
         JSR      TXCRLF
         CMPI.B   #'A',D6
         BEQ      MB_AREA
         CMPI.B   #'Y',D6
         BEQ      MB_SCAN
         CMPI.B   #'Q',D6
         BEQ.S    MB_QUIT
         PEA      MB_LOOP
         MOVE.L   A1,-(A7)
         BSR.S    GET_CMSG
         MOVEQ    #0,D1
         MOVE.B   (A1),D1
MB_QUIT  RTS
MB_INERR TXSTR    {'Invalid input',CR,LF}
         RTS
GET_CMSG MOVEQ    #0,D0
         MOVE.B   USERBUF+US_MAREA(A6),D0
         ADD.W    D0,D0
         LEA      LASTREAD(A6),A1
         ADDA.W   D0,A1
         ADDQ.W   #1,A1
         RTS

MBCMDTBL STRING$  {'Mail'}
         STRING$  {LV.DISGR,'A',$5B,'A]rea change'}
         DC.W     MB_AREA-*
         STRING$  {LV.DISGR,'N',$5B,'N]ext'}
         DC.W     RM_NEXT-*
         STRING$  {LV.DISGR,'P',$5B,'P]revious'}
         DC.W     RM_BACK-*
         STRING$  {LV.DISGR,'.',$5B,'.]current'}
         DC.W     RM_CURR-*
         STRING$  {LV.DISGR,'-',$5B,'-]prev reply'}
         DC.W     RM_MIN-*
         STRING$  {LV.DISGR,'+',$5B,'+]next reply'}
         DC.W     RM_PLUS-*
         STRING$  {LV.DISGR,'C','read ',$5B,'C]ontinuous'}
         DC.W     RM_CONT-*
         STRING$  {LV.DISGR,'L',$5B,'L]ist'}
         DC.W     MB_LIST-*
         STRING$  {LV.DISGR,'Y',$5B,'Y]our mail'}
         DC.W     MB_SCAN-*
         STRING$  {LV.NORM,'D',$5B,'D]elete'}
         DC.W     RM_KILL-*
         STRING$  {LV.NORM,'E',$5B,'E]nter msg'}
         DC.W     WRITEMSG-*
         STRING$  {LV.EXTRA,'U',$5B,'U]pdate msg'}
         DC.W     UPDATMSG-*
         STRING$  {LV.NORM,'R',$5B,'R]eply'}
         DC.W     REPLYMSG-*
         STRING$  {LV.EXTRA,'K',$5B,'K]ludges'}
         DC.W     TKLUDGE-*
         STRING$  {LV.COSYS,'X',$5B,'X]port to file'}
         DC.W     MB_XPORT-*
         STRING$  {LV.DISGR,'S',$5B,'S]tatistics'}
         DC.W     STATS-*
         STRING$  {LV.TWIT,'Q',$5B,'Q]uit'}
         DC.W     MB_QUIT-*
         STRING$  {LV.TWIT,'G',$5B,'G]oodbye'}
         DC.W     LOGOFF-*
         DC.W     0

TKLUDGE  NOT.B    KLUDGE(A6)
         IF NE THEN
            TXSTR    {'Kludge display ON',CR,LF}
         ELSE
            TXSTR    {'Kludge display OFF',CR,LF}
         ENDIF
         CLR.L    MSGHDR+MS_DATE(A6)
         RTS

RM_CONT  TST.B    USERBUF+US_MBCMD(A6)
         BEQ.S    RM_NEXT
RM_BACK  ST       USERBUF+US_MBCMD(A6)
RM_BLP   SUBQ.B   #1,D1
         BLS.S    RM_B_END
         BSR      LOADMSG
         BLT      RM_BLP
         BSR      DISPMSG
         BNE.S    RM_B_RTS
         CMPI.B   #'C',D6
         BNE.S    RM_B_RTS
         BRA      RM_BLP
RM_B_END TXSTR    {'Start of available messages',CR,LF}
RM_B_RTS RTS
RM_MIN   BSR      LOAD_CUR
         BNE.S    RM_B_RTS
         MOVE.B   MSGHDR+MS_REPTO(A6),D1
         BNE.S    GETMSG
         TXSTR    {'This message is not a reply',CR,LF}
         RTS
RM_PLUS  BSR      LOAD_CUR
         BNE.S    RM_B_RTS
         MOVE.B   MSGHDR+MS_NXREP(A6),D1
         BNE.S    GETMSG
         TXSTR    {'This message has no reply',CR,LF}
         RTS
RM_NEXT  SF       USERBUF+US_MBCMD(A6)
RM_NLP   ADDQ.B   #1,D1
         CMP.B    D7,D1
         BHI.S    RM_N_MAX
         BSR      LOADMSG
         BLT      RM_NLP
         BSR.S    DISPMSG
         BNE.S    RM_N_END
         CMPI.B   #'C',D6
         BNE.S    RM_N_END
         BRA      RM_NLP
RM_N_MAX TXSTR    {'End of available messages',CR,LF}
         MOVE.B   D7,D1
RM_N_END BSR      GET_CMSG
         MOVE.B   D1,(A1)
         RTS

GETMSG   BSR      LOADMSG
         BGE.S    DISPMSG
         CMPI.L   #ERR.BO,D0
         BEQ.S    MSTOOBIG
         TXSTR    {'Invalid message',CR,LF}
GM_RTS   RTS
MSTOOBIG TXSTR    {'Message too big!',CR,LF}
         RTS
RM_CURR  BSR.S    LOAD_CUR
         BNE.S    GM_RTS
DISPMSG  MOVEM.W  D1/D6-D7,-(A7)
         BSR      GET_CMSG
         MOVE.B   D1,(A1)
         LEA      LOGBUF(A6),A1
         WRITE$   {'Reading message '},A1
         ANDI.W   #$FF,D1
         MOVEQ    #0,D2
         JSR      ITOD.W
         CLR.B    (A1)
         JSR      LOG0
         MOVEQ    #5,D5
         CMPI.B   #'C',D6
         BNE.S    DISPMSG2
         MOVEQ    #-128,D5
DISPMSG2 MOVE.W   (A7),D1
         BSR      TXMSG
         MOVE.L   D0,-(A7)
         JSR      TXCRLF
         MOVE.L   (A7)+,D0
         MOVEM.W  (A7)+,D1/D6-D7
         TST.L    D0
         RTS

LOAD_CUR BSR      GET_CMSG
         MOVEQ    #0,D1
         MOVE.B   (A1),D1
         TST.L    MSGHDR+MS_DATE(A6)
         BNE.S    GC_OK
         BSR.S    LOADMSG
         BGE.S    GC_OK
         TXSTR    {'Current message is invalid',CR,LF}
         MOVEQ    #-1,D0
         RTS
GC_OK    MOVEQ    #0,D0
         RTS

* Load message header (CHECKMSG) or whole message (LOADMSG)
* Entry: D1 message number
* Exit: D0=0 OK, >0 not from/to user, <0 invalid msg
*       A5 end of message text, MSGHDR, FROMUSER, TOUSER, SUBJECT set

CHECKMSG SF       D0
         BRA.S    CHKMSG1
LOADMSG  ST       D0
CHKMSG1  MOVEM.L  D0-D7/A0-A2,-(A7)
         BSR      OPM_EXCL
         MOVEQ    #-1,D3
         MOVE.B   7(A7),D1
         BSR      GET_MSGP
         MOVEQ    #-1,D4
         MOVE.L   D1,D7             Message offset in file
         BLT      CKM_END           if no message
         MOVEQ    #0,D4
         QDOS     FS.POSAB
         MOVEQ    #MS_TOUSR,D2
         LEA      MSGHDR(A6),A1
         BSR      CM_FSTRG
         LEA      TOUSER(A6),A1
         BSR      CM_FNAME
         LEA      FROMUSER(A6),A1
         BSR      CM_FNAME
         LEA      TOUSER(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      CMPNAME
         SNE      D5                D5 = 0 if msg addressed to this user
         LEA      FROMUSER(A6),A1
         JSR      CMPNAME
         SNE      D4
         AND.B    D5,D4             D4 = 0 if msg to or from this user
         MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A6),D0
         IF D0 HS.B #LV.COSYS THEN
            MOVEQ    #0,D4          (co)sysop can read all msgs
         ENDIF
         MOVE.W   MSGHDR+MS_ATTR(A6),D2
         BTST     #MS..PRIV,D2
         BEQ.S    CM_TSTRC          Msg is not private, it's OK
         EXT.W    D4
         EXT.L    D4
         BNE      CKM_END           This user may not read msg
CM_TSTRC SF       D6
         TST.B    D5
         BNE.S    CKM_SUBJ
         BTST     #MS..RCVD,D2
         SEQ      D6                D6 <> 0 if unread msg to this user
CKM_SUBJ LEA      SUBJECT(A6),A1
         BSR      CM_FNAME
         TST.B    3(A7)
         BEQ.S    CKM_END           Exit if CHECKMSG
         MOVEQ    #2,D2
         SUBA.W   D2,A7
         MOVE.L   A7,A1
         BSR      CM_FSTRG
         MOVE.W   (A7)+,D2          Text length
         LEA      MSG_BASE(A6),A1
         TST.W    D2
         IF NE THEN
            CMP.W    BUFSIZE(A6),D2
            IF HI THEN
               MOVEQ    #ERR.BO,D4
               BRA.S    CKM_END
            ENDIF
            BSR.S    CM_FSTRG
         ENDIF
         MOVE.L   A1,A5             A5 = End of message text
         TST.B    KLUDGE(A6)
         IF EQ THEN
            TST.W    MSGHDR+MS_DZONE(A6)
            IF LT THEN
               LEA      MSG_BASE(A6),A5      Strip SEEN-BY and PATH
               ADDA.W   MSGHDR+MS_DNET(A6),A5
            ENDIF
         ENDIF
         TST.B    D6
         BEQ.S    CKM_END
         MOVEQ    #MS_ATTR,D1
         ADD.L    D7,D1
         QDOS     FS.POSAB
         MOVE.W   MSGHDR+MS_ATTR(A6),D1
         BSET     #MS..RCVD,D1
         MOVE.W   D1,-(A7)
         MOVE.L   A7,A1
         MOVEQ    #2,D2
         QDOS     IO.SSTRG          Mark message as received
         ADDQ.W   #2,A7
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         MOVE.L   D1,-(A7)
         MOVEQ    #MS_RSDAT,D1
         ADD.L    D7,D1
         QDOS     FS.POSAB
         MOVEQ    #4,D2
         MOVE.L   A7,A1
         QDOS     IO.SSTRG          Enter date/time of receipt
         ADDQ.W   #4,A7
CKM_END  JSR      FCLOSE
         MOVE.L   D4,D0
         IF LT THEN
            CLR.L    MSGHDR(A6)
         ENDIF
         ADDQ.W   #4,A7
         MOVEM.L  (A7)+,D1-D7/A0-A2
         TST.L    D0
         RTS

CM_FNAME MOVE.L   A1,-(A7)
         QDOS     IO.FBYTE
         MOVE.L   (A7)+,A1
         TST.L    D0
         BNE.S    CM_IOERR
         MOVE.B   D1,(A1)+
         MOVEQ    #0,D2
         MOVE.B   D1,D2
CM_FSTRG QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    CM_IOERR
         RTS
CM_IOERR JMP      IO_ERROR

K_NOKILL TXSTR    {'Not allowed in EchoMail area',CR,LF}
         RTS
NO_KILL  TXSTR    {'Message NOT deleted',CR,LF}
         RTS
K_INVMSG TXSTR    {'NOT your message!',CR,LF}
         RTS
RM_KILL  MOVEQ    #US.LEVEL,D0
         AND.B    USERBUF+US_LEVEL(A6),D0
         CMPI.B   #LV.COSYS,D0
         BHS.S    RM_KILL1
         TST.B    ISECHO(A6)
         BNE      K_NOKILL
RM_KILL1 BSR      CHECKMSG
         BNE      K_INVMSG
         TXSTR    {'Delete message #'}
         MOVE.B   D1,D4
         BSR      PRINTNUM
         JSR      NOYES
         BNE      NO_KILL
KILLMSG  MOVE.B   D4,D1
         BSR      CHECKMSG
         BNE      K_INVMSG
         LEA      LOGBUF(A6),A1
         WRITE$   {'Deleting message '},A1
         MOVEQ    #0,D1
         MOVE.B   D4,D1
         MOVEQ    #0,D2
         JSR      ITOD.W
         CLR.B    (A1)
         JSR      LOG0
         BSR      OPM_EXCL
         MOVE.B   D4,D1
         MOVEQ    #-1,D3
         BSR      GET_MSGP
         MOVEQ    #-4,D1
         QDOS     FS.POSRE
         ST       D1
         QDOS     IO.SBYTE
         MOVE.B   MSGHDR+MS_REPTO(A6),D1
         IF NE THEN
            MOVEQ    #MS_NXREP,D5
            MOVE.B   MSGHDR+MS_NXREP(A6),D6
            BSR.S    RELINK
         ENDIF
         MOVE.B   MSGHDR+MS_NXREP(A6),D1
         IF NE THEN
            MOVEQ    #MS_REPTO,D5
            MOVE.B   MSGHDR+MS_REPTO(A6),D6
            BSR.S    RELINK
         ENDIF
         JSR      FCLOSE
         TXSTR    {'Message #'}
         MOVE.B   D4,D1
         BSR      PRINTNUM
         TXSTR    {' deleted',CR,LF}
         CLR.L    MSGHDR+MS_DATE(A6)
         RTS

RELINK   BSR      GET_MSGP
         BLT.S    REL_END
         ADD.L    D5,D1
         QDOS     FS.POSAB
         MOVE.B   D6,D1
         QDOS     IO.SBYTE
REL_END  RTS

MB_LIST  MOVE.B   D1,D6
         LEA      BUFFER(A6),A1
         MOVEQ    #6,D2
         INPUT    {'List from msg # (<ENTER> = current): '}
         SUBQ.W   #1,D1
         IF NE THEN
            JSR      READNUM
            BNE      MB_INERR
            MOVE.B   D1,D6
         ENDIF
         LOG      {'Listing messages',LF}
         TXSTR    {CR,LF,'  # Date  From                 To                   Subject',CR,LF}
         TXSTR    {'--- ----- -------------------- -------------------- ---------------------------',CR,LF}
         MOVEQ    #2,D5
         TST.B    D6
         BNE.S    RML_LP
         MOVEQ    #1,D6
RML_LP   CMP.B    D7,D6
         BHI      RML_END
         MOVE.B   D6,D1
         BSR      CHECKMSG
         BLT.S    RML_NXT
         LEA      BUFFER(A6),A1
         MOVEQ    #0,D1
         MOVE.B   D6,D1
         MOVEQ    #3,D2
         MOVEQ    #' ',D3
         JSR      ITOD.W
         MOVE.B   #' ',(A1)+
         MOVE.L   MSGHDR+MS_DATE(A6),D1
         JSR      DATE
         MOVEQ    #' ',D0
         MOVE.B   D0,-(A1)
         MOVE.B   D0,-(A1)
         MOVE.B   D0,-1(A1)
         MOVEQ    #20,D2
         LEA      FROMUSER(A6),A0
         BSR.S    RML_COPY
         MOVE.B   #' ',(A1)+
         BTST     #MS..RCVD,MSGHDR+MS_ATTR+1(A6)
         BNE.S    RML_TO
         MOVE.L   A1,-(A7)
         LEA      TOUSER(A6),A1
         LEA      USERBUF+US_NAME(A6),A2
         JSR      CMPNAME
         MOVE.L   (A7)+,A1
         BNE.S    RML_TO
         MOVE.B   #'*',-1(A1)
RML_TO   MOVEQ    #20,D2
         LEA      TOUSER(A6),A0
         BSR.S    RML_COPY
         MOVE.B   #' ',(A1)+
         MOVEQ    #27,D2
         LEA      SUBJECT(A6),A0
         BSR.S    RML_COPY
         MOVE.L   A1,D1
         LEA      BUFFER(A6),A1
         SUB.L    A1,D1
         REPEAT
            JSR      TXLINE
         UNTIL    LE
         BLT.S    RML_END
RML_NXT  ADDQ.B   #1,D6
         BNE      RML_LP
RML_END  JMP      TXCRLF

RML_COPY MOVEQ    #0,D0
         MOVE.B   (A0)+,D0
         CMP.W    D2,D0
         IF HI THEN
            MOVE.W   D2,D0
         ENDIF
         MOVE.W   D0,D1
         BRA.S    RML_C1
RML_CLP  MOVE.B   (A0)+,(A1)+
RML_C1   DBF      D0,RML_CLP
         SUB.W    D1,D2
         BLE.S    RMLC_RTS
         MOVEQ    #' ',D0
RML_CSP  MOVE.B   D0,(A1)+
         SUBQ.W   #1,D2
         BGT      RML_CSP
RMLC_RTS RTS

MB_XPORT BSR      LOAD_CUR
         BNE.S    MBX_END
         MOVE.W   D1,D6
         MOVEQ    #50,D2
         LEA      BUFFER+2(A6),A1
         INPUT    {CR,LF,'File to write message to: '}
         SUBQ.W   #1,D1
         BLE.S    MBX_END
         MOVE.W   D1,-(A1)
         MOVE.L   A1,A0
         MOVEQ    #-1,D1
         MOVEQ    #IO.NEW,D3
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    MBX_EXP
         CMPI.L   #ERR.EX,D0
         BNE.S    MBX_ERR
         MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         LEA      BUFFER(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    MBX_ERR
         MOVE.L   #9999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
MBX_EXP  MOVE.L   A0,INPCHAN(A6)
         ST       SPEC_OUT(A6)
         MOVE.W   D6,D1
         BSR.S    TXMSG
         SF       SPEC_OUT(A6)
         JMP      FCLOSE
MBX_ERR  TXSTR    {'Unable to open file',CR,LF}
MBX_END  RTS

* Print name & possibly "on zone:net/node.point"
* Entry: A1 ptr to name, A2 ptr to zone, net, node, point

TXUSER   JSR      PRINTNAM
         TST.B    ISNET(A6)
         BEQ.S    TXU_END
         TXSTR    {' on '}
         SUBA.W   #32,A7
         MOVE.L   A7,A1
         JSR      ZNNP2A
         MOVE.L   A1,D2
         MOVE.L   A7,A1
         SUB.L    A1,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         ADDA.W   #32,A7
TXU_END  JMP      TXCRLF

TXMSG    MOVE.W   D1,-(A7)
         JSR      TXCRLF
         MOVEQ    #'#',D1
         JSR      TXCHAR
         MOVE.W   (A7)+,D1
         BSR      PRINTNUM
         TXSTR    {'  '}
TXMSG_2  MOVE.L   MSGHDR+MS_DATE(A6),D1
         LEA      BUFFER(A6),A1
         JSR      DATE$
         SUBA.W   D2,A1
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         MOVE.L   MSGHDR+MS_RSDAT(A6),D1
         IF NE THEN
            TXSTR    {'     ('}
            BTST     #MS..RCVD,MSGHDR+MS_ATTR+1(A6)
            IF NE THEN
               TXSTR    {'Received: '}
            ELSE
               TXSTR    {'Sent: '}
            ENDIF
            LEA      BUFFER(A6),A1
            JSR      DATE$
            SUBA.W   D2,A1
            MOVEQ    #SP.SSTRG,D0
            JSR      DO_OUTP
            MOVEQ    #')',D1
            JSR      TXCHAR
         ENDIF
         JSR      TXCRLF
         TXSTR    {'From: '}
         LEA      FROMUSER(A6),A1
         LEA      MSGHDR+MS_OZONE(A6),A2
         BSR      TXUSER
         TXSTR    {'  To: '}
         LEA      TOUSER(A6),A1
         LEA      MSGHDR+MS_DZONE(A6),A2
         BSR      TXUSER
         TXSTR    {'Subj: '}
         LEA      SUBJECT(A6),A1
         JSR      PRINTNAM
         JSR      TXCRLF
         MOVE.W   MSGHDR+MS_ATTR(A6),D1
         ANDI.W   #%1000101011111111,D1
         BEQ      TXMSG_3
         ADDQ.W   #1,D5
         TXSTR    {'Attr:'}
         BTST     #MS..PRIV,D1
         IF NE THEN
            TXSTR    {' Pvt'}
         ENDIF
         BTST     #MS..CRSH,D1
         IF NE THEN
            TXSTR    {' Crash'}
         ENDIF
         BTST     #MS..RCVD,D1
         IF NE THEN
            TXSTR    {' Rcvd'}
         ENDIF
         BTST     #MS..SENT,D1
         IF NE THEN
            TXSTR    {' Sent'}
         ENDIF
         BTST     #MS..FATT,D1
         IF NE THEN
            TXSTR    {' File'}
         ENDIF
         BTST     #MS..TRNS,D1
         IF NE THEN
            TXSTR    {' InTransit'}
         ENDIF
         BTST     #MS..ORPH,D1
         IF NE THEN
            TXSTR    {' Orphan'}
         ENDIF
         BTST     #MS..KSNT,D1
         IF NE THEN
            TXSTR    {' KillSent'}
         ENDIF
         BTST     #MS..HOLD,D1
         IF NE THEN
            TXSTR    {' Hold'}
         ENDIF
         BTST     #MS..FREQ,D1
         IF NE THEN
            TXSTR    {' FileReq'}
         ENDIF
         BTST     #MS..UREQ,D1
         IF NE THEN
            TXSTR    {' UpdReq'}
         ENDIF
         JSR      TXCRLF
TXMSG_3  TST.W    MSGHDR+MS_REPTO(A6)
         BEQ.S    TXMSG_4
         ADDQ.W   #1,D5
         TXSTR    {'Reply chain: '}
         MOVE.B   MSGHDR+MS_REPTO(A6),D1
         IF NE THEN
            BSR      PRINTNUM
            TXSTR    {' <-- '}
         ENDIF
         MOVE.B   MSGHDR+MS_NXREP(A6),D1
         IF NE THEN
            TXSTR    {' --> '}
            BSR      PRINTNUM
         ENDIF
         JSR      TXCRLF
TXMSG_4  JSR      TXCRLF
TXMSG_T  LEA      MSG_BASE(A6),A1
         MOVEQ    #1,D6
         MOVEQ    #0,D7
TXM_LOOP CMPA.L   A5,A1
         BHS.S    TXM_END
         BSR.S    GET_PARA
         BEQ      TXM_LOOP
TXM_LP2  BSR.S    TXM_LINE
         BGT      TXM_LP2
         BLT.S    TXM_RTS
         BRA      TXM_LOOP
TXM_END  MOVEQ    #0,D0
TXM_RTS  RTS

GET_PARA CMPI.B   #QON,(A1)
         BNE.S    GP_QOFF
         ADDQ.W   #1,D7
         BRA.S    GP_SKIP
GP_QOFF  CMPI.B   #QOFF,(A1)
         BNE.S    GP_GTLEN
         SUBQ.W   #1,D7
GP_SKIP  ADDQ.W   #1,A1
         BRA      GET_PARA
GP_GTLEN MOVE.L   A1,A0
         MOVEQ    #CR,D0
GP_FINDC CMP.B    (A0)+,D0
         BNE      GP_FINDC
         MOVE.L   A0,D1
         SUB.L    A1,D1
         TST.B    KLUDGE(A6)
         BNE.S    GP_END
         CMPI.B   #1,(A1)
         BNE.S    GP_END
         MOVE.L   A0,A1
GP_END   RTS

TXM_LINE TST.B    PRINTLIN(A6)
         BEQ.S    TXM_WID
         TST.W    D5
         BLT.S    TXM_WID
         MOVE.W   D1,-(A7)
         JSR      ASKMORE
         BNE.S    TXMABORT
         MOVE.W   (A7)+,D1
TXM_WID  MOVEQ    #0,D2
         MOVE.B   USERBUF+US_WIDTH(A6),D2
         TST.B    LINUMFLG(A6)
         BEQ.S    TXM_QUOT
         BSR.S    TX_LINUM
         ADDQ.W   #1,D6
         SUBQ.W   #4,D2
TXM_QUOT TST.W    D7
         BEQ.S    TXM_LIN2
         SUBQ.W   #2,D2
         MOVE.W   D7,D3
         CMPI.W   #8,D3
         BLE.S    TXM_QUO2
         MOVEQ    #8,D3
TXM_QUO2 SUB.W    D3,D2
         TST.B    PRINTLIN(A6)
         BEQ.S    TXM_LIN2
         MOVEM.L  D1/A1,-(A7)
         MOVEQ    #' ',D1
         JSR      TXCHAR
TXM_QUO3 MOVEQ    #'>',D1
         JSR      TXCHAR
         SUBQ.W   #1,D3
         BGT      TXM_QUO3
         MOVEQ    #' ',D1
         JSR      TXCHAR
         MOVEM.L  (A7)+,D1/A1
TXM_LIN2 MOVE.W   D5,-(A7)
         MOVEQ    #0,D5
         CMPI.B   #1,(A1)
         IF EQ THEN
            MOVE.W   D1,-(A7)
            MOVEQ    #'@',D1
            JSR      TXCHAR
            MOVE.W   (A7)+,D1
            SUBQ.W   #1,D1
            ADDQ.W   #1,A1
         ENDIF
         JSR      TXLINE2
         MOVE.W   (A7)+,D5
         TST.L    D0
         RTS
TXMABORT JSR      TXCRLF
         MOVE.W   (A7)+,D1
         MOVEQ    #-1,D0
         RTS

TX_LINUM TST.B    PRINTLIN(A6)
         BEQ.S    TXL_END
         MOVEM.L  D0-D3/A1,-(A7)
         SUBQ.W   #2,A7
         MOVE.L   A7,A1
         MOVEQ    #0,D1
         MOVE.W   D6,D1
         DIVU     #100,D1
         SWAP     D1
         MOVEQ    #2,D2
         MOVEQ    #' ',D3
         JSR      ITOD.W
         MOVE.L   A7,A1
         MOVEQ    #2,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         ADDQ.W   #2,A7
         TXSTR    {': '}
         MOVEM.L  (A7)+,D0-D3/A1
TXL_END  RTS

         END
