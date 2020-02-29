* QCONNECT device driver

* QDOS definitions

ERR.NC   EQU      -1
ERR.NO   EQU      -6
ERR.IU   EQU      -9
ERR.EF   EQU      -10
ERR.BP   EQU      -15

SV_SER1C EQU      $98
SV_SER2C EQU      $9C

BV_NTBAS EQU      $18
BV_NTP   EQU      $1C
BV_NLBAS EQU      $20
BV_CHBAS EQU      $30
BV_CHP   EQU      $34
BV_RIP   EQU      $58

SER_CHNO EQU      $18
SER_PAR  EQU      $1A
SER_TXHS EQU      $1C
SER_PROT EQU      $1E
SER_RXQ  EQU      $20
SER_TXQ  EQU      $82
SER_CMON EQU      $E4
SER_USC  EQU      $E6
SER_COFF EQU      $E7
SER_LEN  EQU      $E8

Q_NXTIN  EQU      8
Q_NXTOUT EQU      $0C

MT.INF   EQU      0
MT.IPCOM EQU      $11
MT.BAUD  EQU      $12
MT.ALCHP EQU      $18
MT.LIOD  EQU      $20

IO.OPEN  EQU      1
IO.CLOSE EQU      2

IO.PEND  EQU      0
IO.FBYTE EQU      1
IO.FLINE EQU      2
IO.FSTRG EQU      3
IO.SBYTE EQU      5
IO.SSTRG EQU      7
FS.FLUSH EQU      $41
IO.DUMP  EQU      $50
IO.PARIT EQU      $51
IO.BAUD  EQU      $52

MM_ALCHP EQU      $C0
MM_RECHP EQU      $C2
IO_QSET  EQU      $DC
IO_QTEST EQU      $DE
IO_QIN   EQU      $E0
IO_QOUT  EQU      $E2
IO_QEOF  EQU      $E4
IO_SERIO EQU      $EA
BP_INIT  EQU      $110
CA_GTINT EQU      $112
CA_GTLIN EQU      $118
IO_NAME  EQU      $122

* Linkage block offsets

         OFFSET   0

LK_NXINT DS.L     1
LK_AXINT DS.L     1
LK_NPOLL DS.L     1
LK_APOLL DS.L     1
LK_NSCHD DS.L     1
LK_ASCHD DS.L     1
LK_NIOD  DS.L     1
LK_AIO   DS.L     1
LK_AOPEN DS.L     1
LK_ACLOS DS.L     1
LK_SERIO DS.L     3
         DS.W     1
LK_BMASK DS.B     1
         DS.W     0
LK_LEN   EQU      *

         SECTION  CODE

* Initialisation routine

         MOVEQ    #MT.ALCHP,D0
         MOVEQ    #LK_LEN,D1
         MOVEQ    #0,D2
         TRAP     #1                Allocate memory for new linkage block
         TST.L    D0                Error?
         BNE.S    INIT_END          Yes, exit
         MOVE.L   A0,A3
         LEA      LK_AIO(A3),A0
         LEA      SER_IO,A1
         MOVE.L   A1,(A0)+
         LEA      SER_OPEN,A1
         MOVE.L   A1,(A0)+
         LEA      SER_CLOS,A1
         MOVE.L   A1,(A0)+
         LEA      SER_PEND,A1
         MOVE.L   A1,(A0)+          Pending input routine
         LEA      SER_GETC,A1
         MOVE.L   A1,(A0)+          Get character
         LEA      SER_PUTC,A1
         MOVE.L   A1,(A0)+          Put character
         MOVE.W   #$4E75,(A0)+      RTS instruction
         MOVE.B   #%011011,(A0)+    Initial baud mask (1200/1200)
         MOVEQ    #MT.LIOD,D0
         LEA      LK_NIOD(A3),A0
         TRAP     #1                Link in new driver
         MOVEQ    #MT.BAUD,D0
         MOVE.W   #9600,D1
         TRAP     #1
         BRA.S    INIT_BAS
INIT_END RTS
INIT_BAS LEA      PROCDEF,A1
         MOVE.W   BP_INIT,A2
         JSR      (A2)
         LEA      PROCDEF+2,A4
         MOVE.W   #$0800,D5
PROCLOOP MOVE.W   (A4)+,D0
         BEQ.S    PROC_END
         LEA      -2(A4,D0.W),A5
         MOVEQ    #0,D6
         MOVE.B   (A4)+,D6
         MOVE.L   BV_NTBAS(A6),A0
NT_LOOP  MOVE.L   (A6,A0.L),D0
         BEQ.S    NT_NXT
         MOVE.L   BV_NLBAS(A6),A1
         ADDA.W   D0,A1
         MOVE.L   A1,A2
         MOVE.L   A4,A3
         MOVEQ    #0,D0
         MOVE.B   (A6,A2.L),D0
         CMP.B    D6,D0
         BRA.S    NT_CMPNX
NT_CMPLP ADDQ.W   #1,A2
         MOVE.B   (A6,A2.L),D1
         CMPI.B   #$60,D1
         BLT.S    NT_CMPCH
         SUBI.B   #$20,D1
NT_CMPCH CMP.B    (A3)+,D1
NT_CMPNX DBNE     D0,NT_CMPLP
         BEQ.S    NT_MATCH
NT_NXT   ADDQ.W   #8,A0
         CMPA.L   BV_NTP(A6),A0
         BLO      NT_LOOP
         BRA.S    NEXTPROC
NT_MATCH MOVE.W   D5,(A6,A0.L)
         MOVE.L   A5,4(A6,A0.L)
         MOVE.B   D6,D0
         MOVE.L   A4,A3
NT_COPY  ADDQ.W   #1,A1
         MOVE.B   (A3)+,(A6,A1.L)
         SUBQ.B   #1,D0
         BNE      NT_COPY
NEXTPROC BSET     #0,D6
         ADDA.W   D6,A4
         BRA      PROCLOOP
PROC_END ADDQ.W   #2,A4
         BSET     #8,D5
         BEQ      PROCLOOP
         MOVEQ    #0,D0
         RTS

PROCDEF  DC.W     1
         DC.W     NEWBAUD-*
         DC.B     4,'BAUD'
         DC.W     0,0,0

* Commands to be sent to IPC on channel open/close

OPEN_CMD DC.B     3,0,0,0,0,0,1,0
         DS.W     0
CLOS_CMD DC.B     5,0,0,0,0,0,1,0

NEWBAUD  CMPA.L   A5,A3
         BEQ.S    NB_BP
         MOVEQ    #-1,D7
         TST.B    1(A6,A3.L)
         BPL.S    NB_NORM
         MOVE.L   A5,-(A7)
         LEA      8(A3),A5
         MOVE.W   CA_GTINT,A2
         JSR      (A2)
         MOVE.L   (A7)+,A5
         BNE.S    NB_RTS
         MOVE.W   (A6,A1.L),D7
         ADDQ.L   #2,BV_RIP(A6)
         ADDQ.W   #8,A3
NB_NORM  MOVE.W   CA_GTLIN,A2
         JSR      (A2)
         BNE.S    NB_RTS
         SUBQ.W   #1,D3
         BNE.S    NB_BP
         MOVE.L   (A6,A1.L),D1
         ADDQ.L   #4,BV_RIP(A6)
         TST.W    D7
         BPL.S    NB_CHAN
         MOVEQ    #MT.BAUD,D0
         TRAP     #1
NB_RTS   RTS
NB_CHAN  MOVE.L   BV_CHBAS(A6),A0
         MULU     #$28,D7
         ADDA.L   D7,A0
         CMPA.L   BV_CHP(A6),A0
         BHS.S    NB_NO
         MOVE.L   (A6,A0.L),A0
         MOVE.W   A0,D0
         BMI.S    NB_NO
         MOVEQ    #-1,D3
         MOVEQ    #IO.BAUD,D0
         TRAP     #3
         RTS
NB_BP    MOVEQ    #ERR.BP,D0
         RTS
NB_NO    MOVEQ    #ERR.NO,D0
         RTS

* Channel open routine

SER_OPEN MOVE.L   A3,A4
         SUBQ.W   #6,A7
         MOVE.L   A7,A3
         MOVE.W   IO_NAME,A2
         JSR      (A2)
         BRA.S    OPEN_RTS
         BRA.S    OPEN_RTS
         BRA.S    OPEN_OK
         DC.B     0,4,'QCON'
         DC.W     3
         DC.W     ' _',0
         DC.W     4
         DC.B     'OEMS'
         DC.W     1
         DC.B     'C'
OPEN_END MOVEQ    #0,D0
         BRA.S    OPEN_RTS
OPEN_IU  MOVEQ    #ERR.IU,D0
OPEN_RTS ADDQ.W   #6,A7
         RTS

OPEN_OK  MOVE.W   (A7),D1
         BEQ.S    OPEN_DEF
         BSR      CHECKBPS
         BNE      OPEN_RTS
         MOVE.B   D1,D7
OPEN_DEF LEA      SV_SER2C(A6),A5
         MOVE.L   (A5),D0
         BEQ.S    NEW_CHAN
         MOVE.L   D0,A0
         TST.B    SER_TXQ-SER_RXQ(A0)
         BPL      OPEN_IU
         CLR.L    (A5)
         SUBA.W   #SER_RXQ,A0
         MOVE.W   MM_RECHP,A2
         JSR      (A2)
NEW_CHAN MOVE.L   #SER_LEN,D1
         MOVE.W   MM_ALCHP,A2
         JSR      (A2)
         BNE      OPEN_RTS
         LEA      SER_CHNO(A0),A2
         ADDQ.W   #2,(A2)+
         MOVE.W   2(A7),(A2)+
         ADDQ.W   #1,(A2)+
         SUBQ.W   #1,(A2)+
         MOVE.L   A2,(A5)
         MOVEQ    #81,D1
         MOVE.W   IO_QSET,A1
         JSR      (A1)
         LEA      SER_TXQ(A0),A2
         JSR      (A1)
         MOVE.W   4(A7),SER_CMON(A0)
         MOVEQ    #MT.IPCOM,D0
         LEA      OPEN_CMD,A3
         TRAP     #1
         TST.W    (A7)
         BEQ      OPEN_END
         MOVE.B   D7,D1
         BSR      SENDINIT
         BRA      OPEN_END

* Channel close routine
                                    
SER_CLOS MOVEQ    #MT.IPCOM,D0
         LEA      CLOS_CMD,A3       Point to close command
         TRAP     #1
         LEA      SER_TXQ(A0),A2
         MOVEQ    #31,D1
         MOVE.W   IO_QIN,A1
         JSR      (A1)
         MOVEQ    #%00110001,D1
         JSR      (A1)
         MOVEQ    #%00100111,D1
         JSR      (A1)
         MOVE.W   IO_QEOF,A1
         JSR      (A1)
         MOVEQ    #0,D0
         RTS

* I/O routine
                                    
SER_IO   CMPI.B   #FS.FLUSH,D0      Flush command?
         BEQ.S    IO_FLUSH          Jump if so
         CMPI.B   #IO.DUMP,D0       Dump command?
         BEQ.S    CLR_Q             Jump if so
         CMPI.B   #IO.PARIT,D0      Set parity command?
         BEQ.S    SET_PAR           Jump if so
         CMPI.B   #IO.BAUD,D0
         BEQ.S    SET_BAUD
         PEA      LK_SERIO(A3)
         MOVE.W   IO_SERIO,A2
         JMP      (A2)

* IO.DUMP routine, clears output queue
                                    
CLR_Q    LEA      SER_TXQ(A0),A2
         MOVE.L   Q_NXTIN(A2),Q_NXTOUT(A2)
         MOVEQ    #31,D1
         MOVE.W   IO_QIN,A1
         JSR      (A1)
         MOVEQ    #%00100001,D1
         JSR      (A1)
         MOVEQ    #%01010011,D1
         JSR      (A1)
         MOVEQ    #0,D0
         RTS

* FS.FLUSH routine
                                    
IO_FLUSH LEA      SER_TXQ(A0),A2    Point to output queue
         MOVE.W   IO_QTEST,A1       Test its status
         JSR      (A1)
         BEQ.S    NOTEMPTY          If not empty, return ERR.NC
         ADDQ.L   #1,D0             ERR.NC now sets Z flag
         BEQ.S    FS_END            Return OK if queue empty
NOTEMPTY SUBQ.L   #1,D0             Else, restore error status
FS_END   RTS

* Set parity routine
                                    
SET_PAR  CMPI.W   #4,D1             Only allow range 0 to 4
         BHI.S    PAR_BP
         MOVE.W   D1,SER_PAR(A0)    Store parity parameter
         MOVEQ    #0,D0
         RTS
PAR_BP   MOVEQ    #ERR.BP,D0
         RTS

SET_BAUD MOVE.L   D1,D7
         MOVE.L   A3,A4
         LEA      SER_TXQ(A0),A2
         MOVE.W   IO_QTEST,A1
         JSR      (A1)
         MOVE.L   D7,D1
         CMPI.B   #8,D2
         BHS.S    SB_SEND
         MOVEQ    #ERR.NC,D0
SB_RTS   RTS
SB_SEND  BSR.S    CHECKBPS
         BNE      SB_RTS
SENDINIT MOVE.B   D1,LK_BMASK(A4)
         MOVEQ    #31,D1
         MOVE.W   IO_QIN,A1
         JSR      (A1)
         MOVEQ    #$16,D1
         JSR      (A1)
         MOVEQ    #%01101110,D1
         JSR      (A1)
         MOVEQ    #%00100111,D1
         JSR      (A1)
         MOVE.B   LK_BMASK(A4),D1
         JSR      (A1)
         MOVEQ    #%00000011,D1
         JSR      (A1)
         MOVEQ    #%11001110,D1
         JSR      (A1)
         MOVEQ    #%00000100,D1
         JSR      (A1)
         MOVEQ    #0,D0
         RTS

CHECKBPS LEA      BPSTAB-2,A1
CHKB_LP  ADDQ.W   #2,A1
         TST.W    (A1)
         BEQ.S    CHKB_NF
         CMP.W    (A1)+,D1
         BNE      CHKB_LP
         MOVE.W   (A1),D1
         MOVEQ    #0,D0
         RTS
CHKB_NF  MOVEQ    #ERR.BP,D0
         RTS

BPSTAB   DC.W     75,%110110
         DC.W     300,%101101
         DC.W     600,%100100
         DC.W     1200,%011011
         DC.W     1275,%011110
         DC.W     7512,%110011
         DC.W     2400,%010010
         DC.W     4800,%001001
         DC.W     9600,%000000
         DC.W     0

SER_PEND MOVE.L   A3,A4
         LEA      SER_RXQ(A0),A2
         TST.B    SER_USC(A0)
         BNE.S    SP_GT2ND
SP_AGAIN MOVE.W   IO_QTEST,A1
         JSR      (A1)
         BNE.S    SP_RTS
         CMPI.B   #31,D1
         BNE.S    RET_C
         MOVE.W   IO_QOUT,A1
         JSR      (A1)
         ST       SER_USC(A0)
SP_GT2ND MOVE.W   IO_QTEST,A1
         JSR      (A1)
         BNE.S    SP_RTS
         CMPI.B   #31,D1
         BEQ.S    SP_RTS
         MOVE.W   IO_QOUT,A1
         JSR      (A1)
         SF       SER_USC(A0)
         BSR.S    TST_DCD
         BEQ      SP_AGAIN
SP_RTS   RTS

SER_GETC MOVE.L   A3,A4
         LEA      SER_RXQ(A0),A2
         TST.B    SER_USC(A0)
         BNE.S    SG_GT2ND
SG_AGAIN MOVE.W   IO_QOUT,A1
         JSR      (A1)
         BNE.S    SG_RTS
         CMPI.B   #31,D1
         BNE.S    RET_C
         ST       SER_USC(A0)
SG_GT2ND MOVE.W   IO_QOUT,A1
         JSR      (A1)
         BNE.S    SG_RTS
         SF       SER_USC(A0)
         CMPI.B   #31,D1
         BEQ.S    SG_RTS
         BSR.S    TST_DCD
         BEQ      SG_AGAIN
SG_RTS   RTS

RET_C    TST.W    SER_PAR(A0)
         BEQ.S    RET_C2
         ANDI.B   #$7F,D1
RET_C2   RTS

TST_DCD  MOVEQ    #0,D0
         TST.W    SER_CMON(A0)
         BEQ.S    TCD_RTS
         ANDI.B   #$74,D1
         CMPI.B   #$50,D1
         BEQ.S    TCD_CON
         CMPI.B   #$54,D1
         BNE.S    TCD_RTS
         TST.B    SER_CMON(A0)
         BEQ.S    TCD_RTS
         MOVE.W   IO_QEOF,A1
         JSR      (A1)
         BSR      CLR_Q
         ST       SER_COFF(A0)
         MOVEQ    #ERR.EF,D0
         BRA.S    TCD_RTS
TCD_CON  ST       SER_CMON(A0)
TCD_RTS  TST.L    D0
         RTS

SER_PUTC TST.B    SER_COFF(A0)
         BNE.S    SPC_END
         MOVE.B   D1,D7
         MOVE.W   SER_PAR(A0),D0
         MOVE.B   PAR_TAB(PC,D0.W),D0
         JMP      PAR_TAB(PC,D0.W)
SPC_END  MOVEQ    #0,D0
         RTS

PAR_TAB  DC.B     PA_NONE-PAR_TAB
         DC.B     PA_ODD-PAR_TAB
         DC.B     PA_EVEN-PAR_TAB
         DC.B     PA_MARK-PAR_TAB
         DC.B     PA_SPACE-PAR_TAB

PA_ODD   BSR.S    GEN_PAR
         BCHG     #7,D1
         BRA.S    PA_NONE
PA_EVEN  BSR.S    GEN_PAR
         BRA.S    PA_NONE
PA_MARK  BSET     #7,D1
         BRA.S    PA_NONE
PA_SPACE BCLR     #7,D1
PA_NONE  LEA      SER_TXQ(A0),A2
         CMPI.B   #31,D1
         BNE.S    SENDCHAR
         MOVE.W   IO_QTEST,A1
         JSR      (A1)
         CMPI.B   #2,D2
         BHS.S    SENDC_2
         MOVEQ    #ERR.NC,D0
         BRA.S    PUTC_RTS
SENDC_2  MOVEQ    #31,D1
         MOVE.W   IO_QIN,A1
         JSR      (A1)
SENDCHAR MOVE.W   IO_QIN,A1
         JSR      (A1)
PUTC_RTS MOVE.B   D7,D1
         RTS

GEN_PAR  MOVEQ    #6,D3
         MOVE.B   D1,D4
GP_LOOP  ROR.B    #1,D1
         EOR.B    D1,D4
         DBF      D3,GP_LOOP
         ROXL.B   #1,D4
         ROXR.B   #1,D1
         RTS

         END
