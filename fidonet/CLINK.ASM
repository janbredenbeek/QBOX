* QBOXMail Mailer; SEAlink receive/send

sys_inc  SETSTR   FLP2_
qnet_inc SETSTR   FLP2_
version  SETSTR   1.19j

         INCLUDE  [sys_inc]QDOS_IN_MAC

LOG      MACRO    A
[.LAB]   LOAD$    {[A]},A1
         JSR      LOG
         ENDM

SOH      EQU      1
ETX      EQU      3
EOT      EQU      4
ENQ      EQU      5
ACK      EQU      6
LF       EQU      $0A
XON      EQU      $11
XOFF     EQU      $13
NAK      EQU      $15
SYN      EQU      $16
ETB      EQU      $17
CAN      EQU      $18
SUB      EQU      $1A
C        EQU      $43
TSYNC    EQU      $AE

SP.INIT  EQU      0
SP.WTCAL EQU      1
SP.DSCON EQU      2
SP.CLOSE EQU      3
SP.FBAUD EQU      4
SP.DIAL  EQU      5
SP.PEND  EQU      8
SP.FBYTE EQU      9
SP.SBYTE EQU      10
SP.SSTRG EQU      11
SP.FLUSH EQU      12
SP.DUMP  EQU      13
SP.PARIT EQU      14

* Bit flags for RX_CLINK and TX_CLINK (D7)

CRCMODE  EQU      0                 1 if CRC mode
TELINK   EQU      8                 1 if Telink mode
SEALINK  EQU      9                 1 if SEAlink mode
SLO      EQU      10                1 if Overdrive mode
RESYNC   EQU      11                1 if RESYNC mode
B_ALLOC  EQU      12                1 = allocate own buffer (RCFILE)
NOCLOSE  EQU      13                1 = don't close output file (RCFILE)
WANT_C   EQU      14                1 = want SEAlink mode

XR..SKIP EQU      15                1 = got first character
S_XOFF   EQU      16                1 = waiting for other end to stop
CANSLO   EQU      17                1 = can do receive SLO

XR.OK    EQU      0
XR.NOMOR EQU      1
XR.CAN   EQU      2
XR.FAIL  EQU      3
XR.SYNC  EQU      4
XR.IOERR EQU      5
XR.NRERR EQU      6
XR.NSERR EQU      7

         XREF     ITOD_W,ITOD_L,GETDATE,SETTIMER,SET1MIN,GETCHR1,GETCHR2
         XREF     LOG,LOG0,TXCHAR,PROGRESS,TEST_CAN,PURGE,WRITEERR,PURGE_LP
         XREF     PAUSE,TXSTR,DO_OUTP,DUMP_OPB,READNUM,DO_INP
         XREF.S   BUFFER,INPCHAN,FNAMBUF,LOGBUF,FILENAME,LOGCHAN
         XREF.S   XMODBUF,BPS

         SECTION  CODE

* Convert MS-DOS date & time to QDOS date & time
* Entry: D1 MS-DOS date (low word) & time (high word)
* Exit: D1 QDOS date & time

CVT_DATE MOVE.L   D1,D3             Copy DOS date & time
         ROL.W    #7,D1
         MOVEQ    #$7F,D0
         AND.B    D1,D0             D0 = year - 1980
         ADDI.W   #1980-1961,D0     Convert to year - 1961
         MOVE.W   D0,D1
         MULU     #365,D1
         MOVEQ    #3,D2
         AND.B    D0,D2             D2 = year MOD 4
         LSR.W    #2,D0
         ADD.L    D0,D1             Add in leap days
         MOVE.W   D3,D0
         LSR.W    #5,D0
         ANDI.W   #$0F,D0           D0 = month
         SUBQ.W   #3,D2             Leap year?
         BNE.S    RD_NOADD          No, skip
         CMPI.W   #2,D0             After February?
         BLS.S    RD_NOADD          No
         ADDQ.L   #1,D1             Add in extra day
RD_NOADD MOVE.W   D0,D2
         MULU     #275,D2
         DIVU     #9,D2             D2 = month * 275/9
         SUBQ.W   #2,D0
         BLS.S    RD_NOAD2
         SUBQ.W   #2,D2
RD_NOAD2 MOVEQ    #$1F,D0
         AND.B    D3,D0             D0 = day-of-month
         ADD.W    D2,D0
         SUBI.W   #31,D0            D0 = day-of-year
         ADD.L    D0,D1             Add to total
         MOVEQ    #24,D0
         BSR.S    MUL32             Convert to hours
         SWAP     D3
         MOVE.W   D3,D0
         ROL.W    #5,D0
         ANDI.W   #$1F,D0
         ADD.L    D0,D1             Add hours
         MOVEQ    #60,D0
         BSR.S    MUL32             Convert to minutes
         MOVE.W   D3,D0
         LSR.W    #5,D0
         ANDI.W   #$3F,D0
         ADD.L    D0,D1             Add minutes
         MOVEQ    #60,D0
         BSR.S    MUL32             Convert to seconds
         MOVEQ    #$1F,D0
         AND.B    D3,D0             Get seconds/2
         ADD.B    D0,D0
         ADD.L    D0,D1             Add seconds
         RTS

* Routine to multiply D1.L by D0.W

MUL32    MOVE.L   D1,D2
         SWAP     D2                D2.W holds high word from D1
         MULU     D0,D1             Multiply low word
         MULU     D0,D2             Multiply high word
         SWAP     D1
         ADD.W    D2,D1             Form correct high word of result
         SWAP     D1
         RTS

* Log file statistics
* Entry: D1 file length; A1 ptr to buffer after "Receiving:" or "Sending:"
*        A0: Pointer to file name (QDOS string)

LOGFSTAT WRITE$
         TST.L    D1
         BMI.S    LF_LOG
         MOVE.B   #',',(A1)+
         MOVE.B   #' ',(A1)+
         MOVEQ    #0,D2
         BSR      ITOD_L
         WRITE$   {'b, '},A1
         MOVEQ    #0,D0
         MOVE.W   BPS(A6),D0
         DIVU     #10,D0
         DIVU     D0,D1
         ANDI.L   #$FFFF,D1
         DIVU     #60,D1
         MOVEQ    #0,D2
         BSR      ITOD_W
         MOVE.B   #':',(A1)+
         SWAP     D1
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         BSR      ITOD_W
LF_LOG   CLR.B    (A1)
         JMP      LOG0

* Log file transfer result
* Entry: D1 start time (secs), D5 bytes transferred

LOG_THRU MOVEM.L  D1-D5/A0-A1,-(A7)
         LEA      LOGBUF(A6),A1
         WRITE$   {'CPS: '}
         QDOS     MT.RCLCK
         MOVE.L   D1,D4
         SUB.L    (A7),D4
         BNE.S    LG_NO0
         MOVEQ    #1,D4
LG_NO0   MOVE.L   D5,D1
         DIVU     D4,D1
         MOVEQ    #0,D2
         BSR      ITOD_W
         MOVE.B   #' ',(A1)+
         MOVE.B   #'(',(A1)+
         MOVE.L   D5,D1
         BSR      ITOD_L
         WRITE$   {'b, '}
         MOVE.L   D4,D1
         DIVU     #60,D1
         MOVEQ    #0,D2
         BSR      ITOD_W
         MOVE.B   #':',(A1)+
         SWAP     D1
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         BSR      ITOD_W
         MOVE.B   #')',(A1)+
         CLR.B    (A1)
         JSR      LOG0
         MOVEM.L  (A7)+,D1-D5/A0-A1
         RTS

* Clear current line in log window

CLEARLN  MOVEM.L  D1/D3/A0-A1,-(A7)
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     SD.CLRLN
         MOVEM.L  (A7)+,D1/D3/A0-A1
         TST.L    D0
         RTS

TIMEOUT  MOVEM.L  D1-D3/A0,-(A7)
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         LOAD$    {'Timeout, retry '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         BRA.S    ERRCNT

BLOCKERR MOVEM.L  D1-D3/A0,-(A7)
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         LOAD$    {'Block error ('},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVE.L   D6,D1
         SWAP     D1
         BSR.S    PR_NUMW
         LOAD$    {'), retry '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
ERRCNT   MOVE.W   D6,D1
         ADDQ.W   #1,D1
         BSR.S    PR_NUMW
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVEM.L  (A7)+,D1-D3/A0
PRN_END  RTS

SHOWPOS  MOVEM.L  D1-D3/A0-A1,-(A7)
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         LOAD$    {'Byte: '},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVE.L   D5,D1
         SUBQ.L   #1,D1
         LSL.L    #7,D1
         MOVEQ    #0,D3
         MOVE.L   LOGCHAN(A6),A0
         BSR.S    PR_NUML
         MOVEQ    #0,D1
         QDOS     SD.TAB
         MOVEM.L  (A7)+,D1-D3/A0-A1
         RTS

PR_NUMW  ANDI.L   #$FFFF,D1
PR_NUML  SUBA.W   #10,A7
         MOVE.L   A7,A1
         MOVEQ    #0,D2
         JSR      ITOD_L
         MOVE.L   A1,D2
         MOVE.L   A7,A1
         SUB.L    A1,D2
         QDOS     IO.SSTRG
         ADDA.W   #10,A7
PR_END   RTS

* Receive a file using XMODEM, Telink or SEAlink
* Entry: A1 ptr to receive path
* Exit : D0 error code

* Local variables for RX_TELNK

XR_BUFSZ EQU      -4                File buffer size
XR_STPOS EQU      -8                Starting position when RESYNCing
XR_TIME  EQU      -12               Start time of transfer
XR_FLEN  EQU      -16               File length (or -1 if unknown)
XR_NAKCT EQU      -18               NAK counter
XR_STACK EQU      -18               Stack size needed
XR_SOH   EQU      4                 First character received (parameter)
XR_PATH  EQU      36                Pointer to receive path (parameter)

         XDEF     RX_CLINK

RX_CLINK MOVEM.L  D1-D7/A0-A3,-(A7)
         LINK     A5,#XR_STACK
         ANDI.L   #$FFFF,D7
         BSET     #CANSLO,D7
         CLR.L    INPCHAN(A6)
         MOVEQ    #-1,D0
         MOVE.L   D0,XR_FLEN(A5)    Initial file length - unknown
         QDOS     MT.RCLCK
         MOVE.L   D1,XR_TIME(A5)    Start time
         CLR.L    XR_STPOS(A5)      Start position in file
         CLR.L    XR_BUFSZ(A5)      Buffer size
         SUBA.L   A0,A0             Buffer address
         MOVE.L   XR_PATH(A5),A1
         MOVE.L   2(A1),D0
         ANDI.L   #$DFDFDFF0,D0
         CMPI.L   #'RAM0',D0
         BEQ.S    XR_INIT
         BCLR     #CANSLO,D7
         MOVE.L   #32*1024-128,D1
         CMPI.L   #'WIN0',D0
         BEQ.S    XR_ALBF
         CMPI.L   #'MDV0',D0
         BEQ.S    XR_ALBF
         MOVE.L   #8*1024,D1
XR_ALBF  MOVE.L   D1,XR_BUFSZ(A5)
         LEA      BUFFER(A6),A0
         BTST     #B_ALLOC,D7
         BEQ.S    XR_INIT
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         BEQ.S    XR_INIT
         LOG      {'? RECV: Unable to allocate buffer',LF}
         SUBA.L   A3,A3
         BRA      XR_SCAN
XR_INIT  MOVE.L   A0,A3             Buffer address
         MOVEQ    #0,D4             Buffer position
         MOVEQ    #1,D5             WriteBLK
         MOVEQ    #0,D6             Retry count (L) & blocknum (H)
         CLR.B    XR_NAKCT(A5)
         LOAD$    {'Waiting for first block',LF}
         BSR      PROGRESS
         JSR      SET1MIN
         MOVE.L   XR_SOH(A5),D1
         BCLR     #XR..SKIP,D7
         BNE.S    XR_SKIP
XR_START BSR      SENDNAK
         BNE      XR_RCDO
XR_WFRST MOVE.W   #5*50,D3
         JSR      GETCHR2
         BLT      XR_RCDO
         BGT.S    XR_TIMO1
         JSR      TEST_CAN
         BEQ      XR_CAN
         CMPI.B   #EOT,D1
         BEQ      XR_NOMOR
XR_SKIP  CMPI.B   #SOH,D1
         BNE.S    XR_CKSYN
         MOVEQ    #0,D1
         BSR      XR_RBLOK
         BNE.S    XR_FFAIL
         TST.B    XMODBUF(A6)
         BNE      XR_OPEN
         LOAD$    {'SEAlink block received',LF}
         BSR      PROGRESS
         BSET     #SEALINK,D7
         BRA.S    XR_AFRST
XR_CKSYN CMPI.B   #SYN,D1
         BNE.S    XR_CRC
         MOVE.W   D7,-(A7)
         CLR.B    D7
         MOVEQ    #0,D1
         BSR      XR_RBLOK
         MOVE.W   (A7)+,D7
         TST.L    D0
         BNE.S    XR_FFAIL
         TST.B    XMODBUF(A6)
         BNE.S    XR_FFAIL
         LOAD$    {'Telink block received',LF}
         BSR      PROGRESS
         BSET     #TELINK,D7
         BRA.S    XR_AFRST
XR_FFAIL TST.B    D0
         BGT.S    XR_TIMO1
XR_CRC   BSR      BLOCKERR
         JSR      PURGE
         BRA.S    XR_FNEXT
XR_TIMO1 BSR      TIMEOUT
XR_FNEXT ADDQ.W   #1,D6
         CMPI.W   #10,D6
         BGT      XR_FAIL
         CMPI.W   #3,D6
         BLE      XR_START
         TST.B    D7
         BEQ      XR_START
         LOAD$    {'Switched to checksum mode',LF},A1
         BSR      PROGRESS
         CLR.B    D7
         BRA      XR_START
XR_AFRST LEA      XMODBUF+10(A6),A1
         LEA      FILENAME+2(A6),A0
XR_CNAME MOVE.B   (A1)+,D0          Copy filename to buffer
         BEQ.S    XR_CNEND
         CMPI.B   #' ',D0
         BEQ.S    XR_CNEND
         MOVE.B   D0,(A0)+
         BRA      XR_CNAME
XR_CNEND MOVE.L   A0,D0
         LEA      FILENAME+2(A6),A0
         SUB.L    A0,D0
         MOVE.W   D0,-(A0)          Get length of raw file name
         LEA      XMODBUF+2(A6),A1
         MOVE.L   (A1)+,D1
         ROL.W    #8,D1
         SWAP     D1
         ROL.W    #8,D1
         MOVE.L   D1,XR_FLEN(A5)    File length
         MOVE.W   (A1)+,D1          MS-DOS time or LSW
         ROL.W    #8,D1
         SWAP     D1
         MOVE.W   (A1)+,D1          MS-DOS date or MSW
         ROL.W    #8,D1
         BTST     #TELINK,D7
         BEQ.S    XR_CLDAT
         BSR      CVT_DATE          Telink (MS-DOS) date
         BRA.S    XR_STDAT
XR_CLDAT SWAP     D1
         ADDI.L   #3287*24*60*60,D1 SEAlink (base-1980) date
XR_STDAT MOVE.L   D1,-(A1)          Restore date in QDOS format
XR_OPEN  LOAD$    {'+ Receiving (SEAlink): '},A0
         BTST     #SEALINK,D7
         BNE.S    XR_OWRT
         LOAD$    {'+ Receiving (Telink): '},A0
         BTST     #TELINK,D7
         BNE.S    XR_OWRT
         LOAD$    {'+ Receiving (XMODEM): '},A0
XR_OWRT  LEA      LOGBUF(A6),A1
         WRITE$
         MOVE.L   XR_FLEN(A5),D1
         LEA      FILENAME(A6),A0
         BSR      LOGFSTAT
XR_OAGN  LEA      FILENAME(A6),A0
         MOVE.L   XR_PATH(A5),A1
         LEA      FNAMBUF+2(A6),A2
         MOVE.W   (A1)+,D1
         MOVE.W   D1,D0
XR_CPATH MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D0
         BGT      XR_CPATH
         MOVE.W   (A0)+,D0
         ADD.W    D0,D1
         MOVE.W   D1,FNAMBUF(A6)
         SUBI.W   #48,D1
         BLE.S    XR_CNAM2
         MOVE.W   #48,FNAMBUF(A6)
         SUB.W    D1,D0
XR_CNAM2 MOVE.B   (A0)+,(A2)+
         SUBQ.W   #1,D0
         BGT      XR_CNAM2
         MOVEQ    #-1,D1
         MOVEQ    #IO.NEW,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ      XR_SDATE
         CMPI.L   #ERR.EX,D0
         BEQ.S    XR_EXIST
XR_OFAIL LEA      LOGBUF(A6),A1
         WRITE$   {'? Unable to open '},A1
         LEA      FNAMBUF(A6),A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
         MOVEQ    #XR.IOERR,D4
         BRA      XR_SCAN
XR_EXIST MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    XR_DUPFN
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         MOVE.L   BUFFER+10(A6),D1
         BNE.S    XR_CDATE
         MOVE.L   BUFFER+$34(A6),D1
XR_CDATE CMP.L    XMODBUF+6(A6),D1
         BNE.S    XR_CLOLD
         BTST     #SEALINK,D7
         BEQ      XR_SDATE
         TST.B    XMODBUF+43(A6)    RESYNC flag
         BEQ      XR_SDATE
         BSET     #RESYNC,D7
         MOVE.L   BUFFER(A6),D1
         LSR.L    #7,D1
         MOVE.L   D1,D5
         ADDQ.L   #1,D5             D5 = RESYNC blk #
         LSL.L    #7,D1
         MOVE.L   D1,XR_STPOS(A5)
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVEQ    #0,D6
         MOVE.B   D5,D6
         SWAP     D6
         LEA      LOGBUF(A6),A1
         WRITE$   {'+ Resuming from position '}
         MOVEQ    #0,D2
         JSR      ITOD_L
         CLR.B    (A1)+
         JSR      LOG0
         BRA      XR_SDATE
XR_CLOLD QDOS     IO.CLOSE
XR_DUPFN LEA      FILENAME(A6),A0
         CMPI.W   #12,(A0)
         BNE.S    XR_NOPKT
         MOVE.L   10(A0),D0
         ANDI.L   #$FFDFDFDF,D0
         CMPI.L   #'.PKT',D0
         BNE.S    XR_NOPKT
         ADDQ.B   #1,9(A0)
         BRA.S    XR_RND
XR_NOPKT ADDA.W   (A0)+,A0
XR_TSDGT CMPI.B   #'0',-(A0)
         BLO.S    XR_NODGT
         CMPI.B   #'9',(A0)
         BHI.S    XR_NODGT
         ADDQ.B   #1,(A0)
         CMPI.B   #'9',(A0)
         BLS.S    XR_RND
         MOVE.B   #'0',(A0)
         BRA      XR_TSDGT
XR_NODGT LEA      FILENAME(A6),A0
         ADDQ.W   #1,(A0)
         ADDA.W   (A0)+,A0
         MOVE.B   #'0',-(A0)
XR_RND   LEA      LOGBUF(A6),A1
         WRITE$   {'+ Duplicate file - renamed to '},A1
         LEA      FILENAME(A6),A0
         WRITE$
         CLR.B    (A1)
         JSR      LOG0
         BRA      XR_OAGN
XR_SDATE MOVE.L   A0,INPCHAN(A6)
         MOVEQ    #-1,D3
         CLR.W    D6
         TST.B    XMODBUF(A6)
         BEQ.S    XR_SDAT2
         QDOS     IO.SBYTE
         MOVEQ    #0,D1
         QDOS     FS.POSAB
         QDOS     FS.TRUNC
         BSR      SB_FLUSH
         BRA      XR_XFRST
XR_SDAT2 MOVE.L   XMODBUF+6(A6),D1
         MOVEQ    #0,D2
         MOVE.L   INPCHAN(A6),A0
         QDOS     IOF.DATE
         TST.L    D0
         BEQ.S    XR_CKFRE
         LEA      BUFFER(A6),A1     If IOF.DATE doesn't work, use header
         CLR.L    (A1)              offset 10 to store actual file date
         CLR.L    4(A1)
         CLR.W    8(A1)
         MOVE.L   XMODBUF+6(A6),10(A1)
         QDOS     FS.HEADS
XR_CKFRE BSR      GET_FREE
         MOVE.L   XR_FLEN(A5),D0
         SUB.L    XR_STPOS(A5),D0
         CMP.L    D0,D1
         BHI.S    XR_AKNAK
         LOG      {'? X-RECV: Not enough disk space',LF}
         MOVEQ    #XR.IOERR,D4
         BRA      XR_SCAN
XR_AKNAK QDOS     IO.SBYTE
         MOVEQ    #-1,D1
         QDOS     FS.POSRE
         QDOS     FS.TRUNC
         BSR      SB_FLUSH
         BTST     #RESYNC,D7
         BNE.S    XR_RSN2
         BSR      SENDACK
         BNE      XR_RCDO
         BRA.S    XR_STSLO
XR_RSN2  BSR      SENDNAK           Send RESYNC packet
         BNE      XR_RCDO
XR_STSLO TST.B    XMODBUF+42(A6)
         BEQ.S    XR_SPOS
         BTST     #CANSLO,D7
         BEQ.S    XR_SPOS
         LOAD$    {'Using SEAlink Overdrive',LF},A1
         JSR      PROGRESS
         BSET     #SLO,D7
         BRA.S    XR_SPOS

* Main loop

XR_ACK   BSR      SENDACK
         BNE      XR_RCDO
         CLR.W    D6
XR_SPOS  BSR      SHOWPOS
         BSR      SET1MIN
XR_WTBLK MOVE.W   #5*50,D3
         BTST     #S_XOFF,D7
         BEQ.S    XR_WTBL2
         MOVEQ    #50,D3
XR_WTBL2 BSR      GETCHR1
         BLT      XR_RCDO
         BGT.S    XR_TIMO2
XR_NOEOT BSR      TEST_CAN
         BEQ      XR_CAN
         CMPI.B   #EOT,D1
         BEQ      XR_EOT
XR_CKSOH CMPI.B   #SOH,D1
         BEQ.S    XR_ISSOH
XR_JUNK  MOVEQ    #5,D3
         BSR      GETCHR1           Keep looking for SOH
         BLT      XR_RCDO
         BGT      XR_WTBLK
         BRA      XR_CKSOH
XR_ISSOH MOVEQ    #0,D1
XR_GTBLK BSR      XR_RBLOK          Get data block
         BEQ      XR_CKBLK          Jump if OK
         BGT.S    XR_TIMO2          NAK if timeout
         BTST     #SEALINK,D7
         BEQ.S    XR_BFAIL          Also NAK a bad block if not in sealink
         MOVE.B   XMODBUF(A6),D1
         NOT.B    D1
         CMP.B    XMODBUF+1(A6),D1
         BNE.S    XR_SLIDE
         TST.B    XR_NAKCT(A5)
         BEQ.S    XR_BFAIL
XR_SLIDE MOVE.W   #128,D0           Buffer contains junk before real SOH;
         ADD.B    D7,D0             so start looking for it
         LEA      XMODBUF(A6),A1
XR_LKSOH CMPI.B   #SOH,(A1)+
         BNE.S    XR_LKSH2
         MOVE.B   (A1),D1
         NOT.B    D1
         CMP.B    1(A1),D1
XR_LKSH2 DBEQ     D0,XR_LKSOH
         BNE.S    XR_JUNK           Find SOH - blk - !blk sequence
         ADDQ.W   #1,D0             # of chars to move down - 1
         MOVE.W   D0,D1
         ADDQ.W   #1,D1             Position to start receive next blk
         LEA      XMODBUF(A6),A0
XR_MVBUF MOVE.B   (A1)+,(A0)+       Get start of block in place
         DBF      D0,XR_MVBUF
         BRA      XR_GTBLK          Jump to get remainder
XR_BFAIL BSR      BLOCKERR
         BRA.S    XR_BNEXT
XR_TIMO2 BTST     #S_XOFF,D7
         BNE      XR_WRBUF
         BSR      TIMEOUT
         BTST     #0,D6
         BEQ.S    XR_BNEXT
         MOVEQ    #XON,D1
         JSR      TXCHAR            In case Xmitter is stuck in MacFlow
XR_BNEXT ADDQ.W   #1,D6
         CMPI.W   #10,D6
         BGE      XR_FAIL
         BSR      SENDNAK
         BRA      XR_WTBLK

* Data block received OK, check if it is the one we want

XR_XFRST ADDI.L   #$10000,D6
XR_CKBLK LEA      XMODBUF(A6),A1
         MOVE.B   (A1),D1
         SUB.B    D5,D1
         BEQ.S    XR_COPY
         BMI.S    XR_PREV
         BTST     #SEALINK,D7
         BNE.S    XR_SYNC
         LOG      {'? X-RECV: Sync error',LF}
         MOVEQ    #XR.SYNC,D4
         BRA      XR_SCAN
XR_SYNC  TST.B    XR_NAKCT(A5)
         BNE      XR_SLIDE
         BSR      SENDNAK
         BRA      XR_WTBLK
XR_PREV  SUBI.L   #$10000,D6
         BRA      XR_ACK
XR_COPY  ADDQ.L   #1,D5
         ADDQ.W   #2,A1
         MOVE.L   A3,D0
         BNE.S    XR_BUF
         MOVE.W   #128,D2
         MOVE.L   D5,D0
         SUBQ.L   #1,D0
         LSL.L    #7,D0
         SUB.L    XR_FLEN(A5),D0
         BLS.S    XR_WBLK
         SUB.W    D0,D2
XR_WBLK  MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      XR_IOERR
         BRA      XR_ACK
XR_BUF   LEA      (A3,D4.L),A2
         MOVEQ    #128/4-1,D0
XR_CPBLK MOVE.L   (A1)+,(A2)+
         DBF      D0,XR_CPBLK
         ADDI.L   #128,D4
         MOVE.L   XR_BUFSZ(A5),D2
         SUB.L    D4,D2
         BTST     #SEALINK,D7
         BNE.S    XR_TSTBF
         TST.L    D2
         BGT      XR_ACK
         BRA.S    XR_WRBUF
XR_TSTBF CMPI.L   #5*128,D2
         BHI      XR_ACK
         MOVE.L   D5,D0
         SUBQ.L   #1,D0
         LSL.L    #7,D0
         SUB.L    XR_FLEN(A5),D0
         NEG.L    D0
         CMP.L    D0,D2
         BGE      XR_ACK
         TST.L    D2
         BLE.S    XR_FLUSH
         BSET     #S_XOFF,D7
         BRA      XR_ACK
XR_FLUSH BSR      SET1MIN
         MOVEQ    #50,D3
XR_WTCLR BSR      GETCHR1
         BEQ      XR_WTCLR
XR_WRBUF BSR      SAVBUFF
         BNE      XR_IOERR
         MOVEQ    #0,D4
         BTST     #SEALINK,D7
         BEQ      XR_ACK
         BCLR     #S_XOFF,D7
         BEQ      XR_ACK
         MOVEQ    #XON,D1
         JSR      TXCHAR
         BRA      XR_ACK

* Handle EOT; NAK it if premature

XR_EOT   MOVE.L   D5,D0
         SUBQ.L   #1,D0
         LSL.L    #7,D0
         CMP.L    XR_FLEN(A5),D0
         BHS.S    XR_OK
         BSR      SET1MIN
         BTST     #SEALINK,D7
         BEQ.S    XR_EOT2
         MOVEQ    #50,D3
         BSR      GETCHR1
         BLT      XR_RCDO
         BEQ      XR_CKSOH          Junk after EOT; probably not a real EOT
XR_EOT2  BSR      SENDNAK
         BNE      XR_RCDO
         MOVE.W   #5*50,D3
         BSR      GETCHR1
         BLT      XR_RCDO
         BGT      XR_EOT2
         CMPI.B   #EOT,D1
         BNE      XR_NOEOT
XR_OK    BSR      SAVBUFF
         BNE.S    XR_IOERR
         MOVE.L   XR_TIME(A5),D1
         SUBQ.L   #1,D5
         LSL.L    #7,D5
         TST.L    XR_FLEN(A5)
         BLT.S    XR_REPT
         MOVE.L   XR_FLEN(A5),D5
         SUB.L    XR_STPOS(A5),D5
XR_REPT  BSR      LOG_THRU
         MOVEQ    #XR.OK,D4
         BCLR     #SLO,D7
         BRA.S    XR_FACK
XR_NOMOR LOG      {'? X-RECV: No file received',LF}
         MOVEQ    #XR.NOMOR,D4
XR_FACK  BSR      SENDACK
         BNE.S    XR_RCDO
         BRA.S    XR_FINAL
XR_CAN   LOG      {'? X-RECV: Aborted by remote',LF}
         BSR      SAVBUFF
         MOVEQ    #XR.CAN,D4
         BRA.S    XR_SCAN
XR_FAIL  LOG      {'? X-RECV: Retry limit exceeded',LF}
         BSR      SAVBUFF
         MOVEQ    #XR.FAIL,D4
         BRA.S    XR_SCAN
XR_IOERR LEA      LOGBUF(A6),A1
         WRITE$   {'? X-RECV: File I/O error ('},A1
         BSR      WRITEERR
         MOVE.B   #')',-1(A1)
         CLR.B    (A1)
         JSR      LOG0
         MOVEQ    #XR.IOERR,D4
         BRA.S    XR_SCAN
XR_RCDO  MOVE.L   D0,-(A7)
         BSR      SAVBUFF
         MOVE.L   (A7)+,D4
         CMPI.L   #ERR.EF,D4
         BNE.S    XR_TIMO
         LOG      {'? X-RECV: Carrier lost',LF}
         BRA.S    XR_RTS
XR_TIMO  LOG      {'? X-RECV: Fatal timeout',LF}
XR_SCAN  MOVEQ    #CAN,D1
         JSR      TXCHAR
         JSR      TXCHAR
XR_FINAL MOVEQ    #0,D3
         JSR      PURGE_LP
XR_RTS   BTST     #NOCLOSE,D7
         BNE.S    XR_RTS2
         TST.L    INPCHAN(A6)
         BEQ.S    XR_RTS2
         MOVE.L   INPCHAN(A6),A0
         QDOS     IO.CLOSE
         CLR.L    INPCHAN(A6)
XR_RTS2  MOVE.L   A3,D0
         BEQ.S    XR_RTS3
         BTST     #B_ALLOC,D7
         BEQ.S    XR_RTS3
         MOVE.L   A3,A0
         QDOS     MT.RECHP
XR_RTS3  UNLK     A5
         MOVE.L   D4,D0
         MOVEM.L  (A7)+,D1-D7/A0-A3
         TST.L    D0
         RTS

* Receive XMODEM/Telink/SEAlink header or data block
* Entry: D1 offset into XMODBUF
*  Exit: D0 0=OK, +1 timeout, -1 bad block

XR_RBLOK MOVE.W   #130,D2
         ADD.B    D7,D2
         SUB.W    D1,D2
         MOVE.W   #5*50,D3
         LEA      XMODBUF(A6),A2
         ADDA.W   D1,A2
XR_RB_LP MOVEQ    #SP.FBYTE,D0
         JSR      DO_INP
         BNE.S    XR_RB_TM
         MOVE.B   D1,(A2)+
         DBF      D2,XR_RB_LP
         MOVE.B   XMODBUF(A6),D1    Block # must match complement,
         NOT.B    D1                otherwise it's a bad block
         CMP.B    XMODBUF+1(A6),D1
         BNE.S    XR_RB_CK
         BSR      CALCHK            Calculate checksum or CRC
         CMP.W    (A1),D3           Checksum is shifted left by 8
         BNE.S    XR_RB_CK          Checksum/CRC error
         MOVEQ    #0,D0
         RTS
XR_RB_TM MOVEQ    #1,D0
         RTS
XR_RB_CK MOVEQ    #-1,D0
         RTS

SAVBUFF  MOVE.L   INPCHAN(A6),A0
         MOVEQ    #-1,D3
         MOVEQ    #0,D0
         MOVE.W   D4,D2
         BEQ.S    SB_END
         MOVE.L   D5,D0
         SUBQ.L   #1,D0
         LSL.L    #7,D0
         SUB.L    XR_FLEN(A5),D0
         BLS.S    SB_SAVE
         SUB.W    D0,D2
SB_SAVE  MOVE.L   A3,A1
         QDOS     IO.SSTRG
SB_FLUSH MOVE.L   D0,-(A7)
         QDOS     FS.FLUSH
         MOVE.L   FNAMBUF+2(A6),D0
         ANDI.L   #$DFDFDFF0,D0
         CMPI.L   #'FLP0',D0
         BNE.S    SB_END1
         MOVEQ    #60,D3
         JSR      PAUSE
SB_END1  MOVE.L   (A7)+,D0
SB_END   RTS

* Send NAK or RESYNC packet

SENDNAK  BTST     #S_XOFF,D7
         BEQ.S    SN_NAK
         MOVEQ    #XOFF,D1
         JSR      TXCHAR
         MOVEQ    #0,D0
         RTS
SN_NAK   QDOS     MT.RCLCK
         MOVEQ    #30,D2
         ADD.L    D1,D2
         MOVE.L   D2,-(A7)
         BCLR     #RESYNC,D7
         BNE.S    SN_RESYN
         BTST     #SEALINK,D7
         BNE.S    SN1
SN0      QDOS     MT.RCLCK
         CMP.L    (A7),D1
         BHI      SN_FAIL
         MOVEQ    #0,D3
         BSR      GETCHR1
         BEQ      SN0
         BLT      SN_FAIL
SN1      MOVEQ    #NAK,D1
         TST.B    D7
         BEQ.S    SN2
         CMPI.W   #3,D6
         BGT.S    SN2
         MOVEQ    #C,D1
SN2      JSR      TXCHAR
         BTST     #SEALINK,D7
         BEQ.S    SN_OK
         MOVE.L   D6,D1
         SWAP     D1
         JSR      TXCHAR
         NOT.B    D1
         JSR      TXCHAR
         SUBQ.B   #1,XR_NAKCT(A5)
         BGE.S    SN_OK
         MOVE.B   #32,XR_NAKCT(A5)
         BRA.S    SN_OK
SN_RESYN LEA      XMODBUF+2(A6),A1
         MOVE.B   #SYN,(A1)+
         MOVE.L   A1,A0
         MOVE.L   D5,D1
         MOVEQ    #0,D2
         JSR      ITOD_L
         MOVE.L   A1,D0
         MOVE.L   A0,A1
         SUB.L    A1,D0
         SUBQ.W   #1,D0
         BSR      CALCCRC
         MOVE.B   #ETX,(A1)+
         MOVE.B   D3,(A1)+
         LSR.W    #8,D3
         MOVE.B   D3,(A1)+
         MOVE.L   A1,D0
         LEA      XMODBUF+2(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
SN3      LEA      XMODBUF(A6),A1
         JSR      TXSTR
SN3A     QDOS     MT.RCLCK
         CMP.L    (A7),D1
         BHI.S    SN_FAIL
         MOVE.W   #10*50,D3
         BSR      GETCHR1
         BGT      SN3
         BLT.S    SN_FAIL
         CMPI.B   #NAK,D1
         BEQ      SN3
         CMPI.B   #ACK,D1
         BNE      SN3A
SN_OK    MOVEQ    #0,D0
         BRA.S    SN_RTS
SN_FAIL  MOVEQ    #-1,D0
SN_RTS   ADDQ.W   #4,A7
         RTS

* Send ACK

SENDACK  SWAP     D6
         BTST     #S_XOFF,D7
         BEQ.S    SA_ACK
         MOVEQ    #XOFF,D1
         JSR      TXCHAR
         BRA.S    SA3
SA_ACK   BTST     #SLO,D7
         BNE.S    SA3
         BTST     #SEALINK,D7
         BNE.S    SA1
         QDOS     MT.RCLCK
         MOVEQ    #30,D2
         ADD.L    D1,D2
         MOVE.L   D2,-(A7)
SA0      QDOS     MT.RCLCK
         CMP.L    (A7),D1
         BHI.S    SA_FAIL
         MOVEQ    #0,D3
         BSR      GETCHR1
         BEQ      SA0
         BLT.S    SA_FAIL
         ADDQ.W   #4,A7
SA1      MOVEQ    #ACK,D1
         JSR      TXCHAR
         BTST     #SEALINK,D7
         BEQ.S    SA3
         MOVE.B   D6,D1
         JSR      TXCHAR
         NOT.B    D1
         JSR      TXCHAR
SA3      ADDQ.B   #1,D6
         SWAP     D6
         CLR.B    XR_NAKCT(A5)
         MOVEQ    #0,D0
         RTS
SA_FAIL  SWAP     D6
         ADDQ.W   #4,A7
         MOVEQ    #-1,D0
         RTS

CHRGOT   EQU      4
XS_TIME  EQU      -4
XS_FLEN  EQU      -8
XS_STPOS EQU      -12
ACKBLK   EQU      -16
ENDBLK   EQU      -20
ACKST    EQU      -22
ACKRCVD  EQU      -26
WINDOW   EQU      -28
XS_STACK EQU      -28

         XDEF     TX_CLINK

TX_CLINK MOVEM.L  D1-D6/A0-A2,-(A7)
         LINK     A5,#XS_STACK
         ANDI.L   #$FFFF,D7
XS0T     MOVEQ    #1,D0
         MOVE.W   D0,WINDOW(A5)
         MOVEQ    #-1,D0
         MOVE.L   D0,ACKBLK(A5)
         CLR.W    ACKST(A5)
         CLR.L    ACKRCVD(A5)
         CLR.L    XS_STPOS(A5)
         MOVEQ    #0,D4
         MOVEQ    #1,D5             SendBLK
         MOVEQ    #0,D6             NumNAK
         QDOS     MT.RCLCK
         MOVE.L   D1,XS_TIME(A5)
         MOVEQ    #64,D2
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BEQ.S    XS_GTLEN
         LEA      LOGBUF(A6),A1
         WRITE$   {'? Unable to read header file '}
         LEA      FNAMBUF(A6),A0
         WRITE$
         MOVE.B   #':',(A1)+
         MOVE.B   #' ',(A1)+
         JSR      WRITEERR
         CLR.B    -1(A1)
         JSR      LOG0
         MOVEQ    #XR.IOERR,D4
         BRA      XS_TXCAN
XS_GTLEN LOAD$    {'+ Sending (SEAlink): '},A0
         BTST     #WANT_C,D7
         BNE.S    XS_LOG
         LOAD$    {'+ Sending (Telink): '},A0
         BTST     #TELINK,D7
         BNE.S    XS_LOG
         LOAD$    {'+ Sending (XMODEM): '},A0
XS_LOG   LEA      LOGBUF(A6),A1
         WRITE$
         LEA      FNAMBUF(A6),A0
         MOVE.L   BUFFER(A6),D1
         MOVE.L   D1,XS_FLEN(A5)
         MOVE.L   D1,D0
         SUBQ.L   #1,D0
         ASR.L    #7,D0
         ADDQ.L   #2,D0
         MOVE.L   D0,ENDBLK(A5)
         BSR      LOGFSTAT
         MOVEQ    #30,D1
         JSR      SETTIMER
         CLR.B    D7
         MOVE.W   D7,D0
         ANDI.W   #1<<TELINK+1<<WANT_C,D0
         BEQ      XS1
         LEA      XMODBUF(A6),A1
         MOVE.W   #$00FF,(A1)+
         MOVEQ    #128/4-1,D0
XS_CLRTL CLR.L    (A1)+
         DBF      D0,XS_CLRTL
         LEA      XMODBUF+2(A6),A2
         MOVE.L   BUFFER(A6),D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+
         SWAP     D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+
         MOVE.L   BUFFER+$34(A6),D1
         BTST     #WANT_C,D7
         BNE.S    XS_CLDAT
         JSR      GETDATE
         MOVE.L   D3,D4
         SWAP     D4
         LSR.W    #1,D4
         LSL.W    #5,D3
         OR.W     D3,D4
         SWAP     D2
         ROR.W    #5,D2
         OR.W     D2,D4
         ROL.W    #8,D4
         MOVE.W   D4,(A2)+
         ADDQ.W   #1,D0
         LSL.W    #5,D0
         OR.W     D0,D1
         SWAP     D2
         SUBI.W   #1980,D2
         ROR.W    #7,D2
         OR.W     D2,D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+
         MOVE.L   A2,A1
         MOVEQ    #15,D0
XS_SPACE MOVE.B   #' ',(A1)+
         DBF      D0,XS_SPACE
         BRA.S    XS_FNAME
XS_CLDAT SUBI.L   #3287*24*60*60,D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+
         SWAP     D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+
XS_FNAME LEA      FILENAME(A6),A1
         MOVE.W   (A1)+,D0
         CMPI.W   #16,D0
         BLE.S    XS_CNAME
         MOVEQ    #16,D0
XS_CNAME MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D0
         BGT      XS_CNAME
         LEA      SIGNON,A1
         LEA      XMODBUF+27(A6),A2
XS_CSIGN MOVE.B   (A1)+,(A2)+
         BNE      XS_CSIGN
         MOVE.B   #1,XMODBUF+43(A6) CRCmode or RESYNC flag
         BTST     #WANT_C,D7
         BEQ.S    XS1
         MOVE.B   #1,XMODBUF+44(A6) MACFLOW flag
XS1      BSR      CHACKNAK
         BNE      XS_ERROR
         CMPI.W   #10,D6
         BHI      XS_FAIL
         TST.L    D5
         BNE.S    XS2
         CMPI.W   #4,D6
         BNE.S    XS2
         BCLR     #WANT_C,D7
         BEQ.S    XS1T
         LOG      {'- Retry limit exceeded, trying Telink',LF}
         BSET     #TELINK,D7
         BRA      XS0T
XS1T     LOG      {'- Remote doesn''t understand Telink block',LF}
         BCLR     #TELINK,D7
         CLR.W    D6
         ADDQ.L   #1,D5
         ADDQ.L   #1,ACKBLK(A5)
XS2      CMP.L    ENDBLK(A5),D5
         BHI.S    XS3
         BNE.S    XS2A
         MOVEQ    #EOT,D1
         JSR      TXCHAR
         LOAD$    {'Waiting for EOF acknowledgement',LF}
         BSR      PROGRESS
         ADDQ.L   #1,D5
         MOVEQ    #30,D1
         JSR      SETTIMER
         BRA      XS1
XS2A     MOVEQ    #0,D0
         MOVE.W   WINDOW(A5),D0
         ADD.L    ACKBLK(A5),D0
         CMP.L    D0,D5
         BGT.S    XS_WAIT
         BTST     #SLO,D7
         BEQ.S    XS_NOSLO
         BSR      SHIPBLK
         BNE      XS_IOERR
         MOVE.L   D5,ACKBLK(A5)
         ADDQ.L   #1,D5
         JSR      SET1MIN
         BRA      XS1
XS_NOSLO BSR      SHIPBLK
         BNE.S    XS_IOERR
         ADDQ.L   #1,D5
         MOVEQ    #30,D1
         JSR      SETTIMER
         BRA      XS1
XS3      MOVE.L   ACKBLK(A5),D0
         CMP.L    ENDBLK(A5),D0
         BGE.S    XS_OK
XS_WAIT  MOVEQ    #SP.PEND,D0
         MOVE.W   #30*50,D3
         JSR      DO_INP
         BRA      XS1
XS_OK    MOVE.L   XS_TIME(A5),D1
         MOVE.L   XS_FLEN(A5),D5
         SUB.L    XS_STPOS(A5),D5
         BSR      LOG_THRU
         MOVEQ    #XR.OK,D0
         BRA.S    XS_RTS
XS_ERROR CMPI.L   #ERR.NC,D0
         BEQ.S    XS_TIMO
         CMPI.L   #ERR.EF,D0
         BEQ.S    XS_RCDO
XS_CAN   LOG      {'? X-SEND: Aborted by remote',LF}
         MOVEQ    #XR.CAN,D4
         BRA.S    XS_TXCAN
XS_RCDO  LOG      {'? X-SEND: Carrier lost',LF}
         BRA.S    XS_RTS
XS_TIMO  LOG      {'? X-SEND: Fatal timeout',LF}
         MOVEQ    #XR.FAIL,D4
         BRA.S    XS_TXCAN
XS_FAIL  LOG      {'? X-SEND: Retry limit exceeded',LF}
         MOVEQ    #XR.FAIL,D4
         BRA.S    XS_TXCAN
XS_IOERR LEA      LOGBUF(A6),A1
         WRITE$   {'? X-SEND: File I/O Error ('},A1
         JSR      WRITEERR
         MOVE.B   #')',-1(A1)
         CLR.B    (A1)+
         JSR      LOG0
         MOVEQ    #XR.IOERR,D4
XS_TXCAN MOVEQ    #CAN,D1
         JSR      TXCHAR
         JSR      TXCHAR
         MOVE.L   D4,D0
XS_RTS   UNLK     A5
         MOVEM.L  (A7)+,D1-D6/A0-A2
         TST.L    D0
         RTS

* Handle ACK/NAK/RESYNC responses from receiver

CHACKNAK BCLR     #XR..SKIP,D7
         BEQ.S    CN_AGAIN
         MOVE.L   CHRGOT(A5),D1
         BRA.S    AC1
CN_AGAIN MOVEQ    #0,D3
         JSR      GETCHR1
         BEQ.S    AC1
         BLT.S    CN_RTS
CN_OK    MOVEQ    #0,D0
CN_RTS   RTS

AC1      CMPI.W   #2,ACKST(A5)
         BLS      AC6
         MOVE.L   D6,D0             Check blk#/^blk# complements
         SWAP     D0
         NOT.B    D1
         CMP.B    D0,D1
         BEQ.S    AC3
         NOT.B    D1
         BCLR     #SEALINK,D7
         MOVE.W   #1,WINDOW(A5)
         CLR.W    ACKST(A5)
         BRA      AC6
AC3      NEG.B    D1
         ADD.B    D5,D1
         BMI      CN_AGAIN
         ANDI.L   #$FF,D1
         NEG.L    D1
         ADD.L    D5,D1
         BLT      CN_AGAIN
         MOVE.W   ACKST(A5),D0
         CLR.W    ACKST(A5)
         SUBQ.W   #3,D0
         BEQ.S    AC5
         SUBQ.W   #1,D0
         BEQ.S    AC4
         LOG      {'? BUG: Incorrect ACK state',LF}
         BRA      CN_OK
AC4      TST.L    ACKBLK(A5)
         BMI      CN_AGAIN          Ignore blk# before first ACK
         MOVE.L   D1,D5             NAK block in SEAlink mode
         BSR      XS_REPOS
         LEA      LOGBUF(A6),A1
         WRITE$   {'Resending from '},A1
         MOVEQ    #0,D2
         JSR      ITOD_L
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D0
         LEA      LOGBUF(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
         JSR      PROGRESS
         BSET     #SEALINK,D7
         MOVE.W   #6,WINDOW(A5)
         CMPI.W   #4,D6
         BLT      CN_OK
         BCLR     #SEALINK,D7
         MOVE.W   #1,WINDOW(A5)
         BRA      CN_OK
AC5      BSET     #SEALINK,D7       ACK block in SEAlink mode
         MOVE.W   #6,WINDOW(A5)
         MOVE.L   D1,ACKBLK(A5)
         ADDQ.L   #1,ACKRCVD(A5)
         CLR.W    ACKST(A5)
         BTST     #SLO,D7
         BEQ      CN_OK
         MOVEQ    #10,D0
         CMP.L    ACKRCVD(A5),D0
         BHI      CN_OK
         BCLR     #SLO,D7
         BRA      CN_OK
AC6      CMPI.W   #1,ACKST(A5)
         BEQ.S    AC6_1
         CMPI.W   #2,ACKST(A5)
         BNE.S    AC6_2
AC6_1    SWAP     D6
         MOVE.B   D1,D6             Keep blk# for later
         SWAP     D6
         ADDQ.W   #2,ACKST(A5)
AC6_2    BTST     #SEALINK,D7
         BEQ.S    AC7
         TST.W    ACKST(A5)
         BNE      CN_AGAIN
AC7      CMPI.B   #ACK,D1
         BNE.S    AC7_2
         MOVE.W   #1,ACKST(A5)      Basic ACK state
         CLR.W    D6
         BTST     #SEALINK,D7
         BNE      CN_AGAIN
         ADDQ.L   #1,ACKBLK(A5)
         BRA      CN_OK
AC7_2    CMPI.B   #NAK,D1
         BEQ.S    AC7_2A
         CMPI.B   #C,D1
         BNE      AC7_3
AC7_2A   TST.L    ACKBLK(A5)        Basic NAK state
         BPL.S    AC7_2B
         CMPI.B   #C,D1
         SEQ      D7
         ANDI.B   #1,D7
AC7_2B   MOVE.W   #2,ACKST(A5)
         ADDQ.W   #1,D6
         JSR      DUMP_OPB
         MOVEQ    #30,D3
         JSR      PAUSE
         BTST     #SEALINK,D7
         BNE      CN_AGAIN
         MOVE.L   ACKBLK(A5),D5
         ADDQ.L   #1,D5
         BEQ      CN_OK
         BSR      XS_REPOS
         LEA      LOGBUF(A6),A1
         WRITE$   {'NAK (block #'},A1
         MOVE.L   D5,D1
         MOVEQ    #0,D2
         JSR      ITOD_L
         WRITE$   {') #'}
         MOVE.W   D6,D1
         JSR      ITOD_W
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D0
         LEA      LOGBUF(A6),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)
         JSR      PROGRESS
         BRA      CN_OK
AC7_3    CMPI.B   #SYN,D1
         BNE      AC7_4
         CLR.W    ACKST(A5)
         LOAD$    {'Receiving RESYNC packet',LF},A1
         JSR      PROGRESS
         JSR      DUMP_OPB
         JSR      SET1MIN
AC7_3A   LEA      XMODBUF(A6),A1
         MOVEQ    #0,D2
         MOVE.W   #5*50,D3
AC7_3B   JSR      GETCHR1
         BLT      AC7_3X
         BGT      AC7_3N
         MOVE.B   D1,(A1)+
         ADDQ.W   #1,D2
         CMPI.W   #16,D2
         BGT      AC7_3N
         CMPI.B   #ETX,D1
         BNE      AC7_3B
         JSR      GETCHR1
         BLT      AC7_3X
         BGT.S    AC7_3N
         MOVEQ    #0,D4
         MOVE.B   D1,D4
         JSR      GETCHR1
         BLT      AC7_3X
         BGT.S    AC7_3N
         LSL.W    #8,D1
         OR.W     D1,D4
         MOVE.W   D2,D0
         SUBQ.W   #2,D0
         LEA      XMODBUF(A6),A1
         JSR      CALCCRC
         CMP.W    D3,D4
         BNE.S    AC7_3N
         LEA      XMODBUF(A6),A1
         MOVEQ    #0,D1
         JSR      READNUM
         MOVE.L   D1,D5
         BEQ.S    AC7_3I
         BSET     #SEALINK,D7
         MOVE.W   #6,WINDOW(A5)
         MOVE.L   D5,ACKBLK(A5)
         SUBQ.L   #1,ACKBLK(A5)
         BSR      XS_REPOS
         MOVE.L   D1,XS_STPOS(A5)
         LEA      LOGBUF(A6),A1
         WRITE$   {'- Resuming from '}
         MOVEQ    #0,D2
         JSR      ITOD_L
         CLR.B    (A1)+
         JSR      LOG0
         MOVEQ    #ACK,D1
         JSR      TXCHAR
         BRA      CN_OK
AC7_3N   LOAD$    {'RESYNC packet bad or timeout',LF}
         JSR      PROGRESS
         MOVEQ    #NAK,D1
         JSR      TXCHAR
         BRA      AC7_3A
AC7_3I   LOG      {'? RESYNC block invalid',LF}
AC7_3X   LOG      {'? RESYNC failure',LF}
         MOVEQ    #XR.FAIL,D0
         RTS
AC7_4    CMPI.B   #XOFF,D1
         BNE.S    AC7_5
         MOVEQ    #10,D1
         JSR      SETTIMER
AC7_4A   MOVE.W   #10*50,D3
         JSR      GETCHR2
         BNE.S    AC7_4B
         CMPI.B   #XON,D1
         BNE      AC7_4A
AC7_4B   JSR      SET1MIN
         BRA      CN_AGAIN
AC7_5    CMPI.B   #CAN,D1
         BNE      CN_AGAIN
         MOVEQ    #50,D3
         JSR      GETCHR1
         BNE      CN_AGAIN
         CMPI.B   #CAN,D1
         BNE      AC1
         MOVEQ    #XR.CAN,D0
         RTS

* Position file pointer according to blk # in D5

XS_REPOS MOVE.L   D5,D1
         BEQ.S    XSR_RTS
         SUBQ.L   #1,D1
         LSL.L    #7,D1
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         QDOS     FS.POSAB
XSR_RTS  RTS

* Transmit blk # in D5

SHIPBLK  TST.L    D5
         BNE.S    SB_DATA
         LOAD$    {'Sending SEAlink header block',LF},A1
         BTST     #WANT_C,D7
         BNE.S    SB_PROG
         LOAD$    {'Sending Telink header block',LF},A1
SB_PROG  BSR      PROGRESS
         BRA.S    SB_CRC
SB_DATA  BSR      SHOWPOS
         MOVE.W   #128,D2
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         LEA      XMODBUF(A6),A1
         MOVE.B   D5,(A1)+
         MOVE.B   D5,(A1)
         NOT.B    (A1)+
         QDOS     IO.FSTRG
         TST.L    D0
         BEQ.S    SB_CRC
         CMPI.L   #ERR.EF,D0
         BNE.S    SB_IOERR
         TST.W    D1
         BNE.S    SB_PAD
SB_IOERR TST.L    D0
         RTS
SB_PAD   MOVEQ    #127,D0
         SUB.W    D1,D0
         BRA.S    SB_PAD3
SB_PAD2  MOVE.B   #$1A,(A1)+
SB_PAD3  DBF      D0,SB_PAD2
SB_CRC   MOVE.W   D7,-(A7)
         MOVEQ    #SOH,D1
         BTST     #TELINK,D7
         BEQ.S    SB_CRC2
         TST.L    D5
         BNE.S    SB_CRC2
         CLR.B    D7
         MOVEQ    #SYN,D1
SB_CRC2  MOVE.W   D1,-(A7)
         BSR.S    CALCHK
         MOVE.W   D3,(A1)
         MOVE.W   (A7)+,D1
         JSR      TXCHAR
         MOVEQ    #SP.SSTRG,D0
         MOVE.W   #131,D2
         ADD.B    D7,D2
         LEA      XMODBUF(A6),A1
         JSR      DO_OUTP
         MOVE.W   (A7)+,D7
         MOVEQ    #0,D0
         RTS

CALCHK   MOVEQ    #127,D0
         LEA      XMODBUF+2(A6),A1
         TST.B    D7
         BNE.S    CALCCRC
         MOVEQ    #0,D3
CHKLOOP  ADD.B    (A1)+,D3
         DBF      D0,CHKLOOP
         CLR.B    1(A1)
         LSL.W    #8,D3
         RTS

         XDEF     CALCCRC

CALCCRC  LEA      CRC_TBL,A0
         MOVEQ    #0,D3
CRCLOOP  MOVEQ    #0,D1
         MOVE.B   (A1)+,D1
         ROL.W    #8,D3
         EOR.B    D3,D1
         ADD.W    D1,D1
         MOVE.W   (A0,D1.W),D1
         CLR.B    D3
         EOR.W    D1,D3
         DBF      D0,CRCLOOP
         RTS

* Get number of free sectors in D1.L

GET_FREE MOVEQ    #0,D1
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IOF.XINF
         TST.L    D0
         BNE.S    NO_VERS2
         MOVE.L   $24(A1),D1
         MULU     $1E(A1),D1
         MOVEQ    #0,D0
         RTS
NO_VERS2 LEA      BUFFER(A6),A1
         QDOS     FS.MDINF
         SWAP     D1
         MULU     #512,D1
         TST.L    D0
         RTS

         INCLUDE  [qnet_inc]CRCCITT_IN

         SECTION  MSG

SIGNON   DC.B     'QBoxMail [version]'
         DC.B     0

         END
