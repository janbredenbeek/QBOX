* COMPNL - FidoNet Nodelist Compiler
* v1.00: June 7, 1989
*
* This program compiles the NODELIST_IDX and POINTLIST_IDX files from one or
* more nodelist(s) and pointlist(s).
*
* Format of NODELIST_IDX:
*
* "NL02" {nodelist index} $FFFA
* <nodelist index> = $FFFF <filename> <file date> {entry}
* <filename> = <length (word)> <QDOS name (padded to even length)>
* <file date> = QDOS update date (.L) of nodelist file
* <entry> = <node> | <hub> | <net> | <region> | <zone>
* <node> = <number> <flags> <line length>
* <hub> = $FFFB <node>
* <net> = $FFFC <number> <next> <pos>
* <region> = $FFFD <number> <next> <pos>
* <zone> = $FFFE <number> <next> <pos> <nextnet>
* <number> = node, hub, net, region or zone number (0-32767)
* <flags> = byte  bit 0: password protected
*                 bit 1: Phone number exception defined
*                 bit 2: Modem command exception defined
* <line length> = length of entry in raw nodelist (byte)
* <next> = offset to next net, region or zone entry in index (word)
* <pos> = absolute position in raw nodelist file (long)
* <nextnet> = offset to first net or region entry in zone (word)
*
* Format of POINTLIST_IDX:
*
* "PL02" <pointlist index> {pointlist index} $FFFE
* <pointlist index> = $FFFF <filename> <file date> {entry}
* <entry> = <point> | <boss>
* <point> = <number> <flags> <line length>
* <boss> = $0000 <zonenr> <netnr> <nodenr>

         INCLUDE  FLP1_QDOS_IN_MAC

* DEFINITIONS

version  SETSTR   1.90a             Program version

NL_ID    EQU      'NL02'            Nodelist index ID & version
PL_ID    EQU      'PL02'            Pointlist index ID & version

NODELIST EQU      -1
ZONE     EQU      -2
REGION   EQU      -3
HOST     EQU      -4
HUB      EQU      -5
NODE_END EQU      -6

PNTLIST  EQU      -1
PNT_END  EQU      -2

CR       EQU      $0D
LF       EQU      $0A

INPBUFSZ EQU      256


         OFFSET   0

STDERR   DS.L     1
INPCHAN  DS.L     1
OUTCHAN  DS.L     1
CTLCHAN  DS.L     1
DIRCHAN  DS.L     1
ERR_SP   DS.L     1
NLIDXBAS DS.L     1
NLIDXPNT DS.L     1
PLIDXBAS DS.L     1
PLIDXPNT DS.L     1
HP_MAX   DS.L     1
LINECNT  DS.W     1
         DS.W     0
NL_DIR   DS.B     50
FNAMBUF  DS.B     50
INPBUF   DS.B     INPBUFSZ


ERRMSG   MACRO    A
[.LAB]   LEA      .S.[.L],A1
         BRA      ERRMSG
         SECTION  MSG
.S.[.L]  DC.W     .E.[.L]-*-2
         DC.B     [A]
.E.[.L]  EQU      *
         SECTION  CODE
         ENDM

         XREF     SKIPSPC,COMPSTR,READNUM,ITOD_W,ITOD_L,A2ZNNP,READDIR
         XREF     MAKEFNAM

         DATA     4096

         SECTION  CODE

         BRA.S    JOBSTART          Skip job header
         DC.L     0                 Starts at 6 so pad 4 bytes...
         DC.W     $4AFB             Ident flag
JOBNAME  STRING$  {'COMPNL'}        Name of program
CTLFNAM  STRING$  'COMPNL_CTL'
NODEIDXN STRING$  'NODELIST_IDX'
PNTIDXN  STRING$  'POINTLIST_IDX'
PHONEDAT STRING$  'PHONE_DAT'
PWD_DAT  STRING$  'PASSWORD_DAT'
         DS.W     0
BANNER   DC.B     4,1,4,0
         DC.W     448,200,32,16
CONSPEC  DC.B     0,0,0,7
         DC.W     444,188,34,27

JOBSTART ADDA.L   A4,A6
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
         LEA      JOBNAME,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         PRINT    {'COMPNL Nodelist Compiler v[version]   1989-91 Jan Bredenbeek'}
         LEA      CONSPEC,A1
         MOVE.W   UT_SCR,A2
         JSR      (A2)
         BEQ.S    SET_CON
CON_ERR  MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'COMPNL: Unable to open window',LF}
         MOVEQ    #-1,D1
         MOVE.L   (A7)+,D3
         QDOS     MT.FRJOB
SET_CON  MOVE.L   A0,CONCHAN(A6)
         PRINT    {'COMPNL Nodelist Compiler v[version]   1989-91 Jan Bredenbeek',LF,LF}
START_2  MOVE.L   A7,A0
         LEA      INPBUF(A6),A1
         MOVE.W   (A0)+,D0
CMDL_2   CMPI.W   #255,D0
         BLE.S    CPYCML_E
         SUBA.L   A0,A0
         PRINT    {'COMPNL option string too long',LF}
         MOVEQ    #ERR.BL,D0
         BRA.S    KILL_JOB
BADCMD   SUBA.L   A0,A0
         PRINT    {'Use EW COMPNL,<source>,<dest>',$5B,',<list>]',$5B,';"<options>"]',LF}
         MOVEQ    #ERR.BP,D0
         BRA.S    KILL_JOB
CPYCML_S MOVE.B   (A0)+,(A1)+
CPYCML_E DBF      D0,CPYCML_S
         MOVE.B   #LF,(A1)
         BSR.S    PROCESS
KILL_JOB MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

GETNUM   CMPI.B   #'0',(A1)
         BLO.S    GN_ERR
         CMPI.B   #'9',(A1)
         BHI.S    GN_ERR
         MOVEQ    #0,D0
         MOVEQ    #0,D1
GN_LOOP  MOVE.B   (A1),D0
         SUBI.B   #'0',D0
         CMPI.B   #9,D0
         BHI.S    GN_END
         ADDQ.W   #1,A1
         MULU     #10,D1
         ADD.W    D0,D1
         BRA      GN_LOOP
GN_END   MOVEQ    #0,D0
         RTS
GN_ERR   MOVEQ    #ERR.XP,D0
         RTS

PROCESS  MOVE.L   A7,ERR_SP(A6)
         ST       NAMEFLAG(A6)
         ST       LOCFLAG(A6)
         SF       CM_SYSOP(A6)
         SF       CM_USERS(A6)
         SF       CM_FORMT(A6)
         SF       CM_ERROR(A6)
         LEA      INPBUF(A6),A1
OPT_LOOP CMPI.B   #LF,(A1)
         BEQ.S    FIRSTLN
         MOVEQ    #$DF-256,D1
         AND.B    (A1)+,D1
         CMPI.B   #'S',D1
         BNE.S    OPT_2
         ST       CM_SYSOP(A6)
         BRA      OPT_LOOP
OPT_2    CMPI.B   #'U',D1
         BNE.S    OPT_3
         ST       CM_USERS(A6)
         BRA      OPT_LOOP
OPT_3    CMPI.B   #'F',D1
         BNE.S    OPT_4
         ST       CM_FORMT(A6)
         BRA      OPT_LOOP
OPT_4    CMPI.B   #'E',D1
         BNE.S    OPT_5
         ST       CM_ERROR(A6)
         BRA      OPT_LOOP
OPT_5    CMPI.B   #'A',D1
         BNE.S    OPT_6
         ST       CM_SYSOP(A6)
         ST       CM_USERS(A6)
         ST       CM_FORMT(A6)
         BRA      OPT_LOOP
OPT_6    CMPI.B   #'N',D1
         BNE.S    OPT_7
         SF       NAMEFLAG(A6)
         SF       LOCFLAG(A6)
         BRA      OPT_LOOP
OPT_7    CMPI.B   #'L',D1
         BNE.S    OPT_ERR
         SF       LOCFLAG(A6)
         BRA      OPT_LOOP
OPT_ERR  SUBA.L   A0,A0
         PRINT    {'COMPNL: Bad command line option',LF}
         MOVEQ    #ERR.BP,D0
         RTS
FIRSTLN  CLR.W    LINECNT(A6)
         BSR      GETLN
         LEA      -7(A1),A2
         SUBA.W   D2,A1
         BSR      PROC_COM
         MOVE.L   A2,A1
         BSR      GETNUM
         BEQ.S    INITCRC
         SUBA.L   A0,A0
         PRINT    {'COMPNL: Garbage found in CRC field',LF}
         MOVEQ    #ERR.BL,D0
         RTS
INITCRC  MOVE.W   D1,CRC(A6)
         CLR.W    CURCRC(A6)
         MOVEQ    #0,D7
         LEA      INDEX(A6),A5
         MOVEQ    #8,D2
         MOVEQ    #-1,D3
         MOVE.L   OUTCHAN(A6),A0
         CLR.L    -(A7)
         MOVE.L   #NL_ID,-(A7)
         MOVE.L   A7,A1
         QDOS     IO.SSTRG
         ADDQ.W   #8,A7
MAINLOOP BSR      GETLN
         BNE      ENDLIST
         PEA      MAINLOOP
         SUBA.W   D2,A1
         MOVEQ    #-1,D3
         MOVE.L   OUTCHAN(A6),A0
         LEA      OUTBUF(A6),A4
         CMPI.B   #',',(A1)
         BEQ.S    PROCNODE
         CMPI.B   #';',(A1)
         BEQ      PROC_COM
         MOVE.L   (A1),D1
         CMPI.L   #'Hub,',D1
         BEQ.S    PROC_HUB
         CMPI.L   #'Pvt,',D1
         BEQ.S    PROC_PVT
         CMPI.L   #'Hold',D1
         BEQ.S    PROCHOLD
         CMPI.L   #'Down',D1
         BEQ.S    PROCDOWN
         CMPI.L   #'Zone',D1
         BEQ      PROCZONE
         CMPI.L   #'Host',D1
         BEQ      PROCHOST
         CMPI.L   #'Regi',D1
         BEQ      PROC_REG
         ERRMSG   {'Unrecognised keyword field'}
READNNUM BSR      GETNUM
         BNE.S    NUM_ERR
         CMPI.B   #',',(A1)+
         BNE.S    NUM_ERR
         RTS
NUM_ERR  ERRMSG   {'Bad zone, net or node number'}
PROC_HUB MOVEQ    #HUB,D0
         ADDQ.W   #3,A1
         BRA.S    STO_ID
PROC_PVT MOVEQ    #PVT,D0
         ADDQ.W   #3,A1
         BRA.S    STO_ID
PROCHOLD MOVEQ    #HOLD,D0
         ADDQ.W   #4,A1
         BRA.S    STO_ID
PROCDOWN MOVEQ    #DOWN,D0
         ADDQ.W   #4,A1
STO_ID   MOVE.W   D0,(A4)+
PROCNODE ADDQ.W   #1,A1
         BSR      READNNUM
         MOVE.W   D1,(A4)+
PNODE_2  CLR.B    (A4)+
         MOVE.L   A4,A2
         BSR.S    COPYNAME
         MOVE.L   A4,A3
         MOVE.B   #',',(A4)+
         MOVE.B   #' ',(A4)+
         BSR.S    COPYNAME
         ORI.B    #$80,-1(A4)
         TST.B    LOCFLAG(A6)
         BNE.S    GET_PH
         MOVE.L   A3,A4
         ORI.B    #$80,-1(A4)
         TST.B    NAMEFLAG(A6)
         BNE.S    GET_PH
         MOVE.L   A2,A4
         MOVE.B   #$80,(A4)+
GET_PH   MOVE.L   A4,A3
         BSR.S    COPYNAME
         MOVE.L   A3,A4
         BSR.S    COPYNAME
         CMPI.W   #PVT,OUTBUF(A6)
         BGT.S    MARK_NUM
         MOVE.L   A3,A4
         CLR.B    (A4)+
MARK_NUM ORI.B    #$80,-1(A4)
         MOVE.L   A4,D0
         SUB.L    A2,D0
         MOVE.B   D0,-(A2)
         LEA      OUTBUF(A6),A1
         MOVE.L   A4,D2
         SUB.L    A1,D2
DO_OUTP  QDOS     IO.SSTRG
         TST.L    D0
         BEQ.S    DN_END
         MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'COMPNL: Output I/O error',LF}
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
DN_END   RTS

COPYNAME MOVE.B   (A1)+,D1
         CMPI.B   #CR,D1
         BEQ.S    CN_END
         CMPI.B   #LF,D1
         BEQ.S    CN_END
         CMPI.B   #',',D1
         BEQ.S    CN_END
         CMPI.B   #'_',D1
         BNE.S    CN_STORE
         MOVEQ    #' ',D1
CN_STORE MOVE.B   D1,(A4)+
         BRA      COPYNAME
CN_END   RTS

PROC_COM ADDQ.W   #1,A1
         MOVE.B   (A1),D1
         CMPI.B   #CR,D1
         BEQ.S    COM_END
         CMPI.B   #LF,D1
         BEQ.S    COM_END
         CMPI.B   #'S',D1
         BNE.S    COM_USR
         TST.B    CM_SYSOP(A6)
         BRA.S    COM_OUT
COM_USR  CMPI.B   #'U',D1
         BNE.S    COM_FMT
         TST.B    CM_USERS(A6)
         BRA.S    COM_OUT
COM_FMT  CMPI.B   #'F',D1
         BNE.S    COM_ERR
         TST.B    CM_FORMT(A6)
         BRA.S    COM_OUT
COM_ERR  CMPI.B   #'E',D1
         BNE.S    COM_OUT1
         TST.B    CM_ERROR(A6)
COM_OUT  BEQ.S    COM_END
COM_OUT1 TST.B    LISTFLAG(A6)
         BEQ.S    COM_END
         ADDQ.W   #2,A1
         SUBQ.W   #4,D2
         MOVE.B   #LF,-1(A1,D2.W)
         MOVE.L   LISTCHAN(A6),A0
         BRA      DO_OUTP
COM_END  RTS

PROCZONE ADDQ.W   #5,A1
         BSR      READNNUM
         MOVE.L   A1,A2
         MOVE.W   #ZONE,(A4)+
         TST.L    D7
         BEQ.S    PZ_2
         CLR.W    (A5)+
         MOVE.L   A5,D0
         SUB.L    D7,D0
         MOVE.L   D7,A1
         MOVE.W   D0,-(A1)
PZ_2     MOVE.W   D1,(A5)+
         CLR.W    (A5)+
         MOVE.L   A5,D7
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         MOVE.L   D1,(A5)+
         MOVE.L   D1,D6
         BRA.S    PNET_END
PROC_REG MOVEQ    #REGION,D0
         ADDQ.W   #7,A1
         BRA.S    PROCNET
PNET_ERR ERRMSG   {'ZONE start expected'}
PROCHOST MOVEQ    #HOST,D0
         ADDQ.W   #5,A1
PROCNET  TST.L    D7
         BEQ.S    PNET_ERR
         MOVE.W   D0,(A4)+
         BSR      READNNUM
         MOVE.W   D1,D4
         MOVE.L   A1,A2
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         EXG      D1,D6
         MOVE.L   D6,D0
         SUB.L    D1,D0
         MOVE.W   D0,(A5)+
         MOVE.W   D4,(A5)+
PNET_END MOVE.L   A2,A1
         BRA      PNODE_2

ENDLIST  CLR.W    (A5)+
         MOVEQ    #2,D2
         MOVEQ    #-1,D3
         MOVE.L   OUTCHAN(A6),A0
         CLR.L    -(A7)
         MOVE.L   A7,A1
         BSR      DO_OUTP
         MOVEQ    #0,D1
         QDOS     FS.POSRE
         MOVE.L   D1,D4
         LEA      INDEX(A6),A1
         MOVE.L   A5,D2
         SUB.L    A1,D2
         BSR      DO_OUTP
         MOVEQ    #4,D1
         QDOS     FS.POSAB
         MOVE.L   D4,(A7)
         MOVEQ    #4,D2
         MOVE.L   A7,A1
         BSR      DO_OUTP
         ADDQ.W   #4,A7
         MOVEQ    #0,D0
         MOVE.W   CURCRC(A6),D1
         CMP.W    CRC(A6),D1
         BEQ.S    XLAT_END
         SUBA.L   A0,A0
         PRINT    {'COMPNL: CRC Mismatch',LF}
         MOVEQ    #ERR.TE,D0
XLAT_END RTS

GETLN    MOVE.W   #INPBUFSZ,D2
         MOVEQ    #-1,D3
         MOVE.L   INPCHAN(A6),A0
         LEA      INPBUF(A6),A1
         QDOS     IO.FLINE
         TST.L    D0
         BEQ.S    GL_CHKCR
         CMPI.L   #ERR.EF,D0
         BEQ.S    GL_END
         MOVE.L   D0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'COMPNL: Input I/O error',LF}
         MOVE.L   (A7)+,D0
         MOVE.L   ERR_SP(A6),A7
         RTS
GL_CHKCR ADDQ.W   #1,LINECNT(A6)
         SUBA.W   D1,A1
         MOVE.W   D1,D2
         MOVE.W   CURCRC(A6),D3
         LEA      CRC_TBL,A0
CRCLOOP  MOVEQ    #0,D0
         MOVE.B   (A1)+,D0
         ROL.W    #8,D3
         EOR.B    D3,D0
         ADD.W    D0,D0
         MOVE.W   (A0,D0.W),D0
         CLR.B    D3
         EOR.W    D0,D3
         SUBQ.W   #1,D1
         BGT      CRCLOOP
         MOVE.W   D3,CURCRC(A6)
         MOVEQ    #0,D0
GL_END   TST.L    D0
         RTS

ERRMSG   TST.B    LISTFLAG(A6)
         BEQ.S    EM_END
         SUBQ.W   #2,D2
         MOVEQ    #-1,D3
         MOVE.L   LISTCHAN(A6),A0
         MOVE.L   A1,-(A7)
         LEA      INPBUF(A6),A1
         QDOS     IO.SSTRG
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
         MOVE.L   (A7)+,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         PRINT    {' - line '}
         MOVE.W   LINECNT(A6),D1
         MOVE.W   UT_MINT,A2
         JSR      (A2)
         MOVEQ    #LF,D1
         QDOS     IO.SBYTE
EM_END   MOVE.L   ERR_SP(A6),A7
         MOVEQ    #ERR.NC,D0
         RTS

         INCLUDE  FLP2_CRCCITT_IN

         SECTION  MSG
         DC.W     0

         END
