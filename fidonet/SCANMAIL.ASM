*                 QBoss ECHOMAIL SYSTEM
*                 ---------------------
*
* SCANMAIL - Echomail Packer
* --------------------------
*
* Copyright (C) 1989, 90 by Jan Bredenbeek, Hilversum, Holland.
*
* v1.01b - June 19, 1990
*
* - -POINTNODE= command removed (redundant)
* - "Sysop" always replaced with sysop name, even when used as point
* - Product code in packet now correctly set ($54)
* - Added support for individual Origin-lines for each area (ORIGIN_BBS)
* - ARCmail packet numbering now starts at 0 rather than 1
* - Quoted kludge lines don't get exported now
* - Invalid commands in ECHOCTL_BBS now ignored
*
* v1.00 - September 4, 1989
*
* Bug causing incorrect second SEEN-BY lines (e.g. SEEN-BY: 1 2 3) fixed.
*
* v1.00C (Gamma) - August 12, 1989
*
* Bug in EXPORT_2 fixed - caused sometimes failure to display ">" qoutes in
* message text.
*
* v1.00B (Beta) - August 11, 1989
*
* SCANARC module added - compresses _PKT files into ARCmail-compatible packets.
*
* v0.90 - July 8, 1989
*
* Major rewrite:
* - Point configuration now possible
* - New -OUTBOUND=, -TEMPDIR=, -POINTNET=, -POINTNODE= and AKA commands
* - Pointnet entries stripped from SEEN-BY lines in exported message
* - PATH line entries now in form <net/node> rather than <zone:net/node>
* - Message files are handled more efficiently
*
* v0.03 - March 21, 1989
*
* - Wrong month number in packet header fixed
* - SEEN-BY list now sorted
*
* v0.02 - February 26, 1989
*
* Wrong SEEN-BY pointer in stored message fixed - use FIXMSG001 to correct
* already "damaged" message files.
*
* v0.01 - February 25, 1989
*
* First release version
*
* Start of programming work: 13th February 1989

version  SETSTR   1.19a

         INCLUDE  FLP1_QDOS_IN_MAC

* Constants

CR       EQU      $0D
LF       EQU      $0A
QON      EQU      $1E
QOFF     EQU      $1F

FTSCPROD EQU      $54      FTSC Product code for QBoxMail

MAX_AKA  EQU      8        Maximum AKA net/node numbers
MAXFWD   EQU      64       Maximum number of forwarding nodes
MAXSBY   EQU      256      Maximum number of SEEN-BY nodes
MAXPATH  EQU      256      Maximum number of PATH nodes

* Stored message offsets

MS_DATE  EQU      0        Date & time of entry (QDOS format)
MS_OZONE EQU      4        Origination zone
MS_ONET  EQU      6                    net
MS_ONODE EQU      8                    node
MS_OPNT  EQU      10                   point
MS_DZONE EQU      12       Destination zone (or -1 if Echomail msg)
MS_DNET  EQU      14       Dest. net (or ptr to SEEN-BY lines)
MS_DNODE EQU      16       Dest. node (or ptr to product banner)
MS_DPNT  EQU      18       Dest. point
MS_ATTR  EQU      20       Attribute bits
MS_COST  EQU      22       Cost
MS_REPTO EQU      24       Msg # to which this msg replies
MS_NXREP EQU      25       Msg # which is reply to this msg
MS_NREAD EQU      26       Times read
MS_RSDAT EQU      28       Update date & time
MS_TOUSR EQU      32       Start of TOUSER field

* MS_ATTR flags

MS..PRIV EQU      0        Private
MS..RECD EQU      2        Received
MS..SENT EQU      3        Sent
MS..FATT EQU      4        File attached
MS..TRNS EQU      5        In transit
MS..ORPH EQU      6        Orphan
MS..KSNT EQU      7        KillSent
MS..LOC  EQU      8        Local
MS.PKMSK EQU      1+(1<<1)+(1<<4)+(1<<10)+(1<<12)+(1<<13)+(1<<14)
*                          Mask for packing
MAXAREA  EQU      32       Highest possible message area

* Forwarding node entry in forwarding nodes table

         OFFSET   0

FN_ZONE  DS.W     1
FN_NETNR DS.W     1        Net number
FN_NODE  DS.W     1        Node number
FN_POINT DS.W     1
FN_FORWD DS.B     1        Forward this message or not
FN_NMSG  DS.B     1        Number of messages exported
FN_MINSZ DS.W     1        Minimum message length
FN_MAXSZ DS.W     1        Maximum message length
FN_CHAN  DS.L     1        ID of output channel
FN_OLDLN DS.L     1        Old packet file EOF position
FN_LEN   EQU      *

* Variable storage

         OFFSET   0

CTLCHAN  DS.L     1        ID of control file channel
LOGCHAN  DS.L     1        ID of logfile channel
MAREACHN DS.L     1        ID of MAREAS_BBS file channel
MSG_CHAN DS.L     1        ID of MESSAGES_BBS file channel
ORIGCHAN DS.L     1        ID of ORIGIN_BBS channel (<0 if absent)
TDIRCHAN DS.L     1        Temporary directory channel
INPCHAN  DS.L     1        ARCer input channel
OUTCHAN  DS.L     1        ARCer output channel
ERR_SP   DS.L     1        Error stackpointer
MSG_FRST DS.L     1        Position in msg file of first msg examined
MSG_BASE DS.L     1        Base of message file buffer
MSG_END  DS.L     1        End of used message file buffer
MSG_MAX  DS.L     1        End of message file buffer
MYZONE   DS.W     1        Boss zone
MYNET    DS.W     1        Boss net
MYNODE   DS.W     1        Boss node
PNTNET   DS.W     1        "Fake" pointnet
MYPOINT  DS.W     1        Point number (0 if node)
AKAS     DS.W     1+2*MAX_AKA
MINSPACE DS.W     1        Minimum disk space required
MAXMSGS  DS.W     1        Forwarding msg counter
AREANR   DS.B     1        QBOX msg area number
MAXMSG   DS.B     1        Number of highest msg
NOPRIV   DS.B     1        Inhibit forwarding of private msg (<>0) or not (0)
NOFORWD  DS.B     1        Inhibit forwarding of alien msg (<>0) or not (0)
NOLOG    DS.B     1        Make log (0) or not (<>0)
NOARC    DS.B     1        ARC packet files (0) or not (<>0)
MSGUPDAT DS.B     1        Message area file updated (<>0) or not (0)
         DS.W     0        Next areas must start on even address
HD_AREA  DS.B     14       File header of msg area file
MSGPNT   EQU      HD_AREA+9 Byte containing last msg scanned
FWDNODES DS.B     2+MAXFWD*FN_LEN  Table of forwarding nodes
SBYNODES DS.B     2+MAXSBY*4  Table of SEEN-BY nodes
PATNODES DS.B     2+MAXPATH*4 Table of PATH nodes
SYSDIR   DS.B     2+48     System directory name
TEMPDIR  DS.B     2+48
DESTDIR  DS.B     2+48     Destination directory for output files
LOGFILE  DS.B     2+48     Name of log file
DEF_ORIG DS.B     2+80     Default "* Origin" line
ORIGINLN DS.B     2+80     Origin line in use
SYSOPNAM DS.B     2+50     Name of this node's sysop
AREANAME DS.B     2+50     Name of msg area
POINTERS DS.L     255      Buffer for pointers of msg file
BUFFER   DS.B     2048     General buffer area & SEEN-BY lines buffer
BUFFER2  DS.B     256      Buffer used during export
MSGBUF   DS.B     32768

         XDEF     MYZONE,MYNET,MYNODE,MYPOINT,PNTNET,NOARC,ERR_SP
         XDEF     TEMPDIR,DESTDIR,BUFFER,BUFFER2,TDIRCHAN,INPCHAN,OUTCHAN

         XREF     COMP_ALL

         DATA     8*1024

         SECTION  CODE

START    JMP      JOBSTART
         DS.B     6-(*-START)
         DC.W     $4AFB
         STRING$  {'SCANMAIL'}

CTLFNAME STRING$  'ECHOCTL_BBS'
AREAFNAM STRING$  'MAREAS_BBS'
MSG_FNAM STRING$  'MESSAGES_BBS'
ORG_FNAM STRING$  'ORIGIN_BBS'
LOG_FNAM DC.B     'SCANLOG_BBS'
AREA     STRING$  {'AREA:'}
PRODINFO STRING$  {CR,'--- QBoxMail v[version]',CR}
ORIGIN   STRING$  {' * Origin: '}
SEEN_BY  STRING$  {'SEEN-BY:'}
PATH     STRING$  {1,'PATH:'}
NOECHO   STRING$  {'NOECHO',CR}
SYSOP    DC.B     5,'Sysop'
OPTLIST  DC.W     NOLOG
         DC.B     '-NOLOG',0
         DC.W     NOPRIV
         DC.B     '-NOPRIV',0
         DC.W     NOFORWD
         DC.B     '-NOFORWARD',0
         DC.W     NOARC
         DC.B     '-NOARC',0
         DC.W     -MINSPACE
         DC.B     '-MINSPACE',0
         DC.W     -MAXMSGS
         DC.B     '-MAXMSGS',0
         DC.W     0

LD_WORD  MOVE.B   (A1)+,D1
         LSL.W    #8,D1
         MOVE.B   (A1)+,D1
         TST.W    D1
         RTS

         XDEF     LD_LONG

LD_LONG  BSR      LD_WORD
         SWAP     D1
         BSR      LD_WORD
         TST.L    D1
         RTS

STO_WORD ROR.W    #8,D1
         MOVE.B   D1,(A1)+
         ROR.W    #8,D1
         MOVE.B   D1,(A1)+
         RTS

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

* Read nodes from ASCII nodelist
* Entry: D3 max. nr of entries, D4 net nr, A1 ptr to ASCII nodelist, A4 ptr to buffer
* Exit:  D2 number of entries found, D3 updated net nr, A1 and A4 updated

READNODE MOVEQ    #4,D5
RDNODE_2 MOVEQ    #0,D2
RL_NEXT  BSR      SKIPSPC
         BEQ.S    RL_END
         BSR      READNUM
         BNE.S    RL_END
         CMPI.B   #' ',(A1)
         BEQ.S    RL_NODE
         CMPI.B   #CR,(A1)
         BEQ.S    RL_NODE
         CMPI.B   #LF,(A1)
         BEQ.S    RL_NODE
         CMPI.B   #'/',(A1)+
         BNE.S    RL_ERR
         MOVE.W   D1,D4
         BSR      READNUM
         BNE.S    RL_END
RL_NODE  CMP.W    D3,D2
         BGE.S    RL_2MANY
         ADDQ.W   #1,D2
         MOVE.W   D4,(A4)
         MOVE.W   D1,2(A4)
         ADDA.W   D5,A4
         BRA      RL_NEXT
RL_ERR   MOVEQ    #ERR.XP,D0
         BRA.S    RL_END
RL_2MANY MOVEQ    #1,D0
RL_END   RTS

DATE$    MOVEM.L  D1-D6/A2,-(A7)
         JSR      GETDATE
         MOVE.L   D2,D5
         MOVE.L   D3,D6
         MOVEQ    #2,D2
         MOVEQ    #'0',D3
         JSR      ITOD_W
         MOVEQ    #' ',D4
         MOVE.B   D4,(A1)+
         LEA      MONTHTBL,A2
         ADDA.W   D0,A2
         ADD.W    D0,D0
         ADDA.W   D0,A2
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   (A2)+,(A1)+
         MOVE.B   D4,(A1)+
         MOVEQ    #0,D1
         MOVE.W   D5,D1
         DIVU     #100,D1
         SWAP     D1
         JSR      ITOD_W
         MOVE.B   D4,(A1)+
         MOVE.B   D4,(A1)+
         SWAP     D5
         MOVE.W   D5,D1
         JSR      ITOD_W
         MOVEQ    #':',D4
         MOVE.B   D4,(A1)+
         MOVE.W   D6,D1
         JSR      ITOD_W
         MOVE.B   D4,(A1)+
         SWAP     D6
         MOVE.W   D6,D1
         JSR      ITOD_W
         MOVEM.L  (A7)+,D1-D6/A2
         RTS

         XDEF     OPEN_2,OPEN_3,MKFNAME

OPENSYS  LEA      SYSDIR(A6),A1
OPEN_2   BSR.S    MKFNAME
OPEN_3   MOVEM.L  D3/A0,-(A7)
OPEN3_LP MOVEQ    #-1,D1
         MOVEM.L  (A7),D3/A0
         QDOS     IO.OPEN
         CMPI.L   #ERR.IU,D0
         BNE.S    OPEN_END
         MOVEQ    #-1,D1
         MOVEQ    #50,D3
         SUBA.L   A1,A1
         QDOS     MT.SUSJB
         BRA      OPEN3_LP
OPEN_END ADDQ.W   #8,A7
         TST.L    D0
         RTS

MKFNAME  LEA      BUFFER(A6),A2
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
         LEA      BUFFER(A6),A0
         RTS

* Open or create packet file
* Entry: D1 net number (high word) and node number (low word)
* Exit: D0 error code, A0 channel ID

OPEN_PKT MOVEM.L  D1-D5/A1,-(A7)
         MOVE.L   A7,A0
         SUBA.W   #14,A7
         MOVE.L   #'_PKT',-(A0)
         MOVEQ    #7,D2
OP_LOOP  MOVEQ    #$0F,D0
         AND.B    D1,D0
         CMPI.B   #9,D0
         BLS.S    OP_NOADD
         ADDQ.B   #7,D0
OP_NOADD ADDI.B   #'0',D0
         MOVE.B   D0,-(A0)
         LSR.L    #4,D1
         DBF      D2,OP_LOOP
         MOVE.W   #12,-(A0)
         MOVEQ    #IO.EXCL,D3
         LEA      TEMPDIR(A6),A1
         TST.B    NOARC(A6)
         BEQ.S    OP_OPEN
         LEA      DESTDIR(A6),A1
OP_OPEN  BSR      OPEN_2
         BEQ      OP_MARK
         CMPI.L   #ERR.NF,D0
         BNE      OP_END
         MOVEQ    #IO.NEW,D3
         LEA      BUFFER(A6),A0
         BSR      OPEN_3
         BNE      OP_END
         LEA      BUFFER(A6),A1
         MOVEQ    #$3C,D0
CLR_PKHD CLR.L    (A1)+
         SUBQ.W   #4,D0
         BGT      CLR_PKHD
         MOVE.L   A0,-(A7)
         QDOS     MT.RCLCK
         MOVE.L   (A7)+,A0
         BSR      GETDATE
         LEA      BUFFER(A6),A1
         MOVE.L   MYNET(A6),D4
         TST.W    MYPOINT(A6)
         BEQ.S    OP_GDEST
         MOVE.L   PNTNET(A6),D4
OP_GDEST MOVE.L   14(A7),D5
         ROL.W    #8,D4
         ROL.W    #8,D5
         MOVE.W   D4,(A1)
         MOVE.W   D5,2(A1)
         ROL.W    #8,D2
         MOVE.W   D2,4(A1)
         MOVE.B   D0,6(A1)
         MOVE.B   D1,8(A1)
         SWAP     D2
         MOVE.B   D2,10(A1)
         MOVE.B   D3,12(A1)
         SWAP     D3
         MOVE.B   D3,14(A1)
         ADDQ.B   #2,18(A1)
         SWAP     D4
         ROL.W    #8,D4
         SWAP     D5
         ROL.W    #8,D5
         MOVE.W   D4,20(A1)
         MOVE.W   D5,22(A1)
         MOVE.B   #FTSCPROD,24(A1)
         MOVEQ    #$3C,D2
         MOVEQ    #-1,D3
         QDOS     IO.SSTRG
         MOVE.L   D0,D4
         BEQ.S    OP_BACK
         QDOS     IO.CLOSE
         MOVE.L   D4,D0
         BRA.S    OP_END
OP_MARK  MOVE.L   #999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
OP_BACK  MOVEQ    #-2,D1
         QDOS     FS.POSRE
OP_END   ADDA.W   #18,A7
         MOVEM.L  (A7)+,D2-D5/A1
         TST.L    D0
         RTS

LBYTES   MOVEQ    #IO.FSTRG&$FF,D4
         BRA.S    LSBYTES
SBYTES   MOVEQ    #IO.SSTRG&$FF,D4
LSBYTES  MOVE.L   D2,-(A7)
         CMPI.L   #$7FFE,D2
         BLS.S    LSB_2
         MOVE.L   #$7FFE,D2
LSB_2    MOVE.B   D4,D0
         MOVEQ    #-1,D3
         TRAP     #3
         MOVE.L   (A7)+,D2
         TST.L    D0
         BNE.S    LSB_END
         ANDI.L   #$7FFF,D1
         SUB.L    D1,D2
         BHI      LSBYTES
LSB_END  TST.L    D0
         RTS

COPYSTR  MOVE.W   (A1)+,D1
COPYSTR2 MOVE.B   (A1)+,(A2)+
         SUBQ.W   #1,D1
         BGT      COPYSTR2
         RTS

COPYPARA MOVE.B   (A1)+,D1
         MOVE.B   D1,(A2)+
         CMPI.B   #CR,D1
         BNE      COPYPARA
         RTS

LOOK_SBY LEA      SBYNODES(A6),A1
         MOVE.W   (A1)+,D0
         SUBQ.W   #1,D0
         BLT.S    LSBY_NF
LSBY_LP  CMP.L    (A1)+,D1
         DBEQ     D0,LSBY_LP
         BEQ.S    LSBY_FND
LSBY_NF  CMPI.W   #MAXSBY,SBYNODES(A6)
         BGE.S    LSBY_FUL
         MOVE.L   D1,(A1)
         ADDQ.W   #1,SBYNODES(A6)
         MOVEQ    #ERR.NF,D0
         RTS
LSBY_FND MOVEQ    #0,D0
         RTS
LSBY_FUL MOVEQ    #1,D0
         RTS

CMD_TBL  DC.W     DO_OUTB-*
         STRING$  'OUTBOUND='
         DC.W     DO_TMPDR-*
         STRING$  'TEMPDIR='
         DC.W     POINTNET-*
         STRING$  'POINTNET='
         DC.W     DO_AKA-*
         STRING$  'AKA'
         DC.W     0

POINTNET BSR      READNUM
         BNE.S    CTL6ERR
         MOVE.W   D1,PNTNET(A6)
         RTS

DO_AKA   MOVEQ    #MAX_AKA,D3
         MOVE.W   MYNET(A6),D4
         LEA      AKAS+2(A6),A4
         BSR      READNODE
         BLT.S    CTL6ERR
         BGT.S    CTL7ERR
         MOVE.W   D2,AKAS(A6)
         RTS
CTL7ERR  MOVEQ    #ERR.OR,D0
         LEA      CTL7MSG,A1
         BRA      ERR_EXIT

DO_OUTB  LEA      DESTDIR(A6),A0
         BRA.S    DO_DIR
DO_TMPDR LEA      TEMPDIR(A6),A0
DO_DIR   BSR.S    GETDIR
         BNE.S    CTL6ERR
         RTS
CTL6ERR  LEA      CTL6MSG,A1
         BRA      ERR_EXIT

JOBSTART ADDA.L   A4,A6
         CLR.L    LOGCHAN(A6)
         MOVE.W   (A7),D0
         LSL.W    #2,D0
         LEA      2(A7,D0.W),A0
         MOVE.W   (A0)+,D1
         BEQ      BADCMDLN
         CMPI.W   #512,D1
         BHI      BADCMDLN
         LEA      BUFFER(A6),A1
COPYCMDL MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D1
         BGT      COPYCMDL
         MOVE.B   #LF,(A1)+
         MOVE.W   #50,MINSPACE(A6)
         MOVE.W   #100,MAXMSGS(A6)
         MOVE.W   #-1,PNTNET(A6)
         CLR.W    AKAS(A6)
         CLR.W    DESTDIR(A6)
         CLR.W    TEMPDIR(A6)
         SF       NOPRIV(A6)
         SF       NOFORWD(A6)
         SF       NOLOG(A6)
         SF       NOARC(A6)
         LEA      BUFFER(A6),A1
         LEA      SYSDIR(A6),A0
         BSR      GETDIR
         BNE      BAD_FNAM
         TST.W    D1
         BEQ      BAD_FNAM
         LEA      LOGFILE(A6),A0
         BSR      GETDIR
         BNE      BAD_FNAM
         TST.W    D1
         BNE.S    GET_OPT
         LEA      SYSDIR(A6),A2
         MOVE.W   (A2)+,D1
         MOVE.W   D1,(A0)
         ADDI.W   #11,(A0)+
COPYSD2  MOVE.B   (A2)+,(A0)+
         SUBQ.W   #1,D1
         BGT      COPYSD2
         LEA      LOG_FNAM,A2
         MOVEQ    #11,D1
COPYLFN  MOVE.B   (A2)+,(A0)+
         SUBQ.W   #1,D1
         BGT      COPYLFN
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
BADCMDLN LEA      BADCMDMS,A1
         BRA.S    CMD_ERR
BAD_FNAM LEA      BADFNMSG,A1
         BRA.S    CMD_ERR
OPT_ERR  LEA      BADOPTMS,A1
CMD_ERR  MOVEQ    #ERR.BP,D0
         BRA.S    ERR_EXIT
LOG_ERR  LEA      LOGERRMS,A1
         BRA.S    ERR_EXIT
ERR_AROP LEA      AROPMSG,A1
         BRA.S    ERR_EXIT
ERR_ARIO LEA      ARIOMSG,A1
         BRA.S    ERR_EXIT
ERR_OPKT LEA      OPKTMSG,A1
         BRA.S    ERR_EXIT
ERR_OM   LEA      OMMSG,A1
         BRA.S    ERR_EXIT
ERR_BF   LEA      BFMSG,A1
ERR_EXIT MOVE.L   D0,D4
         MOVE.L   A1,A4
         MOVE.L   LOGCHAN(A6),A0
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
         TST.B    NOARC(A6)
         BNE.S    ERR_EX2
         JSR      COMP_ALL
         LEA      CMPERMSG,A1
         BNE      ERR_EXIT
ERR_EX2  MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

         SECTION  MSG
BADCMDMS STRING$  {'SCANMAIL: Command line absent or too long',LF}
BADFNMSG STRING$  {'SCANMAIL: Bad file name in command line',LF}
BADOPTMS STRING$  {'SCANMAIL: Bad option or option parameter',LF}
LOGERRMS STRING$  {'SCANMAIL: Failed to open log file: '}
CTL1MSG  STRING$  {'*** ERROR: Failed to open ECHOCTL_BBS: '}
CTL2MSG  STRING$  {'*** ERROR: I/O error file ECHOCTL_BBS: '}
CTL3MSG  STRING$  {'*** ERROR: Premature end of file ECHOCTL_BBS',LF}
CTL4MSG  STRING$  {'*** ERROR: Bad home node address in ECHOCTL_BBS',LF}
CTL6MSG  STRING$  {'*** ERROR: Bad command parameter in ECHOCTL_BBS',LF}
CTL7MSG  STRING$  {'*** ERROR: Too many AKA nodes specified (>8)',LF}
AROPMSG  STRING$  {'*** ERROR - Failed to open MAREAS_BBS: '}
ARIOMSG  STRING$  {'*** ERROR - I/O error file MAREAS_BBS: '}
OPKTMSG  STRING$  {'*** ERROR - Failed to open packet file: '}
DESTMSG  STRING$  {'*** ERROR - Destination medium error: '}
RSTOMSG  STRING$  {'*** ERROR - Failed to restore message file: '}
OMMSG    STRING$  {'*** ERROR: No room for message buffer',LF}
BFMSG    STRING$  {'*** ERROR: Message buffer overflow',LF}
CMPERMSG STRING$  {'*** ERROR - Failed to compress packets: '}
ANUMMSG  STRING$  {'*** WARNING: Bad message area number',LF}
ANAMMSG  STRING$  {'*** WARNING: Bad message area name',LF}
BADFWMSG STRING$  {'*** WARNING: Bad forwarding node address',LF}
FN2M_MSG STRING$  {'*** WARNING: Too many forwarding nodes (>64)',LF}
SBY1MSG  STRING$  {'*** WARNING: Syntax error in SEEN-BY list area #'}
SBY2MSG  STRING$  {'*** WARNING: Too many SEEN-BY nodes (>256) area #'}
MINSPMSG STRING$  {'*** WARNING: MINSPACE limit exceeded - SCANMAIL aborted',LF}
MAXMSMSG STRING$  {'*** WARNING: MAXMSGS limit exceeded - SCANMAIL aborted',LF}

         SECTION  CODE

OPT_END  TST.B    NOLOG(A6)
         BNE.S    OPEN_CTL
         MOVEQ    #IO.EXCL,D3
         LEA      LOGFILE(A6),A0
         BSR      OPEN_3
         BEQ.S    SET_END
         CMPI.L   #ERR.NF,D0
         BNE      LOG_ERR
         MOVEQ    #IO.NEW,D3
         LEA      LOGFILE(A6),A0
         BSR      OPEN_3
         BNE      LOG_ERR
         PRINT    {'*** QBoss v[version]  (C) 1989 Jan Bredenbeek ***',LF,LF}
         PRINT    {'--- SCANMAIL MESSAGE EXPORT LOG ---',LF,LF}
         PRINT    {'       Date              Area       Net / Node #Msg Minsz Avgsz Maxsz Totsz',LF}
         PRINT    {'------------------- --------------- ---------- ---- ----- ----- ----- -----',LF}
         BRA.S    SETLCHAN
SET_END  MOVE.L   #999999,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
SETLCHAN MOVE.L   A0,LOGCHAN(A6)
OPEN_CTL MOVEQ    #IO.SHARE,D3
         LEA      CTLFNAME,A0
         BSR      OPENSYS
         BNE.S    CTL_OERR
         MOVE.L   A0,CTLCHAN(A6)
         BRA.S    GET_NADD
CTL_OERR LEA      CTL1MSG,A1
         BRA      ERR_EXIT
CTL_IERR LEA      CTL2MSG,A1
         BRA      ERR_EXIT
CTL_EOF  LEA      CTL3MSG,A1
         BRA      ERR_EXIT
CTL_NERR LEA      CTL4MSG,A1
         BRA      ERR_EXIT
GET_CTL  MOVEQ    #-1,D3
         MOVE.L   CTLCHAN(A6),A0
         QDOS     IO.FLINE
         TST.L    D0
         BEQ.S    GCTL_END
         CMPI.L   #ERR.EF,D0
         BNE      CTL_IERR
GCTL_END SUBA.W   D1,A1
         TST.L    D0
         RTS
GET_NADD MOVEQ    #80,D2
         LEA      BUFFER(A6),A1
         BSR      GET_CTL
         BNE      CTL_EOF
         BSR      READNUM
         BNE      CTL_NERR
         MOVE.W   D1,MYZONE(A6)
         CMPI.B   #':',(A1)+
         BNE      CTL_NERR
         BSR      READNUM
         BNE      CTL_NERR
         MOVE.W   D1,MYNET(A6)
         CMPI.B   #'/',(A1)+
         BNE      CTL_NERR
         BSR      READNUM
         BNE      CTL_NERR
         MOVE.W   D1,MYNODE(A6)
         CLR.W    MYPOINT(A6)
         CMPI.B   #'.',(A1)
         BNE.S    GET_NINF
         ADDQ.W   #1,A1
         BSR      READNUM
         BNE      CTL_NERR
         MOVE.W   D1,MYPOINT(A6)
GET_NINF CMPI.B   #LF,(A1)
         BNE      CTL_NERR
         MOVEQ    #80,D2
         LEA      DEF_ORIG+2(A6),A1
         BSR      GET_CTL
         BNE      CTL_EOF
         SUBQ.W   #1,D1
         MOVE.W   D1,-(A1)
         MOVEQ    #50,D2
         LEA      SYSOPNAM+2(A6),A1
         BSR      GET_CTL
         BNE      CTL_EOF
         SUBQ.W   #1,D1
         BNE.S    STO_SLEN
         MOVE.L   #'Syso',(A1)+
         MOVE.L   #'p Of',(A1)+
         MOVE.B   #' ',(A1)+
         BSR      ORIG_ADD
         MOVE.L   A1,D1
         LEA      SYSOPNAM+2(A6),A1
         SUB.L    A1,D1
STO_SLEN MOVE.W   D1,-(A1)
         MOVEQ    #IO.SHARE,D3
         LEA      AREAFNAM,A0
         BSR      OPENSYS
         BNE      ERR_AROP
         MOVE.L   A0,MAREACHN(A6)
         MOVEQ    #-1,D0
         MOVE.L   D0,ORIGCHAN(A6)
         LEA      ORG_FNAM,A0
         BSR      OPENSYS
         BNE.S    NEXTCTLN
         MOVE.L   A0,ORIGCHAN(A6)
NEXTCTLN MOVE.W   #512,D2
         LEA      BUFFER(A6),A1
         BSR      GET_CTL
         BNE      MAIN_END
         MOVE.W   D1,D2
         CMPI.B   #LF,(A1)
         BEQ      NEXTCTLN
         CMPI.B   #' ',(A1)
         BEQ      NEXTCTLN
         CMPI.B   #'*',(A1)
         BEQ      NEXTCTLN
         CMPI.B   #';',(A1)
         BEQ      NEXTCTLN
         CMPI.B   #'-',(A1)
         BNE.S    GET_ANUM
         ADDQ.W   #1,A1
         BSR      DO_CMD
         BRA      NEXTCTLN
GET_ANUM BSR      READNUM
         BNE.S    BAD_ANUM
         MOVE.B   D1,AREANR(A6)
         BSR      SKIPSPC
         BEQ.S    BAD_ANAM
         LEA      AREANAME+2(A6),A0
         MOVEQ    #0,D1
ANAME_LP MOVE.B   (A1)+,D0
         CMPI.B   #LF,D0
         BEQ.S    ANAME_E1
         CMPI.B   #' ',D0
         BEQ.S    ANAME_E2
         CMPI.W   #50,D1
         BGE.S    BAD_ANAM
         MOVE.B   D0,(A0)+
         ADDQ.W   #1,D1
         BRA      ANAME_LP
ANAME_E1 SUBQ.W   #1,A1
ANAME_E2 MOVE.L   A0,D1
         LEA      AREANAME+2(A6),A0
         SUB.L    A0,D1
         MOVE.W   D1,-(A0)
         LEA      FWDNODES+2(A6),A4
         MOVEQ    #MAXFWD,D3
         MOVEQ    #0,D4
         MOVEQ    #FN_LEN,D5
         BSR      RDNODE_2
         BEQ.S    STO_NFWD
         BGT.S    FWD2MANY
BADFNODE LEA      BADFWMSG,A1
         BRA.S    SKP_AREA
BAD_ANUM LEA      ANUMMSG,A1
         BRA.S    SKP_AREA
BAD_ANAM LEA      ANAMMSG,A1
         BRA.S    SKP_AREA
FWD2MANY LEA      FN2M_MSG,A1
SKP_AREA MOVE.L   A1,-(A7)
         MOVE.W   D2,-(A7)
         MOVE.L   LOGCHAN(A6),A0
         PRINT    {'*** '}
         MOVE.W   (A7)+,D2
         LEA      BUFFER(A6),A1
         QDOS     IO.SSTRG
         MOVE.L   (A7)+,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         BRA      NEXTCTLN
STO_NFWD MOVE.W   D2,FWDNODES(A6)
         BEQ      NEXTCTLN
         MOVE.B   AREANR(A6),D4
         MOVE.L   MAREACHN(A6),A0
         MOVEQ    #-1,D3
         MOVEQ    #0,D1
         QDOS     FS.POSAB
         MOVE.W   #256,D2
MAREA_LP LEA      BUFFER+256(A6),A1
         QDOS     IO.FLINE
         CMPI.L   #ERR.EF,D0
         BEQ.S    WAR_AABS
         TST.L    D0
         BNE      ERR_ARIO
         SUBQ.B   #1,D4
         BGT      MAREA_LP
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         BNE.S    GET_ADIR
WAR_AABS MOVE.L   LOGCHAN(A6),A0
         PRINT    {'*** WARNING: Message area #'}
         MOVEQ    #0,D1
         MOVE.B   AREANR(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' absent',LF}
         BRA      NEXTCTLN
GET_ADIR MOVE.L   A1,A0
         MOVEQ    #0,D1
GA_FSPC  CMPI.B   #LF,(A0)
         BEQ.S    OP_MSG
         CMPI.B   #' ',(A0)
         BEQ.S    OP_MSG
         ADDQ.W   #1,A0
         ADDQ.W   #1,D1
         BRA      GA_FSPC
OP_MSG   MOVE.W   D1,-(A1)
         ST       MSG_CHAN+2(A6)
         LEA      MSG_FNAM,A0
         MOVEQ    #IO.EXCL,D3
         BSR      OPEN_2
         BNE      WAR_MBBS
         MOVE.L   A0,MSG_CHAN(A6)
         MOVEQ    #14,D2
         MOVEQ    #-1,D3
         LEA      HD_AREA(A6),A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE      WAR_MBBS
         QDOS     IO.FBYTE
         MOVE.B   D1,MAXMSG(A6)
         MOVE.W   #255*4,D2
         LEA      POINTERS(A6),A1
         QDOS     IO.FSTRG
         TST.L    D0
         BNE      WAR_MBBS
         MOVEQ    #0,D1
         MOVE.B   MSGPNT(A6),D1
         LEA      POINTERS(A6),A1
         MOVE.W   D1,D0
         LSL.W    #2,D0
         ADDA.W   D0,A1
FINDFRST CMP.B    MAXMSG(A6),D1
         BHS      NXT_AREA
         TST.L    (A1)+
         BGE.S    CALC_BUF
         ADDQ.B   #1,D1
         BRA      FINDFRST
CALC_BUF MOVE.B   D1,MSGPNT(A6)
         MOVE.L   -(A1),MSG_FRST(A6)
         MOVEQ    #0,D1
         MOVE.B   MAXMSG(A6),D1
         SUB.B    MSGPNT(A6),D1
         MOVE.L   D1,D0
         MULU     FWDNODES(A6),D1
         LSL.L    #3,D1
         LSL.L    #7,D0
         ADD.L    D0,D1
         MOVE.L   HD_AREA(A6),D0
         SUB.L    MSG_FRST(A6),D0
         ADD.L    D0,D1
         ADDI.L   #1024,D1
         MOVEQ    #-1,D2
         MOVE.L   A0,-(A7)
         QDOS     MT.ALCHP
         MOVE.L   A0,MSG_BASE(A6)
         LEA      -16(A0,D1.L),A0
         MOVE.L   A0,MSG_MAX(A6)
         MOVE.L   (A7)+,A0
         TST.L    D0
         BNE      ERR_OM
         MOVE.L   MSG_FRST(A6),D1
         MOVE.L   HD_AREA(A6),D2
         SUB.L    D1,D2
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVE.L   MSG_BASE(A6),A1
         MOVE.L   A1,MSG_END(A6)
         ADD.L    D2,MSG_END(A6)
         BSR      LBYTES
         BEQ.S    OP_FORWD
         MOVE.L   D0,-(A7)
         MOVE.L   MSG_BASE(A6),A0
         QDOS     MT.RECHP
         MOVE.L   (A7)+,D0
WAR_MBBS MOVE.L   LOGCHAN(A6),A0
         MOVE.L   D0,-(A7)
         PRINT    {'*** WARNING: Error accessing '}
         LEA      BUFFER(A6),A1
         JSR      (A2)
         PRINT    {': '}
         MOVE.L   (A7)+,D0
         MOVE.W   UT_ERR,A2
         JSR      (A2)
NXT_AREA MOVE.L   MSG_CHAN(A6),A0
         MOVE.W   A0,D0
         BLT      NEXTCTLN
         QDOS     IO.CLOSE
         BRA      NEXTCTLN
OP_FORWD LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D7
OPF_LOOP MOVE.L   (A4)+,D1
         CLR.W    (A4)+
         MOVE.W   #$7FFF,(A4)+
         CLR.W    (A4)+
         BSR      OPEN_PKT
         BNE      ERR_OPKT
         MOVE.L   A0,(A4)+
         MOVE.L   D1,(A4)+
         SUBQ.W   #1,D7
         BGT      OPF_LOOP
         CLR.W    ORIGINLN(A6)
         MOVE.L   ORIGCHAN(A6),A0
         MOVE.W   A0,D0
         BLT.S    MSG_LOOP
         MOVEQ    #0,D1
         MOVEQ    #-1,D3
         QDOS     FS.POSAB
         MOVE.B   AREANR(A6),D7
OLN_LOOP MOVEQ    #80,D2
         LEA      ORIGINLN+2(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BNE.S    MSG_LOOP
         SUBQ.B   #1,D7
         BGT      OLN_LOOP
         SUBA.W   D1,A1
         SUBQ.W   #1,D1
         MOVE.W   D1,-(A1)
         BRA.S    MSG_LOOP
NEXT_MSG ADDQ.B   #1,MSGPNT(A6)
MSG_LOOP MOVE.L   FWDNODES+2+FN_CHAN(A6),A0
         MOVEQ    #-1,D3
         LEA      BUFFER(A6),A1
         QDOS     FS.MDINF
         SWAP     D1
         LSR.W    #1,D1
         CMP.W    MINSPACE(A6),D1
         BLO      DESTFULL
         TST.W    MAXMSGS(A6)
         BLE      MSGLIMIT
         MOVEQ    #0,D1
         MOVE.B   MSGPNT(A6),D1
         CMP.B    MAXMSG(A6),D1
         BHS      AREA_END
         LEA      POINTERS(A6),A5
         LSL.W    #2,D1
         MOVE.L   (A5,D1.W),D1
         BLT      NEXT_MSG
         SUB.L    MSG_FRST(A6),D1
         MOVE.L   MSG_BASE(A6),A5
         ADDA.L   D1,A5
         LEA      MS_ATTR(A5),A1
         BSR      LD_WORD
         BTST     #MS..LOC,D1
         BNE.S    TST_PRIV
         TST.B    NOFORWD(A6)
         BNE      NEXT_MSG
TST_PRIV BTST     #MS..PRIV,D1
         BEQ.S    NOT_PRIV
         TST.B    NOPRIV(A6)
         BNE      NEXT_MSG
NOT_PRIV LEA      MS_TOUSR(A5),A1
         MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         BSR      LD_WORD
         MOVE.L   A1,A3
         MOVEQ    #0,D7
         MOVE.W   D1,D7
         ADD.L    A3,D7
         LEA      NOECHO,A0
         BSR      COMPSTR
         BEQ      NEXT_MSG
         CLR.W    SBYNODES(A6)
         CLR.W    PATNODES(A6)
         LEA      MS_DZONE(A5),A1
         BSR      LD_WORD
         BLT.S    GET_EINF
         LEA      PRODINFO,A1
         LEA      BUFFER(A6),A2
         BSR      COPYSTR
         LEA      ORIGIN,A1
         BSR      COPYSTR
         LEA      ORIGINLN(A6),A1
         TST.W    (A1)
         BNE.S    DEFLTORG
         LEA      DEF_ORIG(A6),A1
DEFLTORG BSR      COPYSTR
         MOVE.B   #' ',(A2)+
         MOVE.B   #'(',(A2)+
         MOVE.L   A2,A1
         BSR      ORIG_ADD
         MOVE.L   A1,A2
         MOVE.B   #')',(A2)+
         MOVE.B   #CR,(A2)+
         LEA      MS_DZONE(A5),A1
         MOVEQ    #-1,D1
         BSR      STO_WORD
         MOVE.L   D7,D2
         SUB.L    A3,D2
         MOVE.L   A2,D1
         SUB.L    A6,D1
         SUBI.W   #BUFFER,D1
         ADD.W    D2,D1
         BSR      STO_WORD
         MOVE.W   D2,D1
         BSR      STO_WORD
         MOVE.L   A2,D1
         LEA      BUFFER(A6),A2
         SUB.L    A2,D1
         MOVE.L   D7,A1
         BSR      INSERT
COPY_ORG MOVE.B   (A2)+,(A1)+
         SUBQ.W   #1,D1
         BNE      COPY_ORG
         MOVE.L   A1,D7
         MOVE.L   A1,A3
         BRA.S    NODESCAN
GET_EINF BSR      LD_WORD
         ADDA.W   D1,A3
         MOVE.L   A3,A1
         LEA      SBYNODES+2(A6),A4
         MOVEQ    #0,D4
COPY_EIN CMP.L    A1,D7
         BLS.S    LOOKPATH
         LEA      SEEN_BY,A0
         BSR      COMPSTR1
         BNE.S    LOOKPATH
         MOVE.W   #MAXSBY,D3
         SUB.W    SBYNODES(A6),D3
         BSR      READNODE
         BLT      SB_ERROR
         BGT      SB_2MANY
         ADD.W    D2,SBYNODES(A6)
         ADDQ.W   #1,A1
         BRA      COPY_EIN
LOOKPATH LEA      PATNODES+2(A6),A4
         MOVEQ    #0,D4
LP_LOOP  CMP.L    A1,D7
         BLS.S    NODESCAN
         LEA      PATH,A0
         BSR      COMPSTR
         BNE.S    NODESCAN
         MOVE.W   #MAXPATH-1,D3
         SUB.W    PATNODES(A6),D3
         BSR      READNODE
         BNE.S    PATH_ERR
         ADD.W    D2,PATNODES(A6)
         ADDQ.W   #1,A1
         BRA      LP_LOOP
PATH_ERR MOVE.L   D7,A1
         CLR.W    PATNODES(A6)
NODESCAN MOVE.L   A1,D6
         MOVE.L   MYNET(A6),D1
         TST.W    MYPOINT(A6)
         BEQ.S    NSCAN_2
         MOVE.L   PNTNET(A6),D1
NSCAN_2  MOVE.L   D1,D2
         BSR      LOOK_SBY
         LEA      AKAS(A6),A4
         MOVE.W   (A4)+,D4
ADD_AKAS SUBQ.W   #1,D4
         BLT.S    ADD_FWD
         MOVE.L   (A4)+,D1
         BSR      LOOK_SBY
         BRA      ADD_AKAS
ADD_FWD  LEA      PATNODES(A6),A4
         MOVE.W   (A4),D4
         ADDQ.W   #1,(A4)+
         LSL.W    #2,D4
         MOVE.L   D2,(A4,D4.W)
         LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D4
         MOVE.L   A4,A1
         MOVE.L   D4,D0
NS_CLEAR SF       FN_FORWD(A1)
         ADDA.W   #FN_LEN,A1
         SUBQ.W   #1,D0
         BGT      NS_CLEAR
NS_LOOP  MOVE.L   FN_NETNR(A4),D1
         BSR      LOOK_SBY
         BEQ.S    NS_NEXT
         BGT      SB_2MANY
         ST       FN_FORWD(A4)
         SUBQ.W   #1,MAXMSGS(A6)
NS_NEXT  ADDA.W   #FN_LEN,A4
         SUBQ.W   #1,D4
         BGT      NS_LOOP
SSORT_LP SF       D0
         LEA      SBYNODES(A6),A4
         MOVE.W   (A4)+,D4
         BRA.S    SSORT_NX
SSORT_CP MOVE.L   (A4)+,D1
         CMP.L    (A4),D1
         BLS.S    SSORT_NX
         MOVE.L   (A4),-4(A4)
         MOVE.L   D1,(A4)
         ST       D0
SSORT_NX SUBQ.W   #1,D4
         BGT      SSORT_CP
         TST.B    D0
         BNE      SSORT_LP
         MOVE.W   PNTNET(A6),D5
         TST.W    MYPOINT(A6)
         BEQ.S    GENSBY_1
         MOVEQ    #-1,D5
GENSBY_1 BSR      GEN_SNBY
         LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D4
EXPT_LP  TST.B    FN_FORWD(A4)
         BEQ.S    EXPT_NXT
         BSR      EXPORT_2
         BNE.S    EXPT_ERR
         ADDQ.B   #1,FN_NMSG(A4)
         CMP.W    FN_MINSZ(A4),D1
         BGE.S    EXPT_MAX
         MOVE.W   D1,FN_MINSZ(A4)
EXPT_MAX CMP.W    FN_MAXSZ(A4),D1
         BLE.S    EXPT_NXT
         MOVE.W   D1,FN_MAXSZ(A4)
EXPT_NXT ADDA.W   #FN_LEN,A4
         SUBQ.W   #1,D4
         BGT      EXPT_LP
         SUBQ.W   #1,PATNODES(A6)
         MOVEQ    #-1,D5
         BSR      GEN_SNBY
         MOVE.L   A2,D2
         LEA      BUFFER(A6),A2
         SUB.L    A2,D2
         MOVE.L   D2,D1
         SUB.L    A3,D6
         SUB.L    D6,D1
         MOVE.L   A3,A1
         BSR      INSERT
RSTO_LP  MOVE.B   (A2)+,(A3)+
         SUBQ.L   #1,D2
         BGT      RSTO_LP
         BRA      NEXT_MSG

EXPT_ERR PEA      DESTMSG
         BRA.S    SAV_ERR
RSTO_ERR PEA      RSTOMSG
SAV_ERR  MOVE.L   D0,-(A7)
         LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D4
         MOVEQ    #-1,D3
TRUNC_LP MOVE.L   FN_CHAN(A4),A0
         MOVE.L   FN_OLDLN(A4),D1
         QDOS     FS.POSAB
         QDOS     FS.TRUNC
         ADDA.W   #FN_LEN,A4
         SUBQ.W   #1,D4
         BGT      TRUNC_LP
         BSR.S    CLOSE_FN
         MOVEM.L  (A7)+,D0/A1
         BRA      ERR_EXIT

CLOSE_FN LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D4
         CLR.W    -(A7)
CLFN_LP  MOVE.L   FN_CHAN(A4),A0
         MOVEQ    #-1,D3
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         SUB.L    FN_OLDLN(A4),D1
         MOVE.L   D1,FN_OLDLN(A4)
         MOVEQ    #2,D2
         MOVE.L   A7,A1
         QDOS     IO.SSTRG
         QDOS     IO.CLOSE
         ADDA.W   #FN_LEN,A4
         SUBQ.W   #1,D4
         BGT      CLFN_LP
         ADDQ.W   #2,A7
         RTS

AREA_END BSR.S    A_TIDYUP
         BRA      NEXTCTLN
DESTFULL BSR.S    A_TIDYUP
         LEA      MINSPMSG,A1
         MOVEQ    #0,D0
         BRA      ERR_EXIT
MSGLIMIT BSR.S    A_TIDYUP
         LEA      MAXMSMSG,A1
         MOVEQ    #0,D0
         BRA      ERR_EXIT

A_TIDYUP MOVE.L   MSG_CHAN(A6),A0
         MOVEQ    #-1,D3
         LEA      HD_AREA(A6),A1
         QDOS     FS.HEADS
         MOVEQ    #1,D1
         QDOS     FS.POSAB
         MOVE.W   #255*4,D2
         LEA      POINTERS(A6),A1
         QDOS     IO.SSTRG
         TST.L    D0
         BNE      RSTO_ERR
         MOVE.L   MSG_FRST(A6),D1
         QDOS     FS.POSAB
         MOVE.L   MSG_END(A6),D2
         MOVE.L   MSG_BASE(A6),A1
         SUB.L    A1,D2
         BSR      SBYTES
         BNE      RSTO_ERR
         QDOS     FS.TRUNC
         QDOS     IO.CLOSE
         BSR      CLOSE_FN
         MOVE.L   MSG_BASE(A6),A0
         QDOS     MT.RECHP
         TST.B    NOLOG(A6)
         BNE      A_END
         LEA      FWDNODES(A6),A4
         MOVE.W   (A4)+,D4
LOG_LOOP TST.B    FN_NMSG(A4)
         BEQ      LOG_NEXT
         LEA      BUFFER(A6),A1
         MOVEQ    #79,D0
FILL_SPC MOVE.B   #' ',(A1)+
         DBF      D0,FILL_SPC
         LEA      BUFFER(A6),A1
         QDOS     MT.RCLCK
         BSR      DATE$
         ADDQ.W   #1,A1
         MOVEQ    #0,D1
         MOVE.B   AREANR(A6),D1
         MOVEQ    #2,D2
         MOVEQ    #' ',D3
         BSR      ITOD_W
         ADDQ.W   #1,A1
         LEA      AREANAME(A6),A0
         MOVE.W   (A0)+,D0
         CMPI.W   #12,D0
         BLE.S    DSP_AREA
         MOVEQ    #12,D0
DSP_AREA MOVE.B   (A0)+,(A1)+
         SUBQ.W   #1,D0
         BGT      DSP_AREA
         LEA      BUFFER+36(A6),A1
         MOVE.W   FN_NETNR(A4),D1
         MOVEQ    #5,D2
         BSR      ITOD_W
         MOVE.B   #'/',(A1)+
         MOVE.W   FN_NODE(A4),D1
         MOVEQ    #0,D2
         BSR      ITOD_W
         LEA      BUFFER+47(A6),A1
         MOVEQ    #0,D1
         MOVE.B   FN_NMSG(A4),D1
         MOVEQ    #4,D2
         BSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.W   FN_MINSZ(A4),D1
         MOVEQ    #5,D2
         BSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.L   FN_OLDLN(A4),D1
         MOVEQ    #0,D0
         MOVE.B   FN_NMSG(A4),D0
         DIVU     D0,D1
         BSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.W   FN_MAXSZ(A4),D1
         BSR      ITOD_W
         ADDQ.W   #1,A1
         MOVE.L   FN_OLDLN(A4),D1
         BSR      ITOD_W
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         MOVEQ    #-1,D3
         MOVE.L   LOGCHAN(A6),A0
         QDOS     IO.SSTRG
LOG_NEXT ADDA.W   #FN_LEN,A4
         SUBQ.W   #1,D4
         BGT      LOG_LOOP
A_END    RTS

SB_ERROR LEA      SBY1MSG,A1
         BRA.S    CE_ERR2
SB_2MANY LEA      SBY2MSG,A1
CE_ERR2  MOVE.L   LOGCHAN(A6),A0
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVEQ    #0,D0
         MOVE.B   AREANR(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         PRINT    {' msg #'}
         MOVEQ    #0,D1
         MOVE.B   MSGPNT(A6),D1
         ADDQ.W   #1,D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         BRA      NEXT_MSG

GEN_SNBY MOVE.L   A3,-(A7)
         LEA      BUFFER(A6),A2
         LEA      SEEN_BY,A3
         LEA      SBYNODES(A6),A4
         BSR.S    GSB_SUB
         LEA      PATNODES(A6),A4
         TST.W    (A4)
         BEQ.S    GSB_END
         LEA      PATH,A3
         MOVEQ    #-1,D5
         BSR.S    GSB_SUB
GSB_END  MOVE.L   (A7)+,A3
         RTS
GSB_SUB  MOVEQ    #0,D2
         SUBA.L   A0,A0
         MOVE.W   (A4)+,D4
SB_NEXT  SUBQ.W   #1,D4
         BLT.S    SB_END
         TST.W    D5
         BLT.S    SB_NWLIN
         CMP.W    (A4),D5
         BNE.S    SB_NWLIN
         ADDQ.W   #4,A4
         BRA      SB_NEXT
SB_NWLIN MOVE.L   A0,D0
         BEQ.S    SB_FIRST
         MOVE.L   A2,D0
         SUB.L    A0,D0
         CMPI.W   #64,D0
         BLS.S    SB_GEN
         MOVE.B   #CR,(A2)+
SB_FIRST MOVE.L   A2,A0
         MOVE.L   A3,A1
         BSR      COPYSTR
         MOVE.B   #' ',(A2)+
         MOVE.L   A2,A1
         MOVEQ    #-1,D3
SB_GEN   MOVE.W   (A4)+,D1
         CMP.W    D3,D1
         BEQ.S    SB_NODE
         MOVE.W   D1,D3
         BSR      ITOD_W
         MOVE.B   #'/',(A1)+
SB_NODE  MOVE.W   (A4)+,D1
         BSR      ITOD_W
         MOVE.B   #' ',(A1)+
         MOVE.L   A1,A2
         BRA      SB_NEXT
SB_END   MOVE.B   #CR,(A2)+
         RTS

* Return EQ if "Sysop" name at (A1)

COMPSYS  MOVEM.L  A0-A1,-(A7)
         LEA      SYSOP,A0
         MOVEQ    #0,D0
         MOVE.B   (A0),D0
CMPSYSLP CMPM.B   (A0)+,(A1)+
         DBNE     D0,CMPSYSLP
         MOVEM.L  (A7)+,A0-A1
         RTS

EXP2_NAM BSR      COMPSYS
         BNE.S    EXP2_STR
         MOVE.L   A1,-(A7)
         LEA      SYSOPNAM+1(A6),A1
         BSR.S    EXP2_STR
         MOVE.L   (A7)+,A1
         MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         ADDA.W   D0,A1
         RTS
EXP2_STR MOVE.B   (A1)+,D1
         BEQ.S    ES_END
ES_LOOP  MOVE.B   (A1)+,(A2)+
         SUBQ.B   #1,D1
         BNE      ES_LOOP
ES_END   CLR.B    (A2)+
         RTS

* Export message to a packet
* Entry: A4 ptr to forward node table, A5 ptr to stored message

EXPORT_2 MOVEM.L  D1-D7/A0-A3,-(A7)
         MOVEQ    #-1,D3
         MOVE.L   FN_CHAN(A4),A0
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         MOVE.L   D1,(A7)           Save current file position
         LEA      BUFFER2(A6),A2
         MOVE.W   #$0200,(A2)+      Type-2 marker
         MOVE.L   MYNET(A6),D1
         TST.W    MYPOINT(A6)
         BEQ.S    EXP_DEST
         MOVE.L   PNTNET(A6),D1     Get node- or fakenet addr
EXP_DEST MOVE.L   FN_NETNR(A4),D2   Destination net/node
         ROL.W    #8,D1
         ROL.W    #8,D2
         MOVE.W   D1,(A2)+
         MOVE.W   D2,(A2)+
         SWAP     D1
         SWAP     D2
         ROL.W    #8,D1
         ROL.W    #8,D2
         MOVE.W   D1,(A2)+
         MOVE.W   D2,(A2)+
         LEA      MS_ATTR(A5),A1
         BSR      LD_WORD
         ANDI.W   #MS.PKMSK,D1
         ROL.W    #8,D1
         MOVE.W   D1,(A2)+          Store masked attr
         CLR.W    (A2)+             Clear cost field
         LEA      MS_DATE(A5),A1
         BSR      LD_LONG
         MOVE.L   A2,A1
         BSR      DATE$             Produce date string
         MOVE.L   A1,A2
         CLR.B    (A2)+             Follow it by NULL terminator
         LEA      MS_TOUSR(A5),A1
         BSR      EXP2_NAM          ToUser name
         BSR      EXP2_NAM          FromUser name
         BSR      EXP2_STR          Subject
         ADDQ.W   #2,A1             Skipover message length
         MOVE.L   A1,D6             Save A1 temporarily
         MOVE.L   A3,D7             End of message pointer
         LEA      MS_DNODE(A5),A1
         BSR      LD_WORD           Get tearline offset
         MOVE.L   D6,A3
         ADDA.W   D1,A3             A3 ptr to tearline
         LEA      AREA,A1
         BSR      COPYSTR
         LEA      AREANAME(A6),A1
         BSR      COPYSTR           Produce "AREA:" line
         MOVE.B   #CR,(A2)+
         LEA      BUFFER2(A6),A1
         MOVE.L   A2,D2
         SUB.L    A1,D2
         BSR      EX2_SSTR          Send whole header & AREA line
         MOVE.L   D6,A1             Restore A1
         MOVEQ    #0,D6             Clear quote count

* Loop for each paragraph

EXP2_PAR CMP.L    A1,D7
         BLS      EXP2_OK           Jump when at end of msg
         CMPI.B   #QON,(A1)         Handle QON and QOFF
         BEQ.S    EXP2_QON
         CMPI.B   #QOFF,(A1)
         BEQ.S    EXP2_QOF
         MOVE.L   A1,A2
         MOVEQ    #CR,D0
EXP2_FCR CMP.B    (A2)+,D0          Find end of paragraph
         BNE      EXP2_FCR
         MOVE.L   A2,D2
         SUB.L    A1,D2             Paragraph length to D2
         TST.W    D6
         BNE.S    EXP2_QUO
EXP2_NQ  BSR.S    EX2_SSTR          Send non-quoted paragraphs
         BRA      EXP2_PAR
EXP2_QON ADDQ.W   #1,D6             QON: increase count
         ADDQ.W   #1,A1
         BRA      EXP2_PAR
EXP2_QOF SUBQ.W   #1,D6             QOFF: Decrease count
         ADDQ.W   #1,A1
         BRA      EXP2_PAR
EXP2_QUO CMPA.L   A1,A3             Quoted paragraph
         BLS      EXP2_NQ           But don't quote tear line
         CMPI.B   #1,(A1)
         BNE.S    EXP2_QOK
         MOVE.L   A2,A1             Also don't quote kludge lines
         BRA      EXP2_PAR
EXP2_QOK MOVE.W   D2,D4
         SUBQ.W   #1,D4             Paragraph length - 1
EXP2_QLN MOVE.L   A1,A2
         MOVEQ    #' ',D1
         BSR.S    EX2_SBYT
         MOVEQ    #67,D5            Max. length of quoted line (ex. " > ")
         MOVE.W   D6,D2
         CMPI.W   #8,D2
         BLS.S    EXP2_Q2
         MOVEQ    #8,D2
EXP2_Q2  SUB.W    D2,D5
EXP2_QLP MOVE.B   #'>',D1
         BSR.S    EX2_SBYT          Output quotes
         SUBQ.W   #1,D2
         BGT      EXP2_QLP
         MOVEQ    #' ',D1
         BSR.S    EX2_SBYT
         MOVE.L   A2,A1
         MOVE.W   D4,D2
         CMP.W    D5,D2
         BLS.S    EXP2_SLN
         MOVE.W   D5,D2
EXP2_FSP CMPI.B   #' ',(A1,D2.W)    Wrap quoted lines
         BEQ.S    EXP2_SLN
         SUBQ.W   #1,D2
         BNE      EXP2_FSP
         MOVE.W   D5,D2
EXP2_SLN BSR.S    EX2_SSTR
         MOVE.L   A1,A2
         MOVEQ    #CR,D1
         BSR.S    EX2_SBYT
         MOVE.L   A2,A1
         SUB.W    D2,D4
         BLE.S    EXP2_QEN
EXP2_SKP CMPI.B   #' ',(A1)
         BNE      EXP2_QLN
         ADDQ.W   #1,A1
         SUBQ.W   #1,D4
         BNE      EXP2_SKP
EXP2_QEN ADDQ.W   #1,A1
         BRA      EXP2_PAR
EX2_SBYT MOVEQ    #IO.SBYTE&$FF,D0  Send byte
         BRA.S    EX2_TRP3
EX2_SSTR MOVEQ    #IO.SSTRG&$FF,D0  Send string
EX2_TRP3 MOVEQ    #-1,D3
         MOVE.L   FN_CHAN(A4),A0
         TRAP     #3
         TST.L    D0
         BEQ.S    EXP2_RTS
         ADDQ.W   #4,A7             Return immediately when error
         BRA.S    EXP2_END
EXP2_OK  MOVE.L   20(A7),A1         Value of D6 on entry
         MOVE.L   24(A7),D7         End-of-msg ptr
         MOVE.L   36(A7),A2         Ptr past PATH line in buffer
LASTPARA CMP.L    A1,D7
         BLS.S    SENDLAST
         BSR      COPYPARA          Process any line after PATH
         BRA      LASTPARA
SENDLAST MOVE.L   A2,D2
         LEA      BUFFER(A6),A1
         SUB.L    A1,D2
         BSR      EX2_SSTR          Send SEEN-BY and PATH lines
         MOVEQ    #4,D2
         LEA      MSG_TERM,A1       Send LF/CR/LF/NULL
         BSR      EX2_SSTR
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         SUB.L    (A7),D1
         MOVEQ    #0,D0
EXP2_END ADDQ.W   #4,A7
         MOVEM.L  (A7)+,D2-D7/A0-A3
         TST.L    D0
EXP2_RTS RTS

         SECTION  MSG
MSG_TERM DC.B     LF,CR,LF,0
         DC.W     0
         END
