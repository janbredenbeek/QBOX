*                 QBoss ELECTRONIC MAIL SYSTEM
*                 -----------------------------
*
* TOSSMAIL Utility
* ----------------
*
* Copyright (C) 1989-92 by Jan Bredenbeek, Hilversum, Holland.
*
* Start of programming work: 24th February 1989

version  SETSTR   1.19c

         INCLUDE  FLP2_MACRO_LIB
         INCLUDE  FLP2_QDOS_IN_MAC
         INCLUDE  FLP2_QBOXMAIL_H
         INCLUDE  FLP2_FSC39_H

BUFSIZE  EQU      4096

* Entry in common heap for each area name

         OFFSET   0

AR_NEXT  DS.L     1        Pointer to next entry (0 if none)
AR_ANUM  DS.W     1        QBOX msg area number
AR_NMSG  DS.W     1        Number of imported messages
AR_MINSZ DS.W     1        Minimum msg size
AR_MAXSZ DS.W     1        Maximum msg size
AR_TOTSZ DS.L     1        Total size
AR_ANAME EQU      *        Name of area (word followed by ASCII + CR)

* Variable storage

         OFFSET   0

CONCHAN  DS.L     1        ID of console channel
LOGCHAN  DS.L     1        ID of logfile channel
CTLCHAN  DS.L     1        ID of control file channel
MAREACHN DS.L     1        ID of MAREAS_BBS file channel
DIRPOS   DS.L     1
PKTCHAN  DS.L     1        ID of current _PKT file
MSGCHAN  DS.L     1        ID of current MESSAGES_BBS file
PKTPOS   DS.L     1        Position in packet of current message
MSGPTR   DS.L     1        Pointer to message text in buffer
MSGEND   DS.L     1        Pointer to end of message in buffer
ECHOINFO DS.L     1        Pointer to SEEN-BY info
MSGSUBJ  DS.L     1        Pointer to subject (original message)
SUBJECT  DS.L     1        Pointer to subject (imported message)
AREALIST DS.L     1        Start of area list
AR_NET   DS.L     1        Address of NETMAIL entry in list
AR_BAD   DS.L     1        Address of BADECHO entry in list
LASTACHN DS.L     1        ID of current MAREAS_BBS channel
POINTNET DS.W     1        Fakenet
NETMAREA DS.W     1        Netmail area number
BADECHO  DS.W     1        Bad echomail area
MYZONE   DS.W     1        Zone number
MYNET    DS.W     1        Net
MYNODE   DS.W     1        Node
MYPOINT  DS.W     1        Point (0 if node)
AKAS     DS.W     MAX_AKA*4+1 AKA's
PKTZONE  DS.W     1
PKTNET   DS.W     1
PKTNODE  DS.W     1
PKTPOINT DS.W     1
PKTMSG   DS.W     1        Packet message counter
LASTAREA DS.W     1        Number of area with last imported msg
CTLINUM  DS.W     1
MSGHDRLN DS.W     1        Length of message header
HPOS     DS.W     1        Horizontal window pos. save
NOLOG    DS.B     1        Make log (0) or not (<>0)
KEEPNULL DS.B     1        Keep null msgs (<>0) or not (0)
DEBUG    DS.B     1
         DS.W     0        Next areas must start on even address

SYSDIR   DS.B     2+48     System directory name
INBDDIR  DS.B     2+48     Inbound directory name
PKTFNAME DS.B     2+48     Name of packet file
FNAMBUF  DS.B     2+48     File name buffer
UNARCCMD DS.B     64       UNARC command
UNZIPCMD DS.B     64       UNZIP command
UNLZHCMD DS.B     64
UNZOOCMD DS.B     64
UNARJCMD DS.B     64
INBUF    DS.B     BUFSIZE  Buffer for _PKT file
MSGHDR   DS.B     180
BUFFER   DS.B     32768    General buffer area

         DATA     40*1024

         XREF     READNUM,READNODE,DIVLONG,GETDATE,DATE$,ITOD_W,ITOD_L
         XREF     MONTHTBL,TOUPPER,COMPSTR,COMPSTR1,DO_CMD,SKIPSPC,GETDIR
         XREF     ZNNP2A,A2ZNNP,FTSCTAB,DAYTAB,MAKEFNAM,READDIR
         XREF.S   MAXPROD

         SECTION  CODE

START    JMP      JOBSTART
         DS.B     6-(*-START)
         DC.W     $4AFB
JB_NAME  STRING$  {'TOSSMAIL'}

CTLFNAME STRING$  'ECHOCTL_BBS'
AREAFNAM STRING$  'MAREAS_BBS'
MSG_FNAM STRING$  'MESSAGES_BBS'
LOG_FNAM STRING$  'IMPORT_LOG'
OPTLIST  DC.W     NOLOG
         DC.B     '-NOLOG',0
         DC.W     KEEPNULL
         DC.B     '-KEEPNULL',0
         DC.W     DEBUG
         DC.B     '-DEBUG',0
         DC.W     0

BANNER   DC.B     4,1,4,0
         DC.W     448,182,32,20
CONSPEC  DC.B     0,0,0,7
         DC.W     444,170,34,31

LD_24BIT MOVEQ    #0,D1
         MOVE.B   (A1)+,D1
         SWAP     D1
         MOVE.B   (A1)+,D1
         LSL.W    #8,D1
         MOVE.B   (A1)+,D1
         RTS

READDATE MOVEM.L  D2/D5-D7/A0-A1,-(A7)
RD_DAY   JSR      READNUM
         BEQ.S    RD_MON
RD_SKPDY MOVE.B   (A1)+,D0
         BEQ      RD_ERR
         CMPI.B   #' ',D0
         BNE      RD_SKPDY
         JSR      SKIPSPC
         BRA      RD_DAY
RD_MON   MOVE.W   D1,D5
         SWAP     D5
         JSR      SKIPSPC
         ANDI.B   #$DF,(A1)
         BSR      LD_24BIT
         ORI.W    #$2020,D1
         MOVE.L   D1,D0
         CLR.W    D5
         EXG      A0,A1
         LEA      MONTHTBL,A1
RDMON_LP ADDQ.W   #1,D5
         CMPI.W   #12,D5
         BHI      RD_ERR
         BSR      LD_24BIT
         CMP.L    D0,D1
         BNE      RDMON_LP
         EXG      A0,A1
         JSR      SKIPSPC
         JSR      READNUM
         BNE      RD_ERR
         MOVE.W   D1,D6
         SWAP     D6
         JSR      SKIPSPC
         JSR      READNUM
         BNE      RD_ERR
         MOVE.W   D1,D6
         ADDQ.W   #1,A1
         JSR      READNUM
         BNE.S    RD_ERR
         MOVE.W   D1,D7
         SWAP     D7
         CLR.W    D7
         TST.B    (A1)
         BEQ.S    RD_CONV
         ADDQ.W   #1,A1
         JSR      READNUM
         MOVE.W   D1,D7
RD_CONV  MOVE.L   D6,D0
         CLR.W    D0
         SWAP     D0
         CMPI.W   #99,D0
         BHI.S    RD_YEAR
         ADDI.W   #1900,D0
RD_YEAR  SUBI.W   #1961,D0
         MOVE.W   D0,D1
         MULU     #365,D1
         MOVEQ    #3,D2
         AND.B    D0,D2
         LSR.W    #2,D0
         ADD.L    D0,D1
         SUBQ.W   #3,D2
         BNE.S    RD_NOADD
         CMPI.W   #2,D5
         BLS.S    RD_NOADD
         ADDQ.L   #1,D1
RD_NOADD MOVE.W   D5,D0
         MULU     #275,D0
         DIVU     #9,D0
         SUBQ.W   #2,D5
         BLS.S    RD_NOAD2
         SUBQ.W   #2,D0
RD_NOAD2 CLR.W    D5
         SWAP     D5
         ADD.W    D0,D5
         SUBI.W   #31,D5
         ADD.L    D5,D1
         MOVEQ    #24,D0
         BSR.S    MUL32
         MOVE.W   D6,D5
         ADD.L    D5,D1
         MOVEQ    #60,D0
         BSR.S    MUL32
         MOVE.W   D7,D5
         CLR.W    D7
         SWAP     D7
         ADD.L    D7,D1
         BSR.S    MUL32
         ADD.L    D5,D1
         BRA.S    RD_END
RD_ERR   QDOS     MT.RCLCK
         MOVE.L   20(A7),A1
RD_END   TST.B    (A1)+
         BNE      RD_END
         MOVEM.L  (A7)+,D2/D5-D7/A0
         ADDQ.W   #4,A7
         RTS

MUL32    MOVE.L   D1,D2
         SWAP     D2
         MULU     D0,D1
         MULU     D0,D2
         SWAP     D1
         ADD.W    D2,D1
         SWAP     D1
         RTS

* Create message area record
* Entry: D1 area number, A1 ptr to echo name
* Exit:  A0 start of record allocated
* Destroys contents of BUFFER(A6)

CAREA    MOVEM.L  D1-D4/A1,-(A7)
         TST.W    D1
         BLE.S    BADAREA
         CMPI.W   #MAXAREA,D1
         BGT.S    BADAREA
CA_2     MOVE.W   D1,D4
         MOVEQ    #127,D2
         MOVEQ    #-1,D3
         MOVE.L   MAREACHN(A6),A0
         SUB.W    LASTAREA(A6),D4
         BGT.S    CA_LOOP
         MOVE.W   D1,D4
         MOVEQ    #0,D1
         QDOS     FS.POSAB
CA_LOOP  LEA      BUFFER+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    BADAREA3
         SUBQ.W   #1,D4
         BGT      CA_LOOP
         SUBA.W   D1,A1
         LEA      -2(A1),A0
         JSR      GETDIR
         BNE.S    BADAREA
         TST.W    D1
         BNE.S    CA_ALLOC
BADAREA3 LEA      BUFFER+2(A6),A1
         WRITE$   {'*** ERROR: Undefined message area (#'},A1
         MOVE.L   (A7),D1
         MOVEQ    #0,D2
         JSR      ITOD_W
         MOVE.B   #')',(A1)+
         BRA.S    BADAREA2
BADAREA  LEA      BUFFER+2(A6),A1
         WRITE$   {'*** ERROR: Bad area specification at line '},A1
         MOVE.W   CTLINUM(A6),D1
         MOVEQ    #0,D2
         JSR      ITOD_W
BADAREA2 MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         LEA      BUFFER+2(A6),A1
         SUB.L    A1,D2
         MOVE.W   D2,-(A1)
         MOVEQ    #ERR.BP,D0
         BRA      ERR_EXIT
CA_ALLOC ADDI.W   #AR_ANAME+3,D1
         BCLR     #0,D1
         MOVE.L   16(A7),A0
         ADD.W    (A0),D1
         ADDQ.W   #4,D1
         BCLR     #0,D1
         MOVEQ    #-1,D2
         QDOS     MT.ALCHP
         TST.L    D0
         IF NE THEN
            LOAD$    {'*** ERROR: Out of memory',LF}
            BRA      ERR_EXIT
         ENDIF
         MOVE.L   A0,A2
         MOVE.W   2(A7),AR_ANUM(A0)
         MOVE.W   #32767,AR_MINSZ(A0)
         LEA      AR_ANAME(A0),A1
         MOVE.L   16(A7),A0
         MOVE.W   (A0)+,D0
         MOVE.W   D0,(A1)
         ADDQ.W   #1,(A1)+
CA_CPNAM MOVE.B   (A0)+,D1
         JSR      TOUPPER
         MOVE.B   D1,(A1)+
         SUBQ.W   #1,D0
         BGT      CA_CPNAM
         MOVE.B   #CR,(A1)+
         LEA      AR_ANAME(A2),A1
         MOVE.W   (A1)+,D0
         ADDQ.W   #1,D0
         BCLR     #0,D0
         ADDA.W   D0,A1
         LEA      BUFFER(A6),A0
         WRITEL$
         MOVE.L   A2,A0
         LEA      AREALIST(A6),A2
CA_LINK  TST.L    (A2)
         BEQ.S    CA_LINK2
         MOVE.L   (A2),A2
         BRA      CA_LINK
CA_LINK2 MOVE.L   A0,(A2)
         MOVEM.L  (A7)+,D1-D4/A1
         MOVE.W   D1,LASTAREA(A6)
         RTS

GET0_PKT BSR.S    GETC_PKT
         BNE.S    GET0_END
         MOVE.B   D1,(A1)+
         BEQ.S    GET0_END
         SUBQ.W   #1,D2
         BNE      GET0_PKT
         CLR.B    -1(A1)
GET0_SKP BSR.S    GETC_PKT
         BNE.S    GET0_EN1
         TST.B    D1
         BNE      GET0_SKP
GET0_EN1 MOVEQ    #1,D0
GET0_END RTS

GETS_PKT BSR.S    GETC_PKT
         BNE.S    GETS_END
         MOVE.B   D1,(A1)+
         SUBQ.W   #1,D2
         BGT      GETS_PKT
GETS_END TST.L    D0
         RTS

* Read character from packet file

GETC_PKT SUBQ.W   #1,D7
         BLT.S    NEWBUFF
         MOVE.B   (A5)+,D1
         MOVEQ    #0,D0
         RTS
NEWBUFF  MOVEM.L  D2-D3/A0-A1,-(A7)
         MOVE.W   #BUFSIZE,D2
         MOVEQ    #-1,D3
         MOVE.L   PKTCHAN(A6),A0
         LEA      INBUF(A6),A1
         MOVE.L   A1,A5
         QDOS     IO.FSTRG
         MOVE.W   D1,D7
         MOVEM.L  (A7)+,D2-D3/A0-A1
         TST.L    D0
         BEQ      GETC_PKT
         CMPI.L   #ERR.EF,D0
         BNE.S    GPKT_ERR
         TST.W    D1
         BNE      GETC_PKT
GPKT_ERR TST.L    D0
         RTS

COPYCSTR MOVE.L   A2,A0
         CLR.B    (A0)
         ADDQ.W   #1,A2
CSTR_LP  MOVE.B   (A1)+,D0
         BEQ.S    CSTR_END
         MOVE.B   D0,(A2)+
         ADDQ.B   #1,(A0)
         BRA      CSTR_LP
CSTR_END RTS

CMD_TAB  DC.W     DO_INB-*
         STRING$  'INBOUND='
         DC.W     DO_PNET-*
         STRING$  'POINTNET='
         DC.W     DO_AKA-*
         STRING$  'AKA'
         DC.W     DO_NETM-*
         STRING$  'NETMAIL='
         DC.W     DO_BAD-*
         STRING$  'BADECHO='
         DC.W     DO_UNARC-*
         STRING$  'UNARC='
         DC.W     DO_UNZIP-*
         STRING$  'UNZIP='
         DC.W     DO_UNLZH-*
         STRING$  'UNLZH='
         DC.W     DO_UNZOO-*
         STRING$  'UNZOO='
         DC.W     DO_UNARJ-*
         STRING$  'UNARJ='
         DC.W     0

DO_NETM  MOVEQ    #NETMAREA,D7
         BRA.S    DO_NUM
DO_BAD   MOVEQ    #BADECHO,D7
         BRA.S    DO_NUM
DO_PNET  MOVEQ    #POINTNET,D7
DO_NUM   JSR      READNUM
         BNE.S    CMD_ERR
         MOVE.W   D1,(A6,D7.W)
         RTS

DO_AKA   JSR      SKIPSPC
         BEQ.S    AKA_END
         LEA      AKAS(A6),A0
         MOVE.W   (A0)+,D0
         CMPI.W   #MAX_AKA,D0
         BGE.S    AKA2MANY
         LSL.W    #3,D0
         ADDA.W   D0,A0
         MOVEM.W  -8(A0),D2-D5
         JSR      A2ZNNP
         BNE.S    CMD_ERR
         MOVEM.W  D2-D5,(A0)
         ADDQ.W   #1,AKAS(A6)
         BRA      DO_AKA
AKA_END  RTS
AKA2MANY LOAD$    {'*** ERROR - Too many AKAs specified',LF}
         BRA      ERR_EXIT

DO_INB   LEA      INBDDIR(A6),A0
         JSR      GETDIR
         BNE.S    CMD_ERR
         RTS

DO_UNARC LEA      UNARCCMD(A6),A0
         BRA.S    CP_CMD
DO_UNZIP LEA      UNZIPCMD(A6),A0
         BRA.S    CP_CMD
DO_UNLZH LEA      UNLZHCMD(A6),A0
         BRA.S    CP_CMD
DO_UNZOO LEA      UNZOOCMD(A6),A0
         BRA.S    CP_CMD
DO_UNARJ LEA      UNARJCMD(A6),A0
CP_CMD   MOVEQ    #0,D1
CPCMD_LP ADDQ.W   #1,D1
         CMPI.W   #64,D1
         BGT.S    CPCMDERR
         MOVE.B   (A1)+,D0
         MOVE.B   D0,(A0)+
         CMPI.B   #LF,D0
         BNE      CPCMD_LP
         RTS
CPCMDERR MOVEQ    #ERR.BN,D0
CMD_ERR  LOAD$    {'*** ERROR - Command parameter error: '},A1
         BRA      ERR_EXIT

DEARCZIP LEA      PKTFNAME(A6),A0
         LEA      INBDDIR(A6),A1
         LEA      FNAMBUF(A6),A2
         JSR      MAKEFNAM
         BNE.S    D_OERROR
         MOVEQ    #IO.SHARE,D3
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    D_OERROR
         MOVEQ    #4,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IO.FSTRG
         MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
         BNE.S    D_OERROR
         LEA      BUFFER(A6),A1
         LEA      UNARCCMD(A6),A3
         CMPI.B   #$1A,(A1)
         BEQ.S    D_PROCES
         LEA      UNZIPCMD(A6),A3
         CMPI.W   #'PK',(A1)
         BEQ.S    D_PROCES
         LEA      UNARJCMD(A6),A3
         CMPI.W   #$60EA,(A1)
         BEQ.S    D_PROCES
         LEA      UNZOOCMD(A6),A3
         CMPI.W   #'ZO',(A1)+
         BEQ.S    D_PROCES
         LEA      UNLZHCMD(A6),A3
         CMPI.W   #'-l',(A1)
         BEQ.S    D_PROCES
         MOVEQ    #ERR.BP,D0
D_OERROR MOVE.L   D0,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Unable to process bundle '}
         LEA      PKTFNAME(A6),A1
         JSR      (A2)
         PRINT    {': '}
         MOVE.L   (A7)+,D0
         JMP      UT_ERR
D_PROCES LEA      INBUF(A6),A0
         CLR.W    (A0)
         LEA      2(A0),A1
D_CP1    CMPI.B   #' ',(A3)
         BLS.S    D_PNAME
         MOVE.B   (A3)+,(A1)+
         ADDQ.W   #1,(A0)
         BRA      D_CP1
D_PNAME  TST.W    (A0)
         IF EQ THEN
            MOVE.L   CONCHAN(A6),A0
            PRINT    {'Unarchiving command missing!',LF}
            RTS
         ENDIF
         MOVEQ    #-1,D1
         MOVEQ    #IO.SHARE,D3
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    D_PERROR
         MOVEQ    #10,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE.S    D_PERR2
         SUBA.W   D1,A1
         MOVEQ    #ERR.BP,D0
         CMPI.B   #1,5(A1)
         BNE.S    D_PERR2
         MOVE.L   (A1),D2
         MOVE.L   6(A1),D3
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         MOVE.L   A0,-(A7)
         QDOS     MT.CJOB
         MOVE.L   A0,A1
         MOVE.L   (A7)+,A0
         TST.L    D0
         BNE.S    D_PERR2
         MOVE.L   D1,D4
         MOVEQ    #-1,D3
         MOVE.L   A1,A2
         QDOS     FS.LOAD
         TST.L    D0
         BEQ.S    D_CMDLN
         MOVE.L   D0,-(A7)
         MOVE.L   D4,D1
         QDOS     MT.FRJOB
         MOVE.L   (A7)+,D0
D_PERR2  MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
D_PERROR MOVE.L   D0,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {'Unable to execute unarchiving program '}
         LEA      INBUF(A6),A1
         JSR      (A2)
         PRINT    {': '}
         MOVE.L   (A7)+,D0
         JMP      UT_ERR
D_CMDLN  QDOS     IO.CLOSE
         LEA      BUFFER(A6),A1
D_CMDLN2 CMPI.B   #LF,(A3)
         BEQ.S    D_CMDLN3
         MOVE.B   (A3)+,(A1)+
         BRA      D_CMDLN2
D_CMDLN3 MOVE.B   #' ',(A1)+
         LEA      FNAMBUF(A6),A0
         WRITE$
         MOVE.B   #' ',(A1)+
         LEA      SYSDIR(A6),A0
         WRITE$
         MOVE.L   A1,D0
         LEA      BUFFER(A6),A1
         SUB.L    A1,D0
         MOVE.L   D0,D1
         ADDQ.L   #1,D1
         BCLR     #0,D1
         MOVE.L   $5C-$68(A2),A0
         SUBA.L   D1,A0
         SUBQ.W   #4,A0
         MOVE.L   A0,$5C-$68(A2)
         MOVE.W   #1,(A0)+
         MOVE.L   CONCHAN(A6),(A0)+
         MOVE.W   D0,(A0)+
D_CMDLN4 MOVE.B   (A1)+,(A0)+
         SUBQ.W   #1,D0
         BGT      D_CMDLN4
         MOVE.L   D4,D1
         MOVEQ    #32,D2
         MOVEQ    #-1,D3
         QDOS     MT.ACTIV
         TST.L    D0
         BNE.S    D_ERROR
         MOVEQ    #-1,D1
         LEA      FNAMBUF(A6),A0
         QDOS     IO.DELET
         MOVE.L   CONCHAN(A6),A0
         LEA      PKTFNAME(A6),A1
         MOVE.W   (A1)+,D2
         MOVEQ    #0,D3
         QDOS     IO.SSTRG
         LOAD$    {' removed',LF},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #0,D0
         RTS

* Dearchiving program reported error, delete unpacked .PKTs

D_ERROR  MOVE.L   CONCHAN(A6),A0
         LEA      PKTFNAME(A6),A1
         MOVE.W   (A1)+,D2
         MOVEQ    #0,D3
         QDOS     IO.SSTRG
         LOAD$    {' is incomplete or invalid',LF},A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3
         LEA      SYSDIR(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    D_END
         LEA      SYSDIR(A6),A2
D_DEL_LP BSR.S    FINDPKT
         BNE.S    D_END2
         MOVE.L   A0,-(A7)
         MOVEQ    #-1,D1
         LEA      FNAMBUF(A6),A0
         QDOS     IO.DELET
         MOVE.L   (A7)+,A0
         BRA      D_DEL_LP
D_END2   QDOS     IO.CLOSE
D_END    MOVEQ    #-1,D0
         RTS

* Find next _PKT or .PKT file in directory
* Entry: A0 dir channel ID; A2 directory name
* Exit : D0 error code; D1=-1; A0 full filename

FINDPKT  LEA      INBUF(A6),A1
         JSR      READDIR
         BNE.S    FP_END
         CMPI.W   #4,D1
         BLS      FINDPKT
         MOVE.B   -1(A1,D1.W),D0
         ROR.L    #8,D0
         MOVE.B   -2(A1,D1.W),D0
         ROR.L    #8,D0
         MOVE.B   -3(A1,D1.W),D0
         ROR.L    #8,D0
         MOVE.B   -4(A1,D1.W),D0
         ROR.L    #8,D0
         ANDI.L   #$FFDFDFDF,D0
         CMPI.L   #'.PKT',D0
         BEQ.S    FP_ISPKT
         CMPI.L   #'_PKT',D0
         BNE      FINDPKT
FP_ISPKT MOVEM.L  A0/A2,-(A7)
         LEA      PKTFNAME(A6),A0
         MOVE.W   D1,(A0)+
FP_CPNAM MOVE.B   (A1)+,(A0)+
         SUBQ.W   #1,D1
         BGT      FP_CPNAM
         LEA      PKTFNAME(A6),A0
         MOVE.L   A2,A1
         LEA      FNAMBUF(A6),A2
         JSR      MAKEFNAM
         MOVEM.L  (A7)+,A0/A2
FP_END   RTS

OPENSYS  LEA      SYSDIR(A6),A1
         LEA      FNAMBUF(A6),A2
         JSR      MAKEFNAM
         BNE.S    OS_END
         QDOS     IO.OPEN
         TST.L    D0
OS_END   RTS

JOBSTART ADDA.L   A4,A6
         CLR.L    LOGCHAN(A6)
         MOVE.W   (A7)+,D0
         BEQ.S    OPEN_CON
         MOVE.L   (A7),A0
         LSL.W    #2,D0
         ADDA.W   D0,A7
         BRA.S    SET_CON
OPEN_CON LEA      BANNER,A1
         MOVE.W   UT_SCR,A2
         JSR      (A2)
         BNE.S    CON_ERR
         LEA      JB_NAME,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         LEA      CONSPEC,A1
         MOVE.W   UT_SCR,A2
         JSR      (A2)
         BEQ.S    SET_CON
CON_ERR  MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'TOSSMAIL: Unable to open screen window',LF}
         MOVE.L   (A7)+,D0
         BRA      ERR_EX2
SET_CON  MOVE.L   A0,CONCHAN(A6)
         PRINT    {'TOSSMAIL  QBOX Network Mail Tosser  v[version]',LF}
         PRINT    {'Copyright (C) 1989-92 by Jan Bredenbeek',LF,LF}
         MOVE.L   A7,A0
         MOVE.L   A7,A1
         WRITE$
         MOVE.B   #LF,(A1)+
         SF       NOLOG(A6)
         SF       KEEPNULL(A6)
         SF       DEBUG(A6)
         CLR.W    LASTAREA(A6)
         CLR.W    POINTNET(A6)
         CLR.W    AKAS(A6)
         CLR.W    NETMAREA(A6)
         CLR.W    BADECHO(A6)
         CLR.W    INBDDIR(A6)
         MOVEQ    #LF,D0
         MOVE.B   D0,UNARCCMD(A6)
         MOVE.B   D0,UNZIPCMD(A6)
         MOVE.B   D0,UNLZHCMD(A6)
         MOVE.B   D0,UNZOOCMD(A6)
         MOVE.B   D0,UNARJCMD(A6)
         CLR.L    AREALIST(A6)
         LEA      SYSDIR(A6),A0
         MOVE.L   A7,A1
         BSR      GETDIR
         BNE.S    SD_ERROR
         TST.W    D1
         BNE.S    GET_OPT
         QDOS     MT.INF
         TST.L    $AC(A0)
         BNE.S    COPY_SD
SD_ERROR LOAD$    {'*** ERROR: System directory specification missing or invalid',LF}
         BRA.S    ERR_EXIT
COPY_SD  MOVE.L   $AC(A0),A0
         MOVE.L   A1,-(A7)
         LEA      SYSDIR(A6),A1
         WRITEL$
         MOVE.L   (A7)+,A1
GET_OPT  BSR      SKIPSPC
         BEQ      OPT_END
         LEA      OPTLIST,A0
OPT_LOOP MOVE.W   (A0)+,D7
         BEQ.S    OPT_ERR
         MOVE.L   A1,A2
OPT_NXCH MOVE.B   (A0)+,D0
         BEQ.S    OPT_ENDC
         MOVE.B   (A1)+,D1
         BSR      TOUPPER
         CMP.B    D0,D1
         BEQ      OPT_NXCH
OPT_SKIP TST.B    (A0)+
         BNE      OPT_SKIP
OPT_NEXT MOVE.L   A2,A1
         MOVE.W   A0,D0
         LSR.W    #1,D0
         BCC      OPT_LOOP
         ADDQ.W   #1,A0
         BRA      OPT_LOOP
OPT_ENDC CMPI.B   #LF,(A1)
         BEQ.S    OPT_FND
         CMPI.B   #' ',(A1)
         BNE      OPT_NEXT
OPT_FND  TST.W    D7
         BLT.S    OPT_NUM
         ST       (A6,D7.W)
         BRA      GET_OPT
OPT_NUM  NEG.W    D7
         BSR      SKIPSPC
         BSR      READNUM
         BNE.S    OPT_ERR
         MOVE.W   D1,(A6,D7.W)
         BRA      GET_OPT
OPT_ERR  LOAD$    {'*** ERROR: Bad option or option parameter',LF}
         MOVEQ    #ERR.BP,D0
ERR_EXIT MOVE.L   D0,D4
         MOVE.L   A1,A4
         MOVE.L   CONCHAN(A6),A0
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVE.L   D4,D0
         MOVE.W   (A4)+,D1
         CMPI.B   #LF,-1(A4,D1.W)
         BEQ.S    ERR_EX2
         MOVE.W   UT_ERR,A2
         JSR      (A2)
         BRA.S    ERR_EX2
MAIN_END MOVEQ    #0,D0
ERR_EX2  MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

OPT_END  MOVEQ    #IO.SHARE,D3
         LEA      CTLFNAME,A0
         BSR      OPENSYS
         IF NE THEN
            LOAD$    {'*** ERROR: Unable to open control file ECHOCTL_BBS: '},A1
            BRA      ERR_EXIT
         ENDIF
         MOVE.L   A0,CTLCHAN(A6)
         TST.B    NOLOG(A6)
         BNE.S    OPEN_BBS
         MOVEQ    #IO.EXCL,D3
         LEA      LOG_FNAM,A0
         BSR      OPENSYS
         BEQ.S    SET_END
         CMPI.L   #ERR.NF,D0
         IF NE THEN
            LOAD$    {'*** ERROR: Unable to open IMPORT_LOG: '},A1
            BRA      ERR_EXIT
         ENDIF
         MOVEQ    #IO.NEW,D3
         LEA      LOG_FNAM,A0
         BSR      OPENSYS
         IF NE THEN
            LOAD$    {'*** ERROR: Unable to create IMPORT_LOG: '},A1
            BRA      ERR_EXIT
         ENDIF
         PRINT    {'--- TOSSMAIL MESSAGE IMPORT LOG ---',LF,LF}
         PRINT    {'   Date            Area        #Msg  Minsz Avgsz Maxsz  Totsz ',LF}
         PRINT    {'-----------  ----------------  ----  ----- ----- ----- -------',LF}
         BRA.S    SETLCHAN
SET_END  MOVE.L   #9999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
SETLCHAN MOVE.L   A0,LOGCHAN(A6)
OPEN_BBS LEA      AREAFNAM,A0
         MOVEQ    #IO.SHARE,D3
         BSR      OPENSYS
         IF NE THEN
            LOAD$    {'*** ERROR - Unable to open MAREAS_BBS: '},A1
            BRA      ERR_EXIT
         ENDIF
         MOVE.L   A0,MAREACHN(A6)
         MOVEQ    #127,D2
         MOVEQ    #-1,D3
         MOVE.L   CTLCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    CTL_IOER
         SUBA.W   D1,A1
         MOVEQ    #0,D2
         MOVEQ    #0,D3
         MOVEQ    #0,D4
         JSR      A2ZNNP
         BEQ.S    ADDR_OK
         LOAD$    {'*** ERROR - Bad address specification in ECHOCTL_BBS',LF},A1
         BRA      ERR_EXIT
CTL_IOER LOAD$    {'*** ERROR - I/O Error ECHOCTL_BBS: '},A1
         BRA      ERR_EXIT
ADDR_OK  MOVEM.W  D2-D5,MYZONE(A6)
         MOVEQ    #127,D2
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE      CTL_IOER
         QDOS     IO.FLINE
         TST.L    D0
         BNE      CTL_IOER
         MOVE.W   #3,CTLINUM(A6)
GET_CLIN ADDQ.W   #1,CTLINUM(A6)
         MOVE.W   #32767,D2
         MOVEQ    #-1,D3
         MOVE.L   CTLCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     IO.FLINE
         CMPI.L   #ERR.EF,D0
         BEQ.S    CHKPARAM
         TST.L    D0
         BNE      CTL_IOER
         SUBA.W   D1,A1
         MOVE.W   D1,D2
         SUBQ.W   #1,D1
         BEQ      GET_CLIN
         CMPI.B   #' ',(A1)
         BEQ      GET_CLIN
         CMPI.B   #'*',(A1)
         BEQ      GET_CLIN
         CMPI.B   #';',(A1)
         BEQ      GET_CLIN
         CMPI.B   #'-',(A1)
         BNE.S    CTL_AREA
         ADDQ.W   #1,A1
         LEA      CMD_TAB,A2
         JSR      DO_CMD
         BRA      GET_CLIN
CTL_AREA JSR      READNUM
         BNE      BADAREA
         JSR      SKIPSPC
         BEQ      GET_CLIN
         MOVE.W   D1,-(A7)
         LEA      INBUF(A6),A0
         JSR      GETDIR
         MOVE.W   (A7)+,D1
         MOVE.L   A0,A1
         BSR      CAREA
         BRA      GET_CLIN
CHKPARAM MOVEQ    #ERR.BP,D0
         LOAD$    {'*** ERROR: No inbound directory specified in ECHOCTL_BBS',LF},A1
         TST.W    INBDDIR(A6)
         BEQ      ERR_EXIT
         LOAD$    {'*** ERROR: No NetMail area specified in ECHOCTL_BBS',LF},A1
         MOVE.W   NETMAREA(A6),D1
         BEQ      ERR_EXIT
         LEA      INBUF(A6),A1
         WRITEL$  {'NETMAIL'},A1
         LEA      INBUF(A6),A1
         BSR      CAREA
         MOVE.L   A0,AR_NET(A6)
         CLR.L    (A2)
         CLR.L    AR_BAD(A6)
         MOVE.W   BADECHO(A6),D1
         BEQ.S    OPEN_INB
         LEA      INBUF(A6),A1
         WRITEL$  {'BADECHO'},A1
         LEA      INBUF(A6),A1
         BSR      CAREA
         MOVE.L   A0,AR_BAD(A6)
         CLR.L    (A2)
OPEN_INB CLR.W    LASTAREA(A6)
         LEA      INBDDIR(A6),A0
         BSR      TOSS_PKT
         CLR.L    DIRPOS(A6)
LOOKARC  MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3
         LEA      INBDDIR(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE      TP_NO
         MOVE.L   DIRPOS(A6),D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
LOOKARC2 LEA      INBUF(A6),A1
         LEA      INBDDIR(A6),A2
         JSR      READDIR
         BEQ.S    LOOKARC3
         CMPI.L   #ERR.EF,D0
         BNE      DIRIOERR
         QDOS     IO.CLOSE
         BRA.S    END_TOSS
LOOKARC3 CMPI.W   #12,D1
         BNE      LOOKARC2
         CMPI.B   #'.',8(A1)
         BNE      LOOKARC2
         MOVE.B   9(A1),D1
         LSL.W    #8,D1
         MOVE.B   10(A1),D1
         ANDI.W   #$DFDF,D1
         MOVEQ    #6,D0
         LEA      DAYTAB,A2
LOOKARC6 CMP.W    (A2)+,D1
         DBEQ     D0,LOOKARC6
         BNE      LOOKARC2
         MOVEQ    #12,D1
         LEA      PKTFNAME(A6),A2
         MOVE.W   D1,(A2)+
LOOKARC7 MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      LOOKARC7
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         MOVE.L   D1,DIRPOS(A6)
         QDOS     IO.CLOSE
         BSR      DEARCZIP
         BNE      LOOKARC
         LEA      SYSDIR(A6),A0
         BSR.S    TOSS_PKT
         BRA      LOOKARC

END_TOSS BSR      REPORT
         BRA      MAIN_END

CL_AREA  TST.W    LASTAREA(A6)
         BEQ.S    CL_END
         SUBA.W   #16,A7
         MOVEQ    #14,D2
         MOVEQ    #-1,D3
         MOVE.L   LASTACHN(A6),A0
         MOVE.L   A7,A1
         QDOS     FS.HEADR
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         MOVE.L   A7,A1
         MOVE.L   D1,10(A1)
         QDOS     FS.HEADS
         QDOS     IO.CLOSE
         CLR.W    LASTAREA(A6)
         ADDA.W   #16,A7
CL_END   RTS

TOSS_PKT MOVEQ    #-1,D1
         MOVEQ    #IO.DIR,D3
         MOVE.L   A0,A2
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    TP_NEXT
TP_NO    LOAD$    {'*** ERROR - Unable to open inbound directory: '},A1
         BRA      ERR_EXIT
TP_NEXT  BSR      FINDPKT
         BEQ.S    TP_PKT
         CMPI.L   #ERR.EF,D0
         BEQ.S    TP_END
DIRIOERR LOAD$    {'*** ERROR - Directory I/O Error: '},A1
         BRA      ERR_EXIT
TP_PKT   MOVEM.L  A0/A2,-(A7)
         BSR.S    UNPK_PKT
         BSR      CL_AREA
         MOVEM.L  (A7)+,A0/A2
         TST.L    D0
         BNE      TP_NEXT
         TST.B    DEBUG(A6)
         BNE      TP_NEXT
         MOVEM.L  A0/A2,-(A7)
         LEA      PKTFNAME(A6),A0
         MOVE.L   A2,A1
         LEA      FNAMBUF(A6),A2
         JSR      MAKEFNAM
         QDOS     IO.DELET
         MOVEM.L  (A7)+,A0/A2
         BRA      TP_NEXT
TP_END   QDOS     IO.CLOSE
         RTS

UNPK_PKT MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BEQ.S    UNPK_2
UNPK_OP  MOVE.L   D0,-(A7)
         LOAD$    {'Unable to open '},A1
         BRA.S    UNPK_ERR
UNPK_IO  MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         LOAD$    {'Packet file I/O Error '}
UNPK_ERR MOVE.L   CONCHAN(A6),A0
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         LEA      FNAMBUF(A6),A1
         JSR      (A2)
         PRINT    {': '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JMP      (A2)
UNPK_2   MOVE.L   A0,PKTCHAN(A6)
         MOVEQ    #10,D2
         MOVEQ    #-1,D3
         LEA      INBUF(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      UNPK_IO
         MOVE.L   -(A1),PKTPOS(A6)
         MOVE.W   #PK_HDLEN,D2
         LEA      INBUF(A6),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE      UNPK_IO
         SUBA.W   D1,A1
         MOVE.W   PK_VERSN(A1),D0
         ROL.W    #8,D0
         CMPI.W   #PKTVERS,D0
         BEQ.S    VERSN_OK
         QDOS     IO.CLOSE
         MOVE.L   CONCHAN(A6),A0
         LEA      PKTFNAME(A6),A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         PRINT    {': Incorrect packet version!',LF}
         MOVEQ    #ERR.BP,D0
         RTS
VERSN_OK MOVE.W   PK_ONODE(A1),D0
         ROL.W    #8,D0
         MOVE.W   D0,PKTNODE(A6)
         MOVE.W   PK_ONET(A1),D0
         ROL.W    #8,D0
         MOVE.W   D0,PKTNET(A6)
         MOVEQ    #0,D3
         MOVE.B   PK_PRDCL(A1),D3
         MOVE.W   PK_CAPWD(A1),D2
         ROL.W    #8,D2
         CMP.W    PK_CAPVL(A1),D2
         IF NE THEN
            MOVEQ    #0,D2
         ENDIF
         BTST     #0,D2
         BNE.S    IS2PLUS
         CMPI.B   #FRODO,D3
         BEQ.S    IS2PLUS2
         CMPI.B   #DBRIDGE,D3
         BEQ.S    IS2PLUS2
         CMPI.B   #TOSSCAN,D3
         BEQ.S    IS2PLUS2
         CMPI.B   #XRS,D3
         BEQ.S    IS2PLUS2
         CMPI.B   #QMAIL,D3
         BEQ.S    IS_Q
         CMPI.B   #ZMAILQ,D3
         BEQ.S    IS_Q
         MOVEQ    #0,D0
         MOVEQ    #0,D1
         BRA.S    SET_ZP
IS2PLUS  MOVE.B   PK_PRDCH(A1),D0
         LSL.W    #8,D0
         OR.W     D0,D3
IS2PLUS2 MOVE.W   PK_OZONE(A1),D0
         MOVE.W   PK_OPNT(A1),D1
         BRA.S    SET_ZP
IS_Q     MOVE.W   PK_QOZON(A1),D0
         MOVEQ    #0,D1
SET_ZP   ROL.W    #8,D0
         MOVE.W   D0,PKTZONE(A6)
         ROL.W    #8,D1
         MOVE.W   D1,PKTPOINT(A6)
         LEA      BUFFER(A6),A1
         WRITE$   {'Unpacking '},A1
         LEA      PKTFNAME(A6),A0
         WRITE$
         WRITE$   {' from '},A1
         LEA      PKTZONE(A6),A2
         JSR      ZNNP2A
         MOVE.B   #' ',(A1)+
         MOVE.B   #'(',(A1)+
         CMPI.W   #MAXPROD,D3
         IF HI THEN
            MOVE.W   #MAXPROD+1,D3
         ENDIF
         LEA      FTSCTAB,A0
         ADD.W    D3,D3
         ADDA.W   (A0,D3.W),A0
         WRITE$
         MOVE.B   #')',(A1)+
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #0,D3
         MOVE.L   CONCHAN(A6),A0
         QDOS     IO.SSTRG
         MOVE.L   PKTPOS(A6),D1
         IF NE THEN
            LEA      BUFFER(A6),A1
            WRITE$   {'Continuing from position '}
            MOVEQ    #0,D2
            JSR      ITOD_L
            MOVE.B   #LF,(A1)+
            MOVE.L   A1,D2
            LEA      BUFFER(A6),A1
            SUB.L    A1,D2
            QDOS     IO.SSTRG
            MOVE.L   PKTPOS(A6),D1
            MOVEQ    #-1,D3
            MOVE.L   PKTCHAN(A6),A0
            QDOS     FS.POSAB
            TST.L    D0
            BNE      UNPK_IO
         ENDIF
         CLR.W    PKTMSG(A6)
         CLR.W    HPOS(A6)
         MOVEQ    #0,D7
MSG_LOOP MOVEQ    #0,D1
         MOVEQ    #-1,D3
         MOVE.L   PKTCHAN(A6),A0
         QDOS     FS.POSRE
         SUB.L    D7,D1
         MOVE.L   D1,PKTPOS(A6)
         LEA      BUFFER(A6),A1
         MOVEQ    #2,D2
         BSR      GETS_PKT
         BNE.S    UNPK_EOF
         MOVE.W   -(A1),D0
         BEQ.S    UNPK_DEL
         ROL.W    #8,D0
         SUBQ.W   #PKTVERS,D0
         BNE.S    UNPK_BP
         BSR      UNPK_MSG
         TST.L    D0
         BEQ      MSG_LOOP
UNPK_EOF CMPI.L   #ERR.EF,D0
         BNE.S    PKTERROR
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Short packet!',LF}
UNPK_DEL MOVE.L   PKTCHAN(A6),A0
         QDOS     IO.CLOSE
         MOVEQ    #0,D0
         RTS
UNPK_BP  MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Bad packet!',LF}
         MOVEQ    #ERR.BP,D0
         BRA.S    REN_PKT
PKTERROR MOVE.L   D0,-(A7)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'Packet I/O Error: '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
REN_PKT  MOVE.L   D0,-(A7)
         MOVEQ    #14,D2
         MOVEQ    #-1,D3
         MOVE.L   PKTCHAN(A6),A0
         LEA      BUFFER(A6),A1
         QDOS     FS.HEADR
         SUBA.W   D1,A1
         MOVE.L   PKTPOS(A6),6(A1)
         QDOS     FS.HEADS
         QDOS     IO.CLOSE
         MOVE.L   (A7)+,D0
ERR_RTS  RTS

UNPK_MSG LEA      MSGHDR(A6),A1
         MOVEQ    #MS_TOUSR/4-1,D0
CLRMSGHD CLR.L    (A1)+
         DBF      D0,CLRMSGHD
         LEA      BUFFER+2(A6),A1
         MOVEQ    #12,D2
         BSR      GETS_PKT
         BNE      ERR_RTS
         MOVEQ    #20,D2
         BSR      GET0_PKT
         BLT      ERR_RTS
         MOVE.W   D0,D4
         MOVEQ    #36,D2
         BSR      GET0_PKT
         BLT      ERR_RTS
         OR.W     D0,D4
         MOVEQ    #36,D2
         BSR      GET0_PKT
         BLT      ERR_RTS
         OR.W     D0,D4
         MOVEQ    #72,D2
         BSR      GET0_PKT
         BLT      ERR_RTS
         OR.W     D0,D4
         MOVE.W   #32*1024,D2
         BSR      GET0_PKT
         IF LT THEN
            CLR.B    (A1)+
         ENDIF
         OR.W     D0,D4
         MOVE.L   A1,MSGEND(A6)
         LEA      BUFFER+2(A6),A1
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         MOVE.W   D0,MSGHDR+MS_ONODE(A6)
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         MOVE.W   D0,MSGHDR+MS_DNODE(A6)
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         MOVE.W   D0,MSGHDR+MS_ONET(A6)
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         MOVE.W   D0,MSGHDR+MS_DNET(A6)
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         ANDI.W   #MS.PKMSK,D0
         MOVE.W   D0,MSGHDR+MS_ATTR(A6)
         MOVE.W   (A1)+,D0
         ROL.W    #8,D0
         MOVE.W   D0,MSGHDR+MS_COST(A6)
         BSR      READDATE
         MOVE.L   D1,MSGHDR+MS_DATE(A6)
         LEA      MSGHDR+MS_TOUSR(A6),A2
         BSR      COPYCSTR
         BSR      COPYCSTR
         MOVE.L   A1,MSGSUBJ(A6)
         MOVE.L   A2,SUBJECT(A6)
         BSR      COPYCSTR
         MOVE.L   A2,D0
         SUB.L    A6,D0
         SUBI.W   #MSGHDR,D0
         MOVE.W   D0,MSGHDRLN(A6)
         MOVE.L   A1,MSGPTR(A6)
         TST.W    D4
         BNE.S    USE_BADM
         SUBA.L   A4,A4
FINDAREA TST.B    (A1)
         BEQ.S    UM_EMPTY
         LOAD$    {'AREA:'},A0
         BSR      COMPSTR1
         BEQ.S    A_FOUND
         CMPI.B   #1,(A1)
         BNE.S    UM_NET
         BSR      SKP_PARA
         BRA      FINDAREA
A_FOUND  JSR      SKIPSPC
         BEQ.S    USE_BADM
         LEA      AREALIST(A6),A4
CMP_AREA MOVE.L   (A4),D0
         BEQ.S    USE_BADM
         MOVE.L   D0,A4
         LEA      AR_ANAME(A4),A0
         JSR      COMPSTR
         BNE      CMP_AREA
         MOVE.L   A1,MSGPTR(A6)
         BRA.S    UM_ECHO
USE_BADM MOVE.L   AR_BAD(A6),A4
         MOVE.L   A4,D0
         BEQ      UM_RMSG2
         BRA.S    UM_ECHO
UM_EMPTY TST.B    KEEPNULL(A6)
         BEQ      UM_RMSG2
UM_NET   MOVE.L   AR_NET(A6),A4
         BRA.S    UM_AREA
UM_ECHO  BSR      FINDSNBY
UM_AREA  MOVE.W   LASTAREA(A6),D0
         CMP.W    AR_ANUM(A4),D0
         BEQ      UM_RMSG
         TST.W    D0
         BEQ.S    UM_OPEN
         BSR      CL_AREA
UM_OPEN  LEA      AR_ANAME(A4),A1
         MOVE.W   (A1)+,D0
         ADDQ.W   #1,D0
         BCLR     #0,D0
         ADDA.W   D0,A1
         LEA      MSG_FNAM,A0
         LEA      FNAMBUF(A6),A2
         JSR      MAKEFNAM
         BNE.S    UM_OERR
         MOVEQ    #-1,D1
         MOVEQ    #IO.EXCL,D3
         QDOS     IO.OPEN
         TST.L    D0
         BEQ      UM_NMSG
         CMPI.L   #ERR.NF,D0
         BNE.S    UM_OERR
         MOVEQ    #-1,D1
         MOVEQ    #IO.NEW,D3
         LEA      FNAMBUF(A6),A0
         QDOS     IO.OPEN
         TST.L    D0
         BNE.S    UM_OERR
         MOVEQ    #-1,D3
         MOVEQ    #0,D1
         QDOS     IO.SBYTE
         TST.L    D0
         BNE.S    UM_OERR2
         MOVE.W   #4*255,D2
UM_CREAT MOVEQ    #-1,D1
         QDOS     IO.SBYTE
         TST.L    D0
         BNE.S    UM_OERR2
         SUBQ.W   #1,D2
         BGT      UM_CREAT
         BRA.S    UM_NMSG

UM_OERR2 MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         MOVEQ    #-1,D1
         LEA      FNAMBUF(A6),A0
         QDOS     IO.DELET
         MOVE.L   (A7)+,D0
UM_OERR  MOVE.L   D0,-(A7)
         LOAD$    {LF,'*** ERROR: Unable to open message area #'},A1
         BRA.S    UM_MBERR
IMP_IO   MOVE.L   D0,-(A7)
         MOVE.L   D5,D1
         QDOS     FS.TRUNC
         MOVE.L   (A7)+,D0
UM_IOERR MOVE.L   D0,-(A7)
         QDOS     IO.CLOSE
         LOAD$    {LF,'*** ERROR: File I/O Error message area #'},A1
UM_MBERR MOVE.L   CONCHAN(A6),A0
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVE.W   LASTAREA(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' ('}
         LEA      FNAMBUF(A6),A1
         JSR      (A2)
         PRINT    {'): '}
         MOVE.L   (A7)+,D0
         JMP      UT_ERR

UM_NMSG  MOVE.W   AR_ANUM(A4),LASTAREA(A6)
         MOVE.L   A0,LASTACHN(A6)
UM_RMSG  MOVE.L   LASTACHN(A6),A0
         MOVEQ    #0,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         TST.L    D0
         BNE      UM_IOERR
         QDOS     IO.FBYTE
         TST.L    D0
         BNE      UM_IOERR
         MOVEQ    #0,D6
         MOVE.B   D1,D6
         ADDQ.B   #1,D6
         BCC.S    UM_RMSG2
         QDOS     IO.CLOSE
         CLR.W    LASTAREA(A6)
         MOVE.L   CONCHAN(A6),A0
         PRINT    {LF,'*** ERROR: Message area full (#'}
         MOVE.W   LASTAREA(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {')',LF}
         MOVEQ    #ERR.OR,D0
UM_R_RTS RTS

UM_RMSG2 MOVEQ    #0,D3
         MOVE.L   CONCHAN(A6),A0
         MOVE.W   HPOS(A6),D1
         BNE.S    UM_RMSG3
         LEA      PKTFNAME(A6),A1
         MOVE.W   (A1)+,D2
         QDOS     IO.SSTRG
         MOVEQ    #':',D1
         QDOS     IO.SBYTE
         SUBQ.W   #8,A7
         MOVE.L   A7,A1
         QDOS     SD.CHENQ
         MOVE.W   4(A7),D1
         ADDQ.W   #8,A7
         TST.L    D0
         BNE.S    UM_RMSG3
         MOVE.W   D1,HPOS(A6)
UM_RMSG3 QDOS     SD.TAB
         ADDQ.W   #1,PKTMSG(A6)
         MOVE.W   PKTMSG(A6),D1
         MOVEQ    #0,D2
         MOVE.L   MSGEND(A6),A1
         JSR      ITOD_W
         WRITE$   {' ==> '},A1
         MOVE.L   A4,D0
         BEQ.S    UM_RMSG4
         LEA      AR_ANAME(A4),A0
         WRITE$
         MOVE.B   #':',-1(A1)
         MOVE.W   D6,D1
         JSR      ITOD_W
         BRA.S    UM_RMSG5
UM_RMSG4 WRITE$   {'killed'},A1
UM_RMSG5 MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         MOVE.L   MSGEND(A6),A1
         SUB.L    A1,D2
         MOVEQ    #0,D3
         MOVE.L   CONCHAN(A6),A0
         QDOS     IO.SSTRG
         QDOS     SD.CLRRT
         MOVE.L   A4,D0
         BEQ      UM_R_RTS

         MOVE.L   MSGPTR(A6),A1
         MOVE.L   A1,A2
         BRA.S    LOOK_KL
SKIPLF   ADDQ.W   #1,A1
LOOK_KL  CMPA.L   ECHOINFO(A6),A1
         IF EQ THEN
            MOVE.L   A2,ECHOINFO(A6)
         ENDIF
         MOVE.B   (A1),D1
         BEQ      IMP_END
         CMPI.B   #LF,D1
         BEQ      SKIPLF
         CMPI.B   #SOFTCR,D1
         BEQ      SKIPLF
         SUBQ.B   #1,D1
         BNE      IMP_CHR
         MOVE.L   A1,A3
         LOAD$    {1,'MSGID:'},A0
         JSR      COMPSTR
         BNE.S    LK2
         JSR      SKIPSPC
         MOVEM.W  MSGHDR+MS_OZONE(A6),D2-D4
         JSR      A2ZNNP
         BNE      KL_ERR
         MOVEM.W  D2-D5,MSGHDR+MS_OZONE(A6)
         BRA.S    KL_ERR
LK2      CMPA.L   AR_NET(A6),A4
         BNE.S    IMP_CHR
         LOAD$    {1,'FMPT'},A0
         JSR      COMPSTR
         BNE.S    LK3
         JSR      SKIPSPC
         JSR      READNUM
         BNE.S    KL_ERR
         MOVE.W   D1,MSGHDR+MS_OPNT(A6)
         BRA.S    KL_END
LK3      LOAD$    {1,'TOPT'},A0
         JSR      COMPSTR
         BNE.S    LK4
         JSR      SKIPSPC
         JSR      READNUM
         BNE.S    KL_ERR
         MOVE.W   D1,MSGHDR+MS_DPNT(A6)
         BRA.S    KL_END
LK4      LOAD$    {1,'INTL'},A0
         JSR      COMPSTR
         BNE.S    IMP_CHR
         JSR      SKIPSPC
         MOVEM.W  MSGHDR+MS_DZONE(A6),D2-D4
         JSR      A2ZNNP
         BNE.S    KL_ERR
         MOVEM.W  D2-D4,MSGHDR+MS_DZONE(A6)
         JSR      SKIPSPC
         MOVEM.W  MSGHDR+MS_OZONE(A6),D2-D4
         JSR      A2ZNNP
         BNE.S    KL_ERR
         MOVEM.W  D2-D4,MSGHDR+MS_OZONE(A6)
KL_END   TST.B    (A1)
         BEQ.S    IMP_EN2
         CMPI.B   #CR,(A1)+
         BNE      KL_END
         BRA      LOOK_KL

KL_ERR   MOVE.L   A3,A1
IMP_CHR  MOVE.B   (A1)+,D1
         BEQ.S    IMP_EN2
         CMPI.B   #SOFTCR,D1
         BEQ.S    IMP_CHR
         CMPI.B   #LF,D1
         BEQ.S    IMP_CHR
         MOVE.B   D1,(A2)+
         CMPI.B   #CR,D1
         BNE      IMP_CHR
         BRA      LOOK_KL

IMP_EN2  MOVE.B   #CR,(A2)+
IMP_END  CMP.L    AR_NET(A6),A4
         BNE      IMP_SAVE
         MOVEM.W  MYZONE(A6),D2-D5
         LEA      MSGHDR+MS_DZONE(A6),A1
         BSR      CMP_ADDR
         BEQ      IMP_SAVE
         MOVE.W   POINTNET(A6),D3
         BEQ.S    IMP_AKAS
         MOVE.W   D5,D4
         MOVEQ    #0,D5
         BSR      CMP_ADDR
         BEQ      IMP_SAVE
IMP_AKAS LEA      AKAS(A6),A0
         MOVE.W   (A0)+,D1
         BEQ.S    IMP_TRNS
IMP_AKA2 MOVEM.W  (A0)+,D2-D5
         BSR      CMP_ADDR
         BEQ.S    IMP_SAVE
         SUBQ.W   #1,D1
         BGT      IMP_AKA2
IMP_TRNS MOVE.W   MSGHDR+MS_ATTR(A6),D1
         BSET     #MS..TRNS,D1
         MOVE.W   D1,MSGHDR+MS_ATTR(A6)
         BTST     #MS..FATT,D1
         BEQ.S    IMP_SAVE
         MOVE.L   MSGSUBJ(A6),A3
         MOVE.L   SUBJECT(A6),A1
         ADDQ.W   #1,A1
NXTFSPEC TST.B    (A3)
         BEQ.S    SUBJ_LEN
         CMPI.B   #' ',(A3)
         BNE.S    SUBJ_FL
         ADDQ.W   #1,A3
         BRA      NXTFSPEC
SUBJ_FL  LEA      INBDDIR(A6),A0
         WRITE$
CPYFSPEC TST.B    (A3)
         BEQ.S    SUBJ_LEN
         MOVE.B   (A3)+,D1
         MOVE.B   D1,(A1)+
         CMPI.B   #' ',D1
         BEQ.S    SUBJ_LEN
         CMPI.B   #',',D1
         BNE      CPYFSPEC
SUBJ_LEN MOVE.L   A1,D1
         SUB.L    SUBJECT(A6),D1
         CMPI.W   #72,D1
         BLO.S    SUBJ_NXT
         MOVEQ    #72,D1
         BRA.S    SUBJ_LN2
SUBJ_NXT TST.B    (A3)
         BNE      NXTFSPEC
SUBJ_LN2 MOVE.L   SUBJECT(A6),A0
         SUBQ.W   #1,D1
         MOVE.B   D1,(A0)
         MOVE.L   A1,D1
         SUB.L    A6,D1
         SUBI.W   #MSGHDR,D1
         MOVE.W   D1,MSGHDRLN(A6)

IMP_SAVE CMPA.L   AR_NET(A6),A4
         BEQ.S    IMP_SAV2
         MOVE.L   PKTZONE(A6),MSGHDR+MS_OZONE(A6)
         MOVE.L   PKTNODE(A6),MSGHDR+MS_ONODE(A6)
         MOVE.L   ECHOINFO(A6),D1
         SUB.L    MSGPTR(A6),D1
         MOVE.W   #-1,MSGHDR+MS_DZONE(A6)
         MOVE.W   D1,MSGHDR+MS_DNET(A6)
         CLR.W    MSGHDR+MS_DNODE(A6)
IMP_SAV2 MOVE.L   #9999999,D1
         MOVEQ    #-1,D3
         MOVE.L   LASTACHN(A6),A0
         QDOS     FS.POSAB
         CMPI.L   #ERR.EF,D0
         BNE      UM_IOERR
         MOVE.L   D1,D5
         MOVE.W   MSGHDRLN(A6),D2
         LEA      MSGHDR(A6),A1
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      IMP_IO
         MOVE.L   MSGPTR(A6),A1
         MOVE.L   A2,D1
         SUB.L    A1,D1
         MOVE.W   D1,D2
         ADDQ.W   #2,D2
         MOVE.B   D1,-(A1)
         LSR.W    #8,D1
         MOVE.B   D1,-(A1)
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      IMP_IO
         MOVE.L   D6,D1
         SUBQ.L   #1,D1
         LSL.L    #2,D1
         ADDQ.L   #1,D1
         QDOS     FS.POSAB
         TST.L    D0
         BNE      IMP_IO
         MOVEQ    #4,D2
         MOVE.L   D5,-(A7)
         MOVE.L   A7,A1
         QDOS     IO.SSTRG
         ADDQ.W   #4,A7
         TST.L    D0
         BNE      IMP_IO
         MOVEQ    #0,D1
         QDOS     FS.POSAB
         TST.L    D0
         BNE      IMP_IO
         MOVE.B   D6,D1
         QDOS     IO.SBYTE
         MOVE.L   A2,D1
         SUB.L    MSGPTR(A6),D1
         ADDQ.W   #1,AR_NMSG(A4)
         ADD.L    D1,AR_TOTSZ(A4)
         CMP.W    AR_MINSZ(A4),D1
         BHS.S    UPD_MAX
         MOVE.W   D1,AR_MINSZ(A4)
UPD_MAX  CMP.W    AR_MAXSZ(A4),D1
         BLS.S    UM_OK
         MOVE.W   D1,AR_MAXSZ(A4)
UM_OK    MOVEQ    #0,D0
         RTS

SKP_PARA TST.B    (A1)
         BEQ.S    SKPP_END
         CMPI.B   #CR,(A1)+
         BNE      SKP_PARA
SKP_SK2  TST.B    (A1)
         BEQ.S    SKPP_END
         CMPI.B   #CR,(A1)
         BEQ.S    SKP_SKLF
         CMPI.B   #LF,(A1)
         BEQ.S    SKP_SKLF
         CMPI.B   #SOFTCR,(A1)
         BNE.S    SKPP_END
SKP_SKLF ADDQ.W   #1,A1
         BRA      SKP_SK2
SKPP_END RTS

CMP_ADDR TST.W    (A1)
         BEQ.S    CMPA_NET
         CMP.W    (A1),D2
         BNE.S    CMPA_END
CMPA_NET CMP.W    2(A1),D3
         BNE.S    CMPA_END
         CMP.W    4(A1),D4
         BNE.S    CMPA_END
         CMP.W    6(A1),D5
CMPA_END RTS

BACKPARA MOVEQ    #CR,D0
BP_SKPLF CMPI.B   #LF,-(A2)
         BEQ      BP_SKPLF
         CMP.B    (A2),D0
         BEQ      BP_SKPLF
BP_LOOP  CMPA.L   A3,A2
         BLS.S    BP_START
         CMP.B    -(A2),D0
         BNE      BP_LOOP
         MOVEQ    #0,D0
         ADDQ.W   #1,A2
         BRA.S    BP_SKIP
BP_START MOVEQ    #-1,D0
         MOVE.L   A3,A2
BP_SKIP  CMPI.B   #LF,(A2)
         BNE.S    BP_END
         ADDQ.W   #1,A2
         BRA      BP_SKIP
BP_END   TST.L    D0
         RTS

FINDSNBY MOVEM.L  D1/A0-A3,-(A7)
         MOVE.L   MSGEND(A6),A2
         MOVE.L   A2,ECHOINFO(A6)
         MOVE.L   MSGPTR(A6),A3
IMP_FCR  BSR      BACKPARA
         BNE.S    FS_END
         LOAD$    {'SEEN-BY:'},A0
         MOVE.L   A2,A1
         JSR      COMPSTR1
         BNE      IMP_FCR
SNBYLOOP MOVE.L   A2,ECHOINFO(A6)
         BSR      BACKPARA
         BNE.S    FS_END
         LOAD$    {'SEEN-BY:'},A0
         MOVE.L   A2,A1
         JSR      COMPSTR1
         BEQ      SNBYLOOP
FS_END   MOVEM.L  (A7)+,D1/A0-A3
         RTS

REPORT   TST.B    NOLOG(A6)
         BNE      REP_END
         LEA      AREALIST(A6),A4
REP_NEXT MOVE.L   (A4),D0
         BEQ      REP_END
         MOVE.L   D0,A4
         TST.W    AR_NMSG(A4)
         BEQ      REP_NEXT
         LEA      BUFFER(A6),A1
         MOVEQ    #62,D0
FILL_SPC MOVE.B   #' ',(A1)+
         DBF      D0,FILL_SPC
         LEA      BUFFER(A6),A1
         QDOS     MT.RCLCK
         JSR      GETDATE
         MOVE.L   D2,D5
         MOVE.L   D3,D6
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         JSR      ITOD_W
         MOVE.B   #'-',(A1)+
         MOVE.W   D0,D1
         ADDQ.W   #1,D1
         JSR      ITOD_W
         MOVE.B   #' ',(A1)+
         SWAP     D5
         MOVE.W   D5,D1
         JSR      ITOD_W
         MOVE.B   #':',(A1)+
         MOVE.W   D6,D1
         JSR      ITOD_W
         ADDQ.W   #2,A1
         MOVE.W   AR_ANUM(A4),D1
         MOVEQ    #3,D2
         MOVEQ    #' ',D3
         JSR      ITOD_W
         ADDQ.W   #1,A1
         LEA      AR_ANAME(A4),A0
         MOVE.W   (A0)+,D0
         SUBQ.W   #1,D0
         CMPI.W   #12,D0
         BLE.S    DSP_AREA
         MOVEQ    #12,D0
DSP_AREA MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D0
         BGT      DSP_AREA
         LEA      BUFFER+31(A6),A1
         MOVE.W   AR_NMSG(A4),D1
         MOVEQ    #4,D2
         JSR      ITOD_W
         ADDQ.W   #2,A1
         MOVE.W   AR_MINSZ(A4),D1
         MOVEQ    #5,D2
         JSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.L   AR_TOTSZ(A4),D1
         DIVU     AR_NMSG(A4),D1
         JSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.W   AR_MAXSZ(A4),D1
         JSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.L   AR_TOTSZ(A4),D1
         MOVEQ    #7,D2
         JSR      ITOD_L
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #-1,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     IO.SSTRG
         BRA      REP_NEXT
REP_END  RTS

         END
