* QBOX File section, Sysop commands and XMODEM logic

         INCLUDE  WIN1_MACRO_LIB
         INCLUDE  WIN1_QDOS_IN_MAC
         INCLUDE  WIN3_QBDEV_QBOX_H

         DATA     0

         XREF     TXCHAR,LOG,IO_ERROR,TXCRLF,TXSTR,TXLINE,COPYSPC,LOGOFF,LOG1
         XREF     INDEXER,OP_FDIR,OP_FIN,OP_FNEW,DIRCLOSE,FCLOSE,NOYES,TXLINE2
         XREF     DATE$,ITOD.L,TYPE,YESNO,INPUT,OP_ERROR,TOUPPER,PAUSE,ASKMORE
         XREF     DATE,TXNUMBER,DO_OUTP,FLUSH,DO_INP,SELFAREA,SETFAREA,LOG0
         XREF     WRITEERR,ITOD.W,DIVLONG,GETCHAR,TOUPPER,TXLF,CPSTAB,CHKTIME
         XREF     RX_CLINK,TX_CLINK,PURGE_LP,STATS,WRITE$,WRITEL$

         SECTION  CODE

         XDEF     FILES

FILES    JSR      SETFAREA
         LOG      {'File section',LF}
FILES_LP TXSTR    {CR,LF,'File area '}
         MOVEQ    #0,D1
         MOVE.B   USERBUF+US_FAREA(A6),D1
         ADDQ.W   #1,D1
         JSR      TXNUMBER
         TXSTR    {': '}
         LEA      AREANAME(A6),A1
         JSR      TXSTR
         LEA      F_INDEX,A1
         JSR      INDEXER
         BRA      FILES_LP

F_QUIT   ADDQ.W   #4,A7
         RTS

F_INDEX  STRING$  {'Files'}
         STRING$  {LV.DISGR,'A',$5B,'A]rea change'}
         DC.W     SELFAREA-*
         STRING$  {LV.DISGR,'F',$5B,'F]ile list'}
         DC.W     CATALOG-*
         STRING$  {LV.DISGR,'V',$5B,'V]iew'}
         DC.W     FTYPE-*
         STRING$  {LV.NORM,'D',$5B,'D]ownload'}
         DC.W     FDOWNLD-*
         STRING$  {LV.NORM,'U',$5B,'U]pload'}
         DC.W     FUPLD-*
         STRING$  {LV.COSYS,'R',$5B,'R]aw directory'}
         DC.W     RAWDIR-*
         STRING$  {LV.COSYS,'K',$5B,'K]ill file'}
         DC.W     FKILL-*
         STRING$  {LV.COSYS,'O',$5B,'O]verride directory'}
         DC.W     NEWDIR-*
         STRING$  {LV.DISGR,'S',$5B,'S]tatistics'}
         DC.W     STATS-*
         STRING$  {LV.TWIT,'Q',$5B,'Q]uit'}
         DC.W     F_QUIT-*
         STRING$  {LV.TWIT,'G',$5B,'G]oodbye'}
         DC.W     LOGOFF-*
         DC.W     0

LOOKDIR  MOVEQ    #1,D3
         JSR      OP_FDIR
         BNE      OP_ERROR
LD_LOOP  LEA      BUFFER(A6),A1
         MOVE.W   BUFSIZE(A6),D2
         MOVEQ    #-1,D3
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    LD_NOTF
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BLE      LD_LOOP
         CMPI.B   #' ',(A1)
         BEQ      LD_LOOP
         CMPI.B   #'*',(A1)
         BEQ      LD_LOOP
         CMPI.B   #'-',(A1)
         BEQ      LD_LOOP
         CMPI.B   #';',(A1)
         BEQ      LD_LOOP
         LEA      USERBUF2(A6),A2
         MOVE.W   (A2)+,D2
LD_CMP   MOVE.B   (A1)+,D1
         CMPI.B   #LF,D1
         BEQ.S    LD_MATCH
         CMPI.B   #' ',D1
         BEQ.S    LD_MATCH
         SUBQ.W   #1,D2
         BLT      LD_LOOP
         JSR      TOUPPER
         MOVE.B   D1,D0
         MOVE.B   (A2)+,D1
         JSR      TOUPPER
         CMP.B    D1,D0
         BEQ      LD_CMP
         BRA      LD_LOOP
LD_MATCH TST.W    D2
         BNE      LD_LOOP
         JSR      DIRCLOSE
         MOVEQ    #0,D0
         RTS
LD_NOTF  JSR      DIRCLOSE
         MOVEQ    #ERR.NF,D0
         RTS

CATALOG  LOG      {'Files - list',LF}
         JSR      TXCRLF
         MOVEQ    #IO.SHARE,D3
         JSR      OP_FDIR
         IF NE THEN
            CMPI.L   #ERR.NF,D0
            IF EQ THEN
               TXSTR    {'No files',CR,LF}
            ELSE
               LEA      LOGBUF(A6),A1
               WRITE$   {'? Can''t open FILES_BBS: '},A1
               JSR      WRITEERR
               CLR.B    -1(A1)
               JSR      LOG0
               TXSTR    {'*** Error accessing FILES_BBS, please notify sysop',CR,LF}
            ENDIF
            RTS
         ENDIF
         MOVEQ    #0,D5
CAT_LOOP MOVE.L   DIRCHAN(A6),A0
         MOVEQ    #-1,D3
         QDOS     IO.FBYTE
         TST.L    D0
         BNE      CAT_END
         MOVEQ    #0,D6
         MOVEQ    #0,D7
         LEA      BUFFER+2(A6),A1
         CMPI.B   #LF,D1
         BEQ      CAT_NULL
         CMPI.B   #' ',D1
         BEQ      CAT_CMT
         CMPI.B   #'-',D1
         BEQ      CAT_CMT
         CMPI.B   #'*',D1
         BEQ      CAT_CMT
         CMPI.B   #';',D1
         BEQ      CAT_CMT
         MOVE.L   A1,A2
         MOVE.B   D1,(A2)+
         MOVEQ    #1,D2
CAT_GFN  QDOS     IO.FBYTE
         TST.L    D0
         BNE      CAT_END
         CMPI.B   #LF,D1
         BEQ.S    CAT_ECMT
         CMPI.B   #' ',D1
         BEQ.S    CAT_GSTA
         MOVE.B   D1,(A2)+
         ADDQ.W   #1,D2
         BRA      CAT_GFN
CAT_ECMT MOVEQ    #-1,D1
         QDOS     FS.POSRE
CAT_GSTA MOVEQ    #17,D0
         SUB.W    D2,D0
         BGT.S    CAT_FILL
         MOVEQ    #1,D0
CAT_FILL MOVE.B   #' ',(A2)+
         SUBQ.W   #1,D0
         BGT      CAT_FILL
         LEA      BUFFER(A6),A0
         MOVE.W   D2,(A0)
         LEA      DIRBUF(A6),A1
         JSR      OP_FIN
         BNE.S    CAT_MISS
         LEA      USERBUF2(A6),A1
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
         QDOS     FS.HEADR
         JSR      FCLOSE
         MOVE.L   USERBUF2(A6),D1
         MOVEQ    #7,D3
         MOVE.L   A2,A1
         JSR      ITOD.L
         MOVE.B   #' ',(A1)+
         MOVE.L   USERBUF2+$34(A6),D1
         JSR      DATE
         MOVEQ    #' ',D0
         CMP.L    LASTCALL(A6),D1
         BLS.S    CAT_FLAG
         MOVEQ    #'*',D0
CAT_FLAG MOVE.B   D0,(A1)+
         MOVE.B   #' ',(A1)+
         BRA.S    CAT_REM
CAT_MISS MOVE.L   A2,A1
         LEA      MISSMSG,A0
         MOVEQ    #7,D0
         REPEAT
            MOVE.B   (A0)+,(A1)+
            SUBQ.W   #1,D0
         UNTIL    LE
         MOVEQ    #11,D0
         REPEAT
            MOVE.B   #' ',(A1)+
            SUBQ.W   #1,D0
         UNTIL    LE
CAT_REM  MOVE.L   A1,D7
         LEA      BUFFER+2(A6),A0
         SUB.L    A0,D7
CAT_CMT  MOVE.W   BUFSIZE(A6),D2
         MOVEQ    #-1,D3
         MOVE.L   DIRCHAN(A6),A0
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    CAT_END
         SUBQ.W   #1,D1
         ADD.W    D7,D1
         LEA      BUFFER+2(A6),A1
         BRA.S    CAT_DISP
CAT_NULL MOVEQ    #0,D1
CAT_DISP MOVE.W   D1,-(A7)
         JSR      ASKMORE
         BNE.S    CAT_END2
         MOVEQ    #0,D2
         MOVE.B   USERBUF+US_WIDTH(A6),D2
         SUB.W    D6,D2
         CMPI.W   #20,D2
         IF GE THEN
            BSR.S    DSP_TAB
         ELSE
            ADD.W    D6,D2
         ENDIF
         MOVE.W   (A7)+,D1
         MOVE.W   D5,-(A7)
         MOVEQ    #0,D5
         JSR      TXLINE2
         MOVE.W   (A7)+,D5
         MOVE.W   D7,D6
         TST.L    D0
         BGT      CAT_DISP
         BLT.S    CAT_END
         BRA      CAT_LOOP
CAT_END2 MOVE.W   (A7)+,D1
CAT_END  JSR      TXCRLF
         JMP      DIRCLOSE

DSP_TAB  SUBQ.W   #1,D6
         BLT.S    DTB_END
         MOVEQ    #' ',D1
         JSR      TXCHAR
         BRA      DSP_TAB
DTB_END  RTS

         SECTION  MSG
MISSMSG  DC.B     'MISSING'
         SECTION  CODE

* Get file transfer protocol

GET_PROT TXSTR    {CR,LF,'Choose a protocol:',CR,LF,LF}
         TXSTR    {$5B,'X]modem',CR,LF}
         TXSTR    {$5B,'T]elink (*)',CR,LF}
         TXSTR    {$5B,'S]EAlink (*)',CR,LF}
         TXSTR    {LF,$5B,'(*) indicates batch transfer possible]',CR,LF,LF}
         TXSTR    {'Protocol (or "Q" to quit): '}
GP_ASK   JSR      GETCHAR
         JSR      TOUPPER
         CMPI.B   #'Q',D1
         BEQ.S    GP_QUIT
         SF       D2
         CMPI.B   #'X',D1
         BEQ.S    SET_PROT
         ST       D2
         CMPI.B   #'T',D1
         BEQ.S    SET_PROT
         CMPI.B   #'S',D1
         BNE      GP_ASK
SET_PROT MOVE.B   D1,FXPROT(A6)
         MOVE.B   D2,FXBATCH(A6)
         BRA.S    GP_QUIT2
GP_QUIT  CLR.B    FXPROT(A6)
GP_QUIT2 JSR      TXCHAR
         JSR      TXCRLF
         JMP      TXLF

* Get file name (D7 counts #)

GETFNAME TXSTR    {'File name'}
         TST.W    D7
         IF NE THEN
            TXSTR    {' (#'}
            MOVE.W   D7,D1
            JSR      TXNUMBER
            MOVEQ    #')',D1
            JSR      TXCHAR
         ENDIF
         TXSTR    {': '}
         LEA      FILENAME+2(A6),A1
         MOVEQ    #21,D2
         SUBA.L   A0,A0
         JSR      INPUT
         SUBQ.W   #1,D1
         BLE.S    GFN_ABT
         MOVE.W   D1,-(A1)
         MOVEQ    #0,D0
         RTS
GFN_ABT  MOVEQ    #-1,D0
         RTS

* Check validity of file to be downloaded

CHK_FILE LEA      FILENAME(A6),A0
         LEA      DIRBUF(A6),A1
         JSR      OP_FIN
         BNE      CHKF_NF
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      CHKF_NF2
         MOVE.L   -4(A1),D1
         MOVEQ    #0,D3
         LEA      FILENAME(A6),A0
         LEA      BUFFER+10(A6),A1
         WRITE$
         MOVE.B   #';',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      ITOD.L
         MOVE.B   #'b',(A1)+
         MOVE.B   BPS(A6),D0
         EXT.W    D0
         EXT.L    D0
         BLT.S    CHKF_2
         ADD.W    D0,D0
         LEA      CPSTAB,A0
         MOVE.W   (A0,D0.W),D2
         JSR      DIVLONG
         MOVE.L   D1,D0
         DIVU     #60,D1
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         MOVE.B   #';',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      ITOD.W
         MOVE.B   #':',(A1)+
         SWAP     D1
         JSR      ITOD.W
CHKF_2   MOVE.L   D0,BUFFER+4(A6)
         MOVE.L   A1,D0
         LEA      BUFFER+10(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
         JSR      TXSTR
         JSR      TXCRLF
         MOVE.L   BUFFER+4(A6),D2
         BMI.S    CHKF_OK2
         MOVE.L   D2,D0
         ADD.L    SECSCNT(A6),D0
         JSR      CHKTIME
         BGE.S    CHKF_OK
         TXSTR    {'This download would exceed your time limit',CR,LF}
         JSR      FCLOSE
         MOVEQ    #ERR.NC,D0
         LEA      LOGBUF(A6),A1
         WRITE$   {'Not enough time to download "'},A1
         BRA.S    CHKF_LOG
CHKF_NF2 JSR      FCLOSE
CHKF_NF  TXSTR    {'There is no file "'}
         LEA      FILENAME(A6),A1
         JSR      TXSTR
         MOVEQ    #'"',D1
         JSR      TXCHAR
         JSR      TXCRLF
         MOVEQ    #ERR.NF,D0
         LEA      LOGBUF(A6),A1
         WRITE$   {'Attempted to download unknown file "'},A1
         BRA.S    CHKF_LOG
CHKF_OK  ADD.L    D2,SECSCNT(A6)
CHKF_OK2 MOVE.L   BUFFER(A6),D0
         ADD.L    D0,BYTECNT(A6)
         ADDQ.W   #1,FILECNT(A6)
         MOVEQ    #0,D0
         LEA      LOGBUF(A6),A1
         WRITE$   {'Download "'},A1
CHKF_LOG LEA      FILENAME(A6),A0
         WRITE$
         MOVE.B   #'"',(A1)+
         CLR.B    (A1)+
         JSR      LOG0
         TST.L    D0
         RTS

* Put file into queue

PUTFILE  MOVEQ    #15,D1
         ADD.W    FILENAME(A6),D1
         BCLR     #0,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BNE.S    PF_END
         LEA      FILE_Q(A6),A1
PF_LOOP  TST.L    (A1)
         BEQ.S    PF_NEW
         MOVE.L   (A1),A1
         BRA      PF_LOOP
PF_NEW   MOVE.L   A0,(A1)
         ADDQ.L   #4,A0
         LEA      BUFFER(A6),A1
         MOVE.L   (A1)+,(A0)+
         MOVE.L   (A1)+,(A0)+
         LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D1
         MOVE.W   D1,(A0)+
PF_CPY   MOVE.B   (A1)+,(A0)+
         SUBQ.W   #1,D1
         BGT      PF_CPY
PF_END   TST.L    D0
         RTS

* Remove file from queue (A0 = queue addr)

REMVFILE LEA      FILE_Q(A6),A1
RF_CMP   MOVE.L   (A1),D0
         BEQ.S    RF_END
         CMP.L    A0,D0
         BEQ.S    RF_UNLK
         MOVE.L   D0,A1
         BRA      RF_CMP
RF_UNLK  SUBQ.W   #1,FILECNT(A6)
         MOVE.L   4(A0),D0
         SUB.L    D0,BYTECNT(A6)
         MOVE.L   8(A0),D0
         SUB.L    D0,SECSCNT(A6)
         MOVE.L   (A0),(A1)
         QDOS     MT.RECHP
RF_END   RTS

* Clear whole queue

CLEAR_Q  MOVE.L   FILE_Q(A6),D0
         BEQ      RF_END
         MOVE.L   D0,A0
         BSR      REMVFILE
         BRA      CLEAR_Q

FTYPE    MOVEQ    #0,D7
         BSR      GETFNAME
         BLT.S    FTYP_RTS
         LEA      LOGBUF(A6),A1
         WRITE$   {'Files - view '},A1
         LEA      FILENAME(A6),A0
         WRITE$
         CLR.B    (A1)+
         JSR      LOG0
         LEA      FILENAME(A6),A0
         LEA      DIRBUF(A6),A1
         JSR      TYPE
         BEQ.S    FTYP_RTS
FTYP_ERR MOVEQ    #'"',D1
         JSR      TXCHAR
         LEA      FILENAME(A6),A1
         JSR      TXSTR
         TXSTR    {'" does not exist',CR,LF}
FTYP_RTS RTS

FDOWNLD  LOG      {'Files - download',LF}
         BSR      GET_PROT
         TST.B    FXPROT(A6)
         BEQ.S    FTYP_RTS
         CLR.W    FILECNT(A6)
         CLR.L    BYTECNT(A6)
         CLR.L    SECSCNT(A6)
         MOVEQ    #0,D7
         TST.B    FXBATCH(A6)
         BEQ.S    FD_LOOP
         MOVEQ    #1,D7
FD_LOOP  BSR      GETFNAME
         BLT.S    FD_CONT
         BSR      CHK_FILE
         BNE      FD_LOOP
         TST.B    FXBATCH(A6)
         BEQ.S    FD_CONT
         JSR      FCLOSE
         ADDQ.W   #1,D7
         BSR      PUTFILE
         BEQ      FD_LOOP
         TXSTR    {'No room for more files!',CR,LF}
         SUBQ.W   #1,FILECNT(A6)
         MOVE.L   BUFFER(A6),D0
         SUB.L    D0,BYTECNT(A6)
         MOVE.L   BUFFER+4(A6),D0
         SUB.L    D0,SECSCNT(A6)
FD_CONT  TST.W    FILECNT(A6)
         BEQ      FTYP_RTS
         TXSTR    {CR,LF,'Total files: '}
         MOVE.W   FILECNT(A6),D1
         JSR      TXNUMBER
         TXSTR    {CR,LF,'Total bytes: '}
         MOVE.L   BYTECNT(A6),D1
         MOVEQ    #0,D3
         LEA      BUFFER(A6),A1
         JSR      ITOD.L
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         TST.B    BPS(A6)
         IF PL THEN
            TXSTR    {CR,LF,'Total transfer time: '}
            MOVE.L   SECSCNT(A6),D1
            DIVU     #60,D1
            JSR      TXNUMBER
            TXSTR    {' minute'}
            CMPI.W   #1,D1
            IF NE THEN
               MOVE.L   D1,-(A7)
               MOVEQ    #'s',D1
               JSR      TXCHAR
               MOVE.L   (A7)+,D1
            ENDIF
            TXSTR    {' and '}
            SWAP     D1
            JSR      TXNUMBER
            TXSTR    {' second'}
            CMPI.B   #1,D1
            IF NE THEN
               MOVEQ    #'s',D1
               JSR      TXCHAR
            ENDIF
         ENDIF
         TST.B    LOCALMOD(A6)
         BNE      FD_END
         TXSTR    {CR,LF,LF,'Start downloading now, or type <CTRL-X> several times to cancel',CR,LF,LF}
         MOVEQ    #1,D7
         TST.B    FXBATCH(A6)
         BEQ.S    FD_SEND
FD_GFILE MOVE.L   FILE_Q(A6),D0
         BEQ      FD_BEND
         MOVE.L   D0,A0
         LEA      12(A0),A0
         LEA      FILENAME(A6),A1
         MOVE.W   (A0)+,D0
         MOVE.W   D0,(A1)+
FD_GNAME MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D0
         BGT      FD_GNAME
         MOVE.L   #1<<WANT_C+1,D7
         CMPI.B   #'S',FXPROT(A6)
         IF NE THEN
            MOVE.L   #1<<TELINK+1,D7
         ENDIF
         LEA      FILENAME(A6),A0
         LEA      DIRBUF(A6),A1
         JSR      OP_FIN
         BEQ.S    FD_SEND
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Unable to open file '},A1
         LEA      FILENAME(A6),A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
         BRA.S    FD_UNQ
FD_SEND  JSR      TX_CLINK
         MOVE.L   D0,-(A7)
         JSR      FCLOSE
         MOVE.L   (A7)+,D0
         BNE.S    FD_ERR
         TST.B    FXBATCH(A6)
         BEQ.S    FD_END
FD_UNQ   MOVE.L   FILE_Q(A6),A0
         JSR      REMVFILE
         BRA      FD_GFILE
FD_BEND  CLR.W    FILENAME(A6)
         MOVEQ    #0,D7
         JSR      TX_CLINK
FD_END   TXSTR    {CR,LF,'Transfer completed',CR,LF}
         MOVEQ    #0,D0
         RTS
FD_ERR   JSR      CLEAR_Q
         TXSTR    {CR,LF,'Transfer failed',CR,LF}
         MOVEQ    #-1,D0
FD_RTS   RTS

FUPLD    LOG      {'Files - upload',LF}
         BSR      GET_PROT
         TST.B    FXPROT(A6)
         BEQ      FUPL_NC
         MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3
         LEA      DIRBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    UPL_SPC
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Unable to open directory "'},A1
         LEA      DIRBUF(A6),A0
         WRITE$
         MOVE.B   #'"',(A1)+
         CLR.B    (A1)+
         JSR      LOG0
         TXSTR    {'ERROR: Unable to open upload directory. Please notify sysop!',CR,LF}
         MOVEQ    #-1,D0
         RTS
UPL_SPC  BSR      GETMDINF
         TXSTR    {'Available disk space for upload: '}
         LSR.L    #1,D1
         MOVEQ    #0,D3
         LEA      BUFFER(A6),A1
         JSR      ITOD.L
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         TXSTR    {'K',CR,LF,LF}
         QDOS     IO.CLOSE
         BSR      CLEAR_Q
         MOVEQ    #0,D7
         TST.B    FXBATCH(A6)
         BNE.S    UPL_GTIM
         BSR      GETFNAME
         BLT      FUPL_NC
         MOVEQ    #US.LEVEL,D4
         AND.B    USERBUF+US_LEVEL(A6),D4
         BSR      LOOKDIR
         SEQ      D7
         BNE.S    UPL_OPEN
         CMPI.B   #LV.COSYS,D4
         BLO      FUPL_EX
UPL_OPEN LEA      FILENAME(A6),A0
         LEA      DIRBUF(A6),A1
         JSR      OP_FIN
         BNE.S    UPL_GTIM
         JSR      FCLOSE
         CMPI.B   #LV.COSYS,D4
         BLO      FUPL_EX
         LEA      FILENAME(A6),A1
         JSR      TXSTR
         TXSTR    {' exists, overwrite'}
         JSR      NOYES
         BNE      FUPL_NC
         BSR      FUPL_DEL
UPL_GTIM CLR.W    FILECNT(A6)
         CLR.L    BYTECNT(A6)
         CLR.L    SECSCNT(A6)
         QDOS     MT.RCLCK
         MOVE.W   D7,-(A7)
         MOVE.L   D1,-(A7)
         TXSTR    {CR,LF,'Start uploading now, or type <CTRL-X> several times to cancel',CR,LF,LF}
         MOVEQ    #2*50,D3
         JSR      PAUSE
         MOVEQ    #0,D3
         JSR      PURGE_LP
UPL_NEXT MOVEQ    #1,D7
         TST.B    FXBATCH(A6)
         BEQ.S    UPL_NOW
         BSET     #WANT_C,D7
         LEA      FILENAME(A6),A1
         WRITEL$  'NONAME',A1
UPL_NOW  LEA      DIRBUF(A6),A1
         JSR      RX_CLINK
         TST.L    D0
         BEQ.S    UP_GOTOK
         CLR.W    FILENAME(A6)
         TST.W    FILECNT(A6)
         BEQ.S    UPL_NONE
         CMPI.B   #XR.NOMOR,D0
         BNE.S    UPL_INC
         TXSTR    {CR,LF,'Transfer completed',CR,LF}
         BRA.S    UPL_DESC
UPL_INC  TXSTR    {CR,LF,'Transfer incomplete',CR,LF}
         BRA.S    UPL_DESC
UPL_NONE TXSTR    {CR,LF,'No file(s) received',CR,LF}
         MOVE.L   (A7)+,D1
         MOVE.W   (A7)+,D7
FUPL_NC  MOVEQ    #-1,D0
         RTS
UP_GOTOK TST.B    FXBATCH(A6)
         BEQ.S    UPL_DESC
         ADDQ.W   #1,FILECNT(A6)
         CLR.L    BUFFER(A6)
         CLR.L    BUFFER+4(A6)
         BSR      PUTFILE
         BEQ      UPL_NEXT
         TXSTR    {CAN,CAN,CAN,CAN,CAN,CAN,CAN,CAN,BS,BS,BS,BS,BS,BS,BS,BS}
         MOVEQ    #50,D3
         JSR      PAUSE
         TXSTR    {CR,LF,BELL,'No room for more files!',CR,LF}
UPL_DESC QDOS     MT.RCLCK
         SUB.L    (A7)+,D1
         DIVU     #60,D1
         ADDQ.W   #1,D1
         ADD.W    D1,TIMELEFT(A6)
         SUB.W    D1,USERBUF+US_DAYTM(A6)
         MOVE.W   (A7)+,D7
         TST.B    ISPRIV(A6)
         BNE      CLEAR_Q
         TST.B    ALT_DIR(A6)
         BNE      CLEAR_Q
         TST.B    D7
         BNE      FUPL_OK
         MOVEQ    #0,D3
         JSR      OP_FDIR
         BNE      FUPL_OK
         JSR      DIRCLOSE
         TST.W    FILENAME(A6)
         BNE.S    UPL_DSC2
UPL_DLP  MOVE.L   FILE_Q(A6),A0
         MOVE.L   A0,D0
         BEQ      FUPL_OK
         LEA      12(A0),A1
         LEA      FILENAME(A6),A2
         MOVE.W   (A1)+,D0
         MOVE.W   D0,(A2)+
UPL_DLP2 MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D0
         BGT      UPL_DLP2
         BSR      REMVFILE
UPL_DSC2 TXSTR    {CR,LF,'Please describe '}
         LEA      FILENAME(A6),A1
         JSR      TXSTR
         TXSTR    {' (max. 79 characters):',CR,LF}
         SUBA.L   A0,A0
         LEA      XMODBUF+2(A6),A1
         MOVEQ    #80,D2
         JSR      INPUT
         MOVE.W   D1,XMODBUF(A6)
         MOVEQ    #0,D3
         JSR      OP_FDIR
         BNE      OP_ERROR
         MOVE.W   BUFSIZE(A6),D2
         MOVEQ    #-1,D3
         REPEAT
            MOVEQ    #0,D1
            QDOS     FS.POSRE
            MOVE.L   D1,D5
            LEA      BUFFER(A6),A1
            QDOS     IO.FLINE
            TST.L    D0
         UNTIL    NE
         CMPI.L   #ERR.EF,D0
         BNE      IO_ERROR
         MOVE.L   D5,D1
         QDOS     FS.POSAB
         LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #' ',D1
         QDOS     IO.SBYTE
         LEA      XMODBUF(A6),A1
         MOVE.W   (A1)+,D2
         MOVE.B   #LF,-1(A1,D2.W)
         QDOS     IO.SSTRG
         JSR      DIRCLOSE
         BRA      UPL_DLP
FUPL_OK  MOVEQ    #0,D0
FUPL_END RTS
FUPL_DEL MOVEQ    #-1,D1
         LEA      FNAMBUF(A6),A0
         QDOS     IO.DELET
         RTS
FUPL_EX  LEA      FILENAME(A6),A1
         JSR      TXSTR
         TXSTR    {' already exists',CR,LF}
         RTS
FUPL_ER  LEA      FILENAME(A6),A1
         JSR      TXSTR
         TXSTR    {' cannot be uploaded',CR,LF}
         RTS

SYSFNAM  MOVEQ    #48,D2
         LEA      FNAMBUF+2(A6),A1
         JSR      INPUT
         MOVE.B   #LF,-1(A1,D1.W)
         MOVE.W   D1,-(A1)
         JSR      LOG1
         MOVE.L   A1,A0
         SUBQ.W   #1,(A0)
         RTS

* Find number of free sectors in D1.L and total sectors in D2.L

         XDEF     GETMDINF

GETMDINF MOVEQ    #0,D1
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IOF.XINF
         TST.L    D0
         BNE.S    NO_VERS2
         MOVE.W   $1E(A1),D0
         DIVU     #512,D0
         MOVE.L   $24(A1),D1
         MOVE.L   $20(A1),D2
         MULU     D0,D1
         MULU     D0,D2
         MOVEQ    #20,D0
GMI_NULL TST.B    (A1)+
         DBEQ     D0,GMI_NULL
         BNE.S    GMI_OK
         SUBQ.L   #1,A1
GMI_OK   MOVEQ    #0,D0
         RTS
NO_VERS2 LEA      BUFFER(A6),A1
         QDOS     FS.MDINF
         MOVEQ    #0,D2
         MOVE.W   D1,D2
         CLR.W    D1
         SWAP     D1
         TST.L    D0
         RTS

* Read directory entry
* Entry: A0 channel ID; A1 buffer loc; A2 device & subdir name
* Exit : D1 length of subdir name; D2 length of device name

READDIR  MOVEM.L  D3-D4/A0-A1,-(A7)
         MOVE.L   A2,A1
         MOVE.W   (A1)+,D1
         SUBQ.W   #1,D1
RDIR_    CMPI.B   #'_',(A1)+
         DBEQ     D1,RDIR_
         MOVE.L   A1,D4
         SUB.L    A2,D4
         SUBQ.W   #2,D4
RDIR_LP  MOVEM.L  8(A7),A0-A1
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
         QDOS     IO.FSTRG
         TST.L    D0
         BNE.S    RDIR_END
         SUBA.W   D1,A1
         LEA      2(A2,D4.W),A0
         LEA      14(A1),A1
         TST.W    (A1)
         BEQ      RDIR_LP
         MOVE.W   (A2),D2
         SUB.W    D4,D2
         BLE.S    RDIR_END
         CMP.W    (A1)+,D2
         BGT      RDIR_LP
         SUBQ.W   #1,D2
RDIR_CP  MOVE.B   (A0)+,D1
         JSR      TOUPPER
         MOVE.B   D1,D0
         MOVE.B   (A1)+,D1
         JSR      TOUPPER
         CMP.B    D0,D1
         DBNE     D2,RDIR_CP
         BNE      RDIR_LP
         MOVEQ    #0,D0
RDIR_END MOVE.W   D4,D2
         MOVEM.L  (A7)+,D3-D4/A0-A1
         MOVE.W   (A2),D1
         SUB.W    D2,D1
         TST.L    D0
         RTS

RAWDIR   LOG      {'Raw dir: '}
         LOAD$    {CR,LF,'Dir from medium (ENTER = current): '},A0
         BSR      SYSFNAM
         IF LE THEN
            LEA      DIRBUF(A6),A0
            WRITEL$
         ENDIF
         MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE      SYSFERR
         MOVE.L   A0,DIRCHAN(A6)
         JSR      TXCRLF
         BSR      GETMDINF
         BNE      SYSFERR2
         MOVE.B   #' ',(A1)+
         MOVE.B   #' ',(A1)+
         MOVE.L   D2,-(A7)
         MOVEQ    #0,D3
         JSR      ITOD.L
         MOVE.B   #'/',(A1)+
         MOVE.L   (A7)+,D1
         JSR      ITOD.L
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #SP.SSTRG,D0
         JSR      DO_OUTP
         TXSTR    {' sectors',CR,LF,LF}
         MOVEQ    #2,D5
DIRNEXT  MOVE.L   DIRCHAN(A6),A0
         LEA      USERBUF2(A6),A1
         LEA      FNAMBUF(A6),A2
         BSR      READDIR
         BNE.S    DIR_END
         MOVEQ    #72,D0
         MOVE.L   #'    ',D1
         LEA      BUFFER(A6),A0
         MOVE.L   A0,A1
         REPEAT
            MOVE.L   D1,(A0)+
            SUBQ.W   #4,D0
         UNTIL    LE
         LEA      USERBUF2+14(A6),A0
         MOVE.W   (A0)+,D0
         REPEAT
            MOVE.B   (A0)+,(A1)+
            SUBQ.W   #1,D0
         UNTIL    LE
         CMPI.B   #$FF,USERBUF2+5(A6)
         IF NE THEN
            MOVE.L   USERBUF2(A6),D1
            MOVEQ    #0,D3
            LEA      BUFFER+38(A6),A1
            JSR      ITOD.L
            MOVE.L   USERBUF2+$34(A6),D1
            LEA      BUFFER+48(A6),A1
            JSR      DATE$
         ELSE
            MOVE.B   #' ',(A1)+
            MOVE.B   #'-',(A1)+
            MOVE.B   #'>',(A1)+
         ENDIF
         MOVE.L   A1,D1
         LEA      BUFFER(A6),A1
         SUB.L    A1,D1
         REPEAT
            JSR      TXLINE
         UNTIL    LE
         BEQ      DIRNEXT
DIR_END  MOVEQ    #0,D0
SYSFERR2 MOVE.L   D0,D4
         JSR      DIRCLOSE
         MOVE.L   D4,D0
SYSFERR  MOVE.L   COM_OUT(A6),A0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         MOVEQ    #CR,D1
         JMP      TXCHAR

FKILL    LOG      {'Kill file: '}
         LOAD$    {CR,LF,'Kill file: '},A0
         BSR      SYSFNAM
         BLE.S    FK_END
DEL_FILE LEA      FNAMBUF(A6),A0
         MOVEQ    #-1,D1
         QDOS     IO.DELET
         TST.L    D0
         BNE      SYSFERR
         TXSTR    {CR,LF,'File '}
         LEA      FNAMBUF(A6),A1
         JSR      TXSTR
         TXSTR    {' deleted',CR,LF}
FK_END   RTS

NEWDIR   LOG      {'Changing directory: '}
         LOAD$    {CR,LF,'New directory to use: '},A0
         BSR      SYSFNAM
         BLE.S    ND_END
         MOVE.W   (A0),D0
         CMPI.B   #'_',1(A0,D0.W)
         IF NE THEN
            MOVE.B   #'_',2(A0,D0.W)
            ADDQ.W   #1,(A0)
         ENDIF
         LEA      DIRBUF(A6),A1
         WRITEL$
         ST       ALT_DIR(A6)
ND_END   RTS

         END
