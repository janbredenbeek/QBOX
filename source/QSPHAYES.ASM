* Generic QSPIL driver for Hayes-compatible modems
* Start of programming work: 1st July 1990

* v1.00g3, October 20, 1994
* Made some changes to SP.CLOSE (now always sends offline cmd, unless D1=$80
* on entry; an undocumented and yet unused feature)

* v1.00g2, August 19, 1994
* Changed SENDCMD routine so that it waits for "OK" with multiple AT-commands
* SP.DSCON now waits for "OK" or "NO CARRIER" and exits after 1 sec. delay

* v1.00g1, March 25, 1994
* Extended connect- and dial baudrates
* "Connect Fax" string now returns -2 from SP.WTCAL and SP.DIAL
* When "ARQ" string found after connect, result code is ORed with 256.
* SP.INIT now returns string "QSP1" when OK.
* SP.DIAL and SP.WTCAL return ptr to string after connect string in A1.
* Changed configured command- and response strings to null-terminated
* Echoed modem commands are now ignored

* v0.99d, November 26,1990
* Added 2 * 0.5s delay in SP.INIT

* v0.99c, August 7, 1990
* CONNECT subroutine now correctly sets baudrate
* SP_CLOSE no longer waits for modem response when offline command is null

* v0.99b, August 4, 1990
* Initial beta release

version  SETSTR   1.00g3

* Macro for calling QBOX's PRLOG routine

STRING$  MACRO    A
[.LAB]   DC.W     .E.[.L]-*-2
         DC.B     [A]
.E.[.L]  EQU      *
         ENDM

PRLOG    MACRO    A
[.LAB]   LEA      .S.[.L],A1
         JSR      (A4)
         SECTION  MSG
.S.[.L]  STRING$  {[A]}
         SECTION  CODE
         ENDM

PRINT    MACRO    A
[.LAB]   LEA      .S.[.L],A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         SECTION  MSG
.S.[.L]  STRING$  {[A]}
         SECTION  CODE
         ENDM

QSPIL_ID EQU      $51535031         "QSP1"

CR       EQU      $0D
LF       EQU      $0A

ERR.NC   EQU      -1
ERR.NO   EQU      -6
ERR.IU   EQU      -9
ERR.EF   EQU      -10
ERR.BP   EQU      -15
ERR.NI   EQU      -19
ERR.BL   EQU      -21

* QDOS calls

MT.SUSJB EQU      8
MT.BAUD  EQU      $12

IO.OPEN  EQU      1
IO.CLOSE EQU      2

IO.PEND  EQU      0
IO.FBYTE EQU      1
IO.FLINE EQU      2
IO.SBYTE EQU      5
IO.SSTRG EQU      7
FS.FLUSH EQU      $41

UT_MTEXT EQU      $D0

* Extra TRAP #3 keys for extended SER2 driver

IO.DUMP  EQU      $50               Dump unsent data
IO.PARIT EQU      $51               Set parity
IO.BAUD  EQU      $52               Set baudrate
IO.FLOW  EQU      $53               Set XON/XOFF flow control
IO.DCD   EQU      $54               Set DCD detect capability

* D0 keys for QSPIL calls

SP.INIT  EQU      0                 Initialise driver
SP.WTCAL EQU      1                 Wait for call
SP.DSCON EQU      2                 Disconnect
SP.CLOSE EQU      3                 Closedown
SP.FBAUD EQU      4                 Find baud rates allowed
SP.DIAL  EQU      5                 Dial number
SP.DIALS EQU      6                 Dial with specific command
SP.ANSWR EQU      7                 Answer immediately
SP.PEND  EQU      8                 Test pending input
SP.FBYTE EQU      9                 Fetch byte
SP.SBYTE EQU      $0A               Send byte
SP.SSTRG EQU      $0B               Send string
SP.FLUSH EQU      $0C               Flush output buffer
SP.DUMP  EQU      $0D               Dump unsent data
SP.PARIT EQU      $0E               Set parity
SP.FLOW  EQU      $0F               Set XON/XOFF flow control
SP.DCD   EQU      $10               Set DCD detect capability
SP.MAXOP EQU      $10               Highest operation code

* Return keys for SP.WTCAL

CON_300  EQU      0                 Connection at 300/300 bps
CON_1275 EQU      1                 Connection at 1200/75 bps (main channel)
CON_1200 EQU      2                 Connection at 1200/1200 bps
CON_2400 EQU      3                 Connection at 2400 bps
CON_4800 EQU      4                               4800 ...
CON_9600 EQU      5                               ... and so on
CON_19K2 EQU      6
CON_38K4 EQU      7
CON_7200 EQU      8
CON_12K  EQU      9
CON_14K4 EQU      10
CON_16K8 EQU      11
CON_21K6 EQU      12
CON_24K  EQU      13
CON_26K4 EQU      14
CON_28K8 EQU      15
CON_31K2 EQU      16
CON_33K6 EQU      17
CON_36K  EQU      18
CON_57K6 EQU      19
CON_64K  EQU      20

CON_MAX  EQU      20

CON_ARQ  EQU      $100              ORed with connect code when MNP/V42

CON_UNKN EQU      -1                Unknown speed
CON_FAX  EQU      -2                Fax connect

         SECTION  CODE

         JMP      START(PC)
         DC.L     QSPIL_ID
SIGNON   STRING$  {'QSPHAYES v[version]  Copyright (C) 1990-95 by Jan Bredenbeek'}
         DCB.B    64-(*-SIGNON),0

* Configuration data

CFGVER   DC.W     201
BAUD     DC.W     2400
FAXBAUD  DC.W     19200
LOCKED   DC.W     0
DELAY    DC.W     1
TIMEOUT  DC.W     70*50
ANSWER   DC.W     1
FAXCARR  DC.W     1
PORT     STRING$  'SER2H'
         DS.B     32-(*-PORT)
OKMSG    DC.B     'OK'
         DCB.B    32-(*-OKMSG),0
NOCARMSG DC.B     'NO CARRIER'
         DCB.B    32-(*-NOCARMSG),0
BUSYMSG  DC.B     'BUSY'
         DCB.B    32-(*-BUSYMSG),0
NODIALMS DC.B     'NO DIAL'
         DCB.B    32-(*-NODIALMS),0
RINGMSG  DC.B     'RING|'
         DCB.B    32-(*-RINGMSG),0
RINGINGM DC.B     'RINGING'
         DCB.B    32-(*-RINGINGM),0
CONN300  DC.B     'CONNECT|'
         DCB.B    32-(*-CONN300),0
CONN1275 DC.B     'CONNECT 1275'
         DCB.B    32-(*-CONN1275),0
CONN1200 DC.B     'CONNECT 1200'
         DCB.B    32-(*-CONN1200),0
CONN2400 DC.B     'CONNECT 2400'
         DCB.B    32-(*-CONN2400),0
CONN4800 DC.B     'CONNECT 4800'
         DCB.B    32-(*-CONN4800),0
CONN9600 DC.B     'CONNECT 9600'
         DCB.B    32-(*-CONN9600),0
CONN19K2 DC.B     'CONNECT 19200'
         DCB.B    32-(*-CONN19K2),0
CONN38K4 DC.B     'CONNECT 38400'
         DCB.B    32-(*-CONN38K4),0
CONN7200 DC.B     'CONNECT 7200'
         DCB.B    32-(*-CONN7200),0
CONN12K  DC.B     'CONNECT 12000'
         DCB.B    32-(*-CONN12K),0
CONN14K4 DC.B     'CONNECT 14400'
         DCB.B    32-(*-CONN14K4),0
CONN16K8 DC.B     'CONNECT 16800'
         DCB.B    32-(*-CONN16K8),0
CONN21K6 DC.B     'CONNECT 21600'
         DCB.B    32-(*-CONN21K6),0
CONN24K  DC.B     'CONNECT 24000'
         DCB.B    32-(*-CONN24K),0
CONN26K4 DC.B     'CONNECT 26400'
         DCB.B    32-(*-CONN26K4),0
CONN28K8 DC.B     'CONNECT 28800'
         DCB.B    32-(*-CONN28K8),0
CONN31K2 DC.B     'CONNECT 31200'
         DCB.B    32-(*-CONN31K2),0
CONN33K6 DC.B     'CONNECT 33600'
         DCB.B    32-(*-CONN33K6),0
CONN36K  DC.B     'CONNECT 36000'
         DCB.B    32-(*-CONN36K),0
CONN57K6 DC.B     'CONNECT 57600'
         DCB.B    32-(*-CONN57K6),0
CONN64K  DC.B     'CONNECT 64000'
         DCB.B    32-(*-CONN64K),0
CONN_FAX DC.B     'CONNECT FAX'
         DCB.B    32-(*-CONN_FAX),0
CONN_ARQ DC.B     '/ARQ'
         DCB.B    16-(*-CONN_ARQ),0
INIT1    DC.B     'ATZ|'
         DCB.B    50-(*-INIT1),0
INIT2    DC.B     ''
         DCB.B    50-(*-INIT2),0
INIT3    DC.B     ''
         DCB.B    50-(*-INIT3),0
ASWCMD   DC.B     'ATA|'
         DCB.B    50-(*-ASWCMD),0
FAXASW   DC.B     ''
         DCB.B    50-(*-FAXASW),0
HANGUP   DC.B     '~~~+++~~~ATH0|'
         DCB.B    50-(*-HANGUP),0
OFFLINE  DC.B     'ATM0H1|'
         DCB.B    50-(*-OFFLINE),0
DIAL300  DC.B     'AT'
         DCB.B    50-(*-DIAL300),0
DIAL1275 DC.B     'AT'
         DCB.B    50-(*-DIAL1275),0
DIAL1200 DC.B     'AT'
         DCB.B    50-(*-DIAL1200),0
DIAL2400 DC.B     'AT'
         DCB.B    50-(*-DIAL2400),0
DIAL4800 DC.B     'AT'
         DCB.B    50-(*-DIAL4800),0
DIAL9600 DC.B     'AT'
         DCB.B    50-(*-DIAL9600),0
DIAL19K2 DC.B     'AT'
         DCB.B    50-(*-DIAL19K2),0
DIAL38K4 DC.B     'AT'
         DCB.B    50-(*-DIAL38K4),0
DIAL7200 DC.B     'AT'
         DCB.B    50-(*-DIAL7200),0
DIAL12K  DC.B     'AT'
         DCB.B    50-(*-DIAL12K),0
DIAL14K4 DC.B     'AT'
         DCB.B    50-(*-DIAL14K4),0
DIAL16K8 DC.B     'AT'
         DCB.B    50-(*-DIAL16K8),0
DIAL21K6 DC.B     'AT'
         DCB.B    50-(*-DIAL21K6),0
DIAL24K  DC.B     'AT'
         DCB.B    50-(*-DIAL24K),0
DIAL26K4 DC.B     'AT'
         DCB.B    50-(*-DIAL26K4),0
DIAL28K8 DC.B     'AT'
         DCB.B    50-(*-DIAL28K8),0
DPREFIX  DC.B     'DT'
         DCB.B    50-(*-DPREFIX),0
DSUFFIX  DC.B     '|'
         DCB.B    50-(*-DSUFFIX),0
USRDATA  DC.B     'DATA',0
USRCONN  DC.B     'ATO|',0

START    CMPI.W   #SP.MAXOP,D0      Valid function call?
         BHI.S    ERR_NI            Jump if not implemented yet
         ADD.W    D0,D0             Calculate table offset
         MOVE.W   OPTBL(PC,D0.W),D0
         JMP      START(PC,D0.W)    Jump to handling routine
ERR_NI   MOVEQ    #ERR.NI,D0        "Not implemented"
         RTS
OPTBL    DC.W     SP_INIT-START
         DC.W     SP_WTCAL-START
         DC.W     SP_DSCON-START
         DC.W     SP_CLOSE-START
         DC.W     SP_FBAUD-START
         DC.W     SP_DIAL-START
         DC.W     SP_DIALS-START
         DC.W     SP_ANSWR-START
         DC.W     SP_PEND-START
         DC.W     SP_FBYTE-START
         DC.W     SP_SBYTE-START
         DC.W     SP_SSTRG-START
         DC.W     SP_FLUSH-START
         DC.W     SP_DUMP-START
         DC.W     SP_PARIT-START
         DC.W     SP_FLOW-START
         DC.W     SP_DCD-START

* Initialise driver
                                    
SP_INIT  BSR      OPENCHAN          Is it possible to open a channel?
         BNE.S    INIT_END          No, exit
         BSR      SENDINIT          Send init string
         MOVE.L   #QSPIL_ID,D1
         MOVEQ    #0,D0             Return with QSPIL_ID in D1
INIT_END RTS

* Wait for phone call
                                    
SP_WTCAL MOVE.W   D3,D4             Save timeout
         BSR      OPENCHAN          Open channel (if necessary)
         BNE      WTCAL_RT          Exit if error
         BSR      SENDINIT          Send init string
         MOVE.W   ANSWER(PC),D5     # of rings to answer on
         MOVE.W   D4,D3
         BSR      GETRESLT          Wait...
         BNE      WTCAL_RT
WTCALL_1 LEA      RINGMSG(PC),A2
         BSR      CMPRESLT          Was it a "RING"?
         BNE.S    WTCALL_2          No
         SUBQ.W   #1,D5             Is it time to go off-hook?
         BEQ.S    WTCALL_A          Yes
         PRLOG    {'- Phone is ringing',LF}
         SUBA.L   A1,A1
         TST.W    D5                If #rings was 0, look for
         BMI.S    WTCAL_1A          CONNECT message
         MOVE.W   #15*50,D3         Wait for second ring
         BSR      GETRESLT
         BEQ.S    WTCALL_1
         PRLOG    {'- No second ring detected',LF}
         BRA.S    WTCAL_NC
WTCAL_1A MOVE.W   TIMEOUT(PC),D3
         BSR      GETRESLT          Now wait for CONNECT or other response
         BEQ      WTCALL_1
         BRA.S    WTCAL_NR

* SP_ANSWR enters here (answer call immediately)

SP_ANSWR BSR      OPENCHAN
         BNE.S    WTCAL_RT

* Now send the answer command and wait for the result

WTCALL_A PRLOG    {'- Answering call',LF}
         LEA      ASWCMD(PC),A1
         BSR      SENDCMD
WTCAL_A1 MOVE.W   TIMEOUT(PC),D3
         BSR      GETRESLT
         BEQ.S    WTCALL_2
WTCAL_NR PRLOG    {'? No response from modem',LF}
         MOVEQ    #IO.SBYTE,D0
         MOVEQ    #CR,D1            Send CR to the modem so it hangs up
         MOVEQ    #-1,D3
         TRAP     #3
WTCAL_NC MOVEQ    #ERR.NC,D0
         BRA.S    WTCAL_RT

* Wait for "CONNECT xxxxx" message

WTCALL_2 MOVE.L   A1,-(A7)
         LEA      RINGMSG(PC),A2    But ignore any more rings now
         BSR      CMPRESLT
         BEQ.S    WTCAL_2A
         LEA      OKMSG(PC),A2      ...and "OK"s.
         BSR      CMPRESLT
WTCAL_2A MOVE.L   (A7)+,A1
         BEQ      WTCAL_A1
         LEA      NOCARMSG(PC),A2   "NO CARRIER"?
         BSR      CMPRESLT          Yes
         BEQ.S    WTCAL_C
         LEA      USRDATA(PC),A2    "DATA"? (USRobotics class 1 peculiarity)
         BSR      CMPRESLT
         BNE.S    WTCAL_CO          No
         LEA      USRCONN(PC),A1    Else, send ATO to get connect string
         BSR      SENDCMD
         BRA      WTCAL_A1
WTCAL_CO BSR      CONNECT           Got a CONNECT?
         BEQ.S    WTCAL_OK          Yes
         BSR      MODEMLOG          Else, report it
         SUBA.L   A1,A1
         BRA      WTCAL_A1          and loop back
WTCAL_OK MOVEQ    #0,D0
         BRA.S    WTCAL_RT
WTCAL_C  LEA      FAXASW(PC),A1     No Class 1 answer command?
         TST.B    (A1)
         BEQ.S    WTCAL_ER          Yes, return error
         BSR      SENDCMD           Else, send fax answer cmd
         BRA      WTCAL_A1          and loop back for result

* Disconnect line

SP_DSCON MOVE.L   CHANID(PC),A0
         MOVEQ    #-1,D3
         BSR      SP_FLUSH          Flush output first
         BSR      PURGE_IN
         LEA      HANGUP(PC),A1
         TST.B    (A1)              Is there a "Hangup" command?
         BEQ.S    DSCON_CL          If not, just close the channel
         BSR      SENDCMD           Else, send it
         MOVE.W   #5*50,D3
DSCON_LP BSR      GETRESLT          Now wait for either OK or NO CARRIER
         BNE.S    DSCON_ER
         LEA      OKMSG(PC),A2
         BSR      CMPRESLT
         BEQ.S    DSCON_FL
         LEA      NOCARMSG(PC),A2
         BSR      CMPRESLT
         BNE      DSCON_LP          If we haven't got neither message, try again
         BRA.S    DSCON_FL
DSCON_ER CMPI.L   #ERR.EF,D0        If we got EOF, it's OK
         BEQ.S    DSCON_FL          If timeout, something went wrong...
         PRLOG    {'? Unable to disconnect line',LF}
DSCON_FL MOVEQ    #-1,D3
         BSR      SP_FLUSH          Ensure hangup command has been sent
         MOVEQ    #50,D3
         BSR      PAUSE             Wait 1 second, then close channel
         BRA      CLOSE_CH
DSCON_CL BSR      CLOSE_CH          If no hangup command to send, close the
         MOVEQ    #50,D3            channel (should do the hangup) and wait
         BRA      PAUSE             1 second before returning

* Closedown
                                    
SP_CLOSE ADD.B    D1,D1             D1=$80 only closes channel (undocumented!)
         BVS.S    SP_CLOS2
         BEQ.S    RESMOD            If not online, skip
         BSR      SP_DSCON          else, disconnect line
RESMOD   MOVE.B   OFFLINE(PC),D1    If no offline command to send, just close
         BEQ.S    SP_CLOS2          channel and exit
         MOVEQ    #-1,D1
         BSR      OPENCHAN          else, make sure channel is open
         BNE.S    SP_CLOSR
         MOVEQ    #50,D3
         BSR      PAUSE             Wait 1 second
         LEA      OFFLINE(PC),A1
         BSR      SENDCMD           and send the offline command
         MOVE.W   #5*50,D3
         BSR      GETRESLT          wait at most 5 secs for reply
SP_CLOS2 BSR      CLOSE_CH          at last, close channel
SP_CLOSR RTS

* Return possible originate modes

SP_FBAUD MOVE.W   BAUD(PC),D2       Baudrate as configured
         LEA      DIAL300(PC),A0    Point to first dial cmd
         LEA      BAUDTBL(PC),A1    Point to baudrate table
         MOVEQ    #0,D0
         MOVEQ    #0,D1
FBAUD_LP CMP.W    (A1)+,D2          Check if configured rate is below current
         BLO.S    FBAUD_NX          If so, skip
         TST.B    (A0)              If no dial cmd for this rate, skip also
         BEQ.S    FBAUD_NX
         BSET     D0,D1             Else, set bit to indicate speed supported
FBAUD_NX ADDA.W   #50,A0
         ADDQ.W   #1,D0
         CMPI.W   #CON_MAX,D0
         BLS      FBAUD_LP          Loop for all rates
         MOVEQ    #0,D0
         RTS

* Originate call

SP_DIALS SF       D4                Clear D4 to signal "specific dial cmd"
         BRA.S    SP_DIAL1
SP_DIAL  ST       D4                Set D4 to indicate "standard dial cmd"
SP_DIAL1 MOVE.W   (A1)+,D0          Get length of cmd/phone number
         MOVE.W   D0,D5
         ADDQ.W   #2,D5
         ANDI.W   #$7FFE,D5         Round up to an even number
         SUBA.W   D5,A7
         MOVE.L   A7,A3
SP_DLSL  SUBQ.W   #1,D0
         BLT.S    SP_DLSE
         MOVE.B   (A1)+,(A3)+       ...and copy it onto the stack
         BRA      SP_DLSL
SP_DLSE  CLR.B    (A3)+             Append null byte
         MOVE.L   A7,A3
         TST.B    D4                Are we doing a SP_DIALS?
         BEQ.S    SP_DIAL2          Yes, skip
         LEA      DIAL300(PC),A3
         MOVE.W   D2,D0
         MULU     #50,D0
         ADDA.W   D0,A3             Else, find appropriate dial cmd
         TST.B    (A3)
         BEQ      SPD_BP            ...but it should be there
SP_DIAL2 CMPI.W   #CON_MAX,D2
         BHI      SPD_BP            Don't try higher speeds than supported
         LEA      BAUDTBL(PC),A0
         ADD.W    D2,D2
         MOVE.W   (A0,D2.W),D2      Get appropriate baud rate
         MOVE.W   BAUD(PC),D0
         CMP.W    D0,D2
         BHI      SPD_BP            Baud rate too high
         BSR      OPENCHAN          Now open the channel
         BNE      SPD_RTS
         MOVE.W   D2,D1
         BSR      SETBAUD           ...set the baud rate...
         MOVE.L   A3,A1
         BSR      SENDCMD           ...and send the dial command
         TST.B    D4
         BEQ.S    SPD_RESL          When doing SP_DIALS, skip
         MOVE.L   A1,A3
         LEA      DPREFIX(PC),A1
         BSR      SENDCMD           Else, send dial prefix string
         MOVE.L   A7,A1
         BSR      SENDCMD           ...followed by phone number...
         LEA      DSUFFIX(PC),A1
         BSR      SENDCMD           ...followed by suffix string
         MOVE.L   A3,A1             Original dial cmd (in case modem echoes it)
SPD_RESL MOVE.W   TIMEOUT(PC),D3
         BSR      GETRESLT          Wait for the response
         BEQ.S    SPD_2
         PRLOG    {'? No response from modem',LF}
         MOVEQ    #IO.SBYTE,D0
         MOVEQ    #CR,D1            If no response, send CR to force modem
         MOVEQ    #-1,D3            onhook
         TRAP     #3
         BRA.S    SPD_FL
SPD_2    LEA      OKMSG(PC),A2
         MOVE.L   A1,-(A7)
         BSR      CMPRESLT
         BEQ.S    SPD_2A
         LEA      RINGINGM(PC),A2
         BSR      CMPRESLT
SPD_2A   MOVE.L   (A7)+,A1
         BEQ      SPD_RESL          Ignore "OK" and "RINGING"
         LEA      NODIALMS(PC),A2
         BSR      CMPRESLT
         BEQ.S    SPD_NODL          Exit when "NO DIALTONE"
         LEA      BUSYMSG(PC),A2
         BSR      CMPRESLT
         BEQ.S    SPD_BUSY          and with "BUSY"
         BSR      CONNECT           Do we have a CONNECT?
         BEQ.S    SPD_OK            Yes, exit
         BSR      MODEMLOG          If unknown response, log it
         BRA.S    SPD_RESL
SPD_OK   MOVEQ    #0,D0
SPD_RTS  ADDA.W   D5,A7
         RTS
SPD_BP   MOVEQ    #ERR.BP,D0
         BRA      SPD_RTS
SPD_FL   MOVEQ    #ERR.NC,D0        No connect
         BRA      SPD_RTS
SPD_NODL MOVEQ    #ERR.BL,D0        No dialtone
         BRA      SPD_RTS
SPD_BUSY MOVEQ    #ERR.IU,D0        Busy
         BRA      SPD_RTS

* I/O routines
                                    
SP_PEND  MOVEQ    #IO.PEND,D0
         BRA.S    DOTRP3
SP_FBYTE MOVEQ    #IO.FBYTE,D0
         BRA.S    DOTRP3
SP_SBYTE MOVEQ    #IO.SBYTE,D0
         BRA.S    DOTRP3
SP_SSTRG MOVEQ    #IO.SSTRG,D0
         BRA.S    DOTRP3

* The following entries check for the precense of an extended SER-driver
* If no extended driver, they return ERR.NI

SP_FLUSH MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SP_IO_NI
         MOVEQ    #FS.FLUSH,D0
         BRA.S    DOTRP3
SP_DUMP  MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SP_IO_NI
         MOVEQ    #IO.DUMP,D0
         BRA.S    DOTRP3
SP_PARIT MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SP_IO_NI
         MOVEQ    #IO.PARIT,D0
         BRA.S    DOTRP3
SP_FLOW  MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SP_IO_NI
         MOVEQ    #IO.FLOW,D0
         BRA.S    DOTRP3
SP_DCD   MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SP_IO_NI
         MOVEQ    #IO.DCD,D0
DOTRP3   TRAP     #3
         RTS
SP_IO_NI MOVEQ    #ERR.NI,D0
         RTS

* Get channel ID or open channel

OPENCHAN MOVE.L   CHANID(PC),A0
         MOVE.W   A0,D0             Channel already open?
         BMI.S    OPENCH_2          No, skip
         MOVE.L   D1,-(A7)
         MOVEQ    #-1,D3
         BSR      SP_DUMP           Clear output- and input buffers
         BSR      PURGE_IN
         CMPI.L   #ERR.EF,D0        EOF?
         BEQ.S    OPENCH_C          Yes, jump to close and re-open it
         MOVEQ    #0,D1
         BSR      SP_PARIT          Ensure no parity
         MOVEQ    #1,D1
         BSR      SP_DCD            And enable DCD detect
         MOVE.L   (A7)+,D1          Restore job ID
         MOVEQ    #0,D0             Return OK
         BRA.S    OPENCH_R
OPENCH_C BSR.S    CLOSE_CH          Channel was EOF so close it
         MOVE.L   (A7)+,D1
OPENCH_2 MOVEQ    #IO.OPEN,D0
         MOVEQ    #0,D3
         LEA      PORT(PC),A0
         TRAP     #2                Open the channel
         TST.L    D0
         BNE.S    OPENCH_R
         LEA      CHANID(PC),A1
         MOVE.L   A0,(A1)           and store ID
         BSR      PURGE_IN          Purge input (required for Minnie!)
         MOVEQ    #-1,D3
         BSR      SP_FLUSH          This checks for extended driver
         TST.L    D0
         BEQ.S    OPENCH_R
         LEA      EXT_DRVR(PC),A1
         SF       (A1)
         MOVEQ    #0,D0
OPENCH_R RTS

* Close channel

CLOSE_CH MOVEQ    #IO.CLOSE,D0
         MOVE.L   CHANID(PC),A0
         TRAP     #2                Close the channel
         MOVEQ    #-1,D0
         LEA      CHANID(PC),A0
         MOVE.L   D0,(A0)           ...and set ID to -1
         MOVEQ    #0,D0
         RTS

* Set baudrate (D1)

SETBAUD  MOVE.W   LOCKED(PC),D0     If locked rate, override D1 with
         BEQ.S    SB_2              configured value
         MOVE.W   BAUD(PC),D1
SB_2     MOVE.B   EXT_DRVR(PC),D0
         BEQ.S    SB_3
         MOVEQ    #IO.BAUD,D0
         MOVEQ    #-1,D3
         MOVE.W   D1,-(A7)
         TRAP     #3                Try IO.BAUD first
         MOVE.W   (A7)+,D1
         TST.L    D0
         BEQ.S    SB_END
SB_3     MOVEQ    #MT.BAUD,D0
         TRAP     #1                If not supported, use MT.BAUD
SB_END   MOVEQ    #25,D3

* Pause for D3 frames
                                    
PAUSE    MOVEM.L  D1/A0-A1,-(A7)
         MOVEQ    #MT.SUSJB,D0
         MOVEQ    #-1,D1
         SUBA.L   A1,A1
         TRAP     #1
         MOVEM.L  (A7)+,D1/A0-A1
         RTS

* Send init strings

SENDINIT MOVE.W   BAUD(PC),D1
         BSR      SETBAUD           Set baud rate first
         MOVEQ    #2,D7             Three init strings max.
         LEA      INIT1(PC),A3
DO_INIT1 MOVEQ    #2,D6             Try each at most three times
DO_INIT2 TST.B    (A3)              String is empty?
         BEQ.S    INIT_NXT          Yes, skip
         MOVE.L   A3,A1
         BSR.S    SENDCMD           Send each string
IN_GETRS MOVE.W   #5*50,D3
         BSR      GETRESLT          ...and wait for OK
         BNE.S    IN_FAIL
         LEA      OKMSG(PC),A2
         BSR      CMPRESLT
         BEQ.S    INIT_NXT
IN_FAIL  DBF      D6,DO_INIT2
         MOVE.L   A0,-(A7)
         SUBA.L   A0,A0
         PRINT    {'WARNING: Failed to initialise modem',LF}
         MOVE.L   (A7)+,A0
         RTS
INIT_NXT ADDA.W   #50,A3
         DBF      D7,DO_INIT1
         RTS

* Send modem command (A1)

SENDCMD  MOVEM.L  A2-A4,-(A7)
         MOVE.L   A1,A2
SC_LOOP  MOVE.B   (A1)+,D1          Get next char
         BEQ.S    SC_END
         CMPI.B   #'|',D1           Replace pipe char with CR
         BNE.S    SC_NOPIP
         MOVEQ    #CR,D1
SC_NOPIP CMPI.B   #'~',D1
         BNE.S    SC_SEND
         MOVEQ    #25,D3            and tilde char with .5 secs pause
         BRA.S    SC_PAUSE
SC_SEND  MOVE.L   A1,-(A7)
         MOVEQ    #IO.SBYTE,D0
         MOVEQ    #-1,D3
         TRAP     #3
         MOVE.L   (A7)+,A1
         MOVE.W   DELAY(PC),D3      Wait for modem delay, unless 0
         BEQ.S    SC_PIPE
SC_PAUSE BSR      PAUSE
SC_PIPE  CMPI.B   #'|',-1(A1)       Have we sent a CR?
         BNE      SC_LOOP           no
         TST.B    (A1)              At end of command?
         BEQ.S    SC_END            yes
         EXG      A1,A2             we have a split commmand string
         MOVE.L   A2,-(A7)          so wait for "OK"
         MOVE.W   #5*50,D3
         BSR.S    GETRESLT
         MOVE.L   (A7)+,A2
         MOVE.L   A2,A1             Start of new AT-cmd
         BRA      SC_LOOP
SC_END   MOVE.L   A2,A1
         MOVEM.L  (A7)+,A2-A4
         RTS

* Purge input buffer

PURGE_IN MOVEQ    #0,D3
         MOVEQ    #IO.FBYTE,D0
         TRAP     #3
         TST.L    D0
         BEQ      PURGE_IN
         RTS

* Get result from modem (D3: Timeout)
* Entry: A1 ptr to string to reject (usually modem command echo)

GETRESLT MOVE.L   A1,A2
GR_FLINE MOVEQ    #IO.FLINE,D0
         MOVEQ    #50,D2
         LEA      RESBUF(PC),A1
         TRAP     #3                Read a complete line
         CMPI.L   #ERR.NC,D0
         BEQ.S    GR_END
         CMPI.L   #ERR.NO,D0
         BEQ.S    GR_END
         CMPI.L   #ERR.EF,D0
         BEQ.S    GR_END
         TST.L    D0
         BNE      GR_FLINE
         SUBA.W   D1,A1
         CMPI.W   #2,D1
         BLE      GR_FLINE          Loop back with empty lines
GR_STRIP ANDI.B   #$7F,(A1)+        Strip any high bits
         SUBQ.W   #1,D1
         BGT      GR_STRIP
         MOVE.L   A2,D0             The "reject" string
         BEQ.S    GR_END
         TST.B    (A2)
         BEQ.S    GR_OK             If nothing to reject, all is fine
         BSR      CMPRESLT          Else, look for match
         BEQ      GR_FLINE          ...and loop back if necessary
GR_OK    MOVEQ    #0,D0
GR_END   MOVE.L   A2,A1             Restore original A1
         TST.L    D0
         RTS

* Look for CONNECT codes

CONNECT  MOVEQ    #CON_300,D1
         LEA      CONN300(PC),A2    Start with CONNECT 300
CON_LOOP BSR      CMPRESLT          Jump if match found
         BEQ.S    CON_OK
         ADDA.W   #32,A2            Skip to next connect string
         ADDQ.W   #1,D1
         CMPI.W   #CON_MAX,D1
         BLS      CON_LOOP          Loop back
         LEA      CONN_FAX(PC),A2
         BSR.S    CMPRESLT          Finally, try CONNECT FAX
         BNE.S    CON_NC
         MOVE.W   FAXBAUD(PC),D1
         BEQ.S    CON_FCO
         BSR      SB_2
CON_FCO  MOVE.W   FAXCARR(PC),D1
         BSR      SP_DCD
         MOVEQ    #CON_FAX,D1
         BRA.S    CON_TRL
CON_NC   MOVEQ    #ERR.NC,D0        we cannot make any sense of it...
         RTS
CON_OK   MOVEM.L  D1/A1,-(A7)
         ADD.W    D1,D1
         MOVE.W   BAUDTBL(PC,D1.W),D1
         BSR      SETBAUD           Set new baud rate
         MOVEM.L  (A7)+,D1/A1
CON_TRL  LEA      EXTRABUF+2(PC),A2
CON_MOV  CMPI.B   #CR,(A1)          Now copy anything after the CONNECT xxxxx
         BEQ.S    CON_ARQT          to EXTRABUF for later
         CMPI.B   #LF,(A1)
         BEQ.S    CON_ARQT
         MOVE.B   (A1)+,(A2)+
         BRA      CON_MOV
CON_ARQT CLR.B    (A2)
         MOVE.L   A2,D0
         LEA      EXTRABUF+2(PC),A1
         SUB.L    A1,D0
         MOVE.W   D0,-(A1)          Store length of "extra info"
         CMPI.B   #CON_FAX,D1
         BEQ.S    CON_END           Exit immediately with FAX connects
         MOVE.L   D1,-(A7)          Save connect code
         LEA      CONN_ARQ(PC),A2
         BSR.S    INSTR             Check for "/ARQ" etc., set ARQ bit in
         BNE.S    CON_MORE          connect code if found
         ORI.W    #CON_ARQ,2(A7)

* This code allows for modems returning multiple connect strings (e.g.
* "CARRIER 14400\PROTOCOL LAPM\CONNECT 19200". Each string is scanned for
* the ARQ sequence. Also, it introduces a 1 second settling delay.

CON_MORE MOVEQ    #50,D3            Timeout 1 second
         SUBA.L   A1,A1             No string to reject
         BSR      GETRESLT          Look for more strings
         BNE.S    CON_END1          Done if no more
         LEA      RESBUF(PC),A1
         LEA      CONN_ARQ(PC),A2
         BSR.S    INSTR             Scan for ARQ sequence
         BNE.S    CON_REPT
         ORI.W    #CON_ARQ,2(A7)    Set ARQ bit if found
CON_REPT BSR      MODEMLOG          Print string to log channel
         BRA      CON_MORE          Loop back
CON_END1 MOVE.L   (A7)+,D1          Restore connect code
CON_END  LEA      EXTRABUF(PC),A1   Point to extra info in buffer
         MOVEQ    #0,D0
         RTS

BAUDTBL  DC.W     300,1200,1200,2400,4800,9600,19200,38400
         DC.W     7200,12000,14400,16800,21600,24000,26400,28800
         DC.W     31200,33600,36000,57600,64000

* Compare result codes
* Exit: EQ if string in RESBUF matches string at (A2)

CMPRESLT MOVEM.L  D0-D2/A1-A2,-(A7)
         LEA      RESBUF(PC),A1
CR_LOOP  MOVE.B   (A2)+,D1          Get next char from match string
         BEQ.S    CR_MATCH          if end of string, we've got a match
         CMPI.B   #'~',D1           Skip tildes
         BEQ.S    CR_LOOP
         BSR.S    TOUPPER           Make it uppercase
         CMPI.B   #'|',D1           A pipe char marks the end of a match string
         BNE.S    CR_CMP
         CMPI.B   #CR,(A1)+         ...so look to see if it ends with CR
         BEQ.S    CR_MATCH
         BRA.S    CR_END
CR_CMP   MOVE.B   D1,D0             Compare each char (case-independent)
         MOVE.B   (A1)+,D1
         BSR.S    TOUPPER
         CMP.B    D0,D1
         BEQ      CR_LOOP           If no match, restore all regs and return
CR_END   MOVEM.L  (A7)+,D0-D2/A1-A2
         RTS
CR_MATCH MOVEM.L  (A7)+,D0-D2       If a match, leave A1 and A2 at last char
         ADDQ.L   #8,A7
         RTS

* Convert D1 to uppercase

TOUPPER  CMPI.B   #'a',D1
         BLO.S    TOUP_END
         CMPI.B   #'z',D1
         BHI.S    TOUP_END
         SUBI.B   #'a'-'A',D1
TOUP_END RTS

* Do INSTR for sequence (A2) in string at (A1)

INSTR    MOVE.L   A2,-(A7)          Save ptr to search sequence
INS_1ST  MOVE.B   (A2)+,D1          Get 1st char
         BEQ.S    INS_FND           If null, there's always a match
         BSR      TOUPPER           Convert to upper case
         MOVE.B   D1,D0
INS_1MAT MOVE.B   (A1)+,D1          Now match this up with each char
         CMPI.B   #' ',D1           of the string
         BLO.S    INS_NOTF
         BSR      TOUPPER
         CMP.B    D0,D1
         BNE      INS_1MAT
         MOVE.L   A1,-(A7)          If match found, we need to examine it
INS_2MAT MOVE.B   (A2)+,D1          closer so enter a loop to see if this
         BEQ.S    INS_FND2          is really the string we're looking for
         BSR      TOUPPER
         MOVE.B   D1,D0
         MOVE.B   (A1)+,D1
         CMPI.B   #' ',D1
         BLO.S    INS_BACK
         BSR      TOUPPER
         CMP.B    D0,D1
         BEQ.S    INS_2MAT          Loop back as long as characters match
INS_BACK MOVE.L   (A7)+,A1          If no match, restore pointers and try
         MOVE.L   (A7),A2           again starting with next char of string
         BRA      INS_1ST
INS_FND2 MOVE.L   (A7)+,A1          If we ran out of chars in search string,
         SUBQ.L   #1,A1             we have a match - point A1 at starting pos
INS_FND  MOVE.L   (A7)+,A2          Restore ptr to search string
         MOVEQ    #0,D0             Set D0 to 0 and EQ flag
         RTS
INS_NOTF MOVE.L   (A7)+,A2
         MOVEQ    #-1,D0            No match - set D0 to -1 and NE flag
         RTS

* Print modem message to logfile

MODEMLOG MOVE.L   A4,D0             Is there a log routine?
         BEQ.S    ML_END            No
         LEA      RESBUF(PC),A1
ML_LF    CMPI.B   #CR,(A1)          Find end of message
         BEQ.S    ML_FLEN
         CMPI.B   #LF,(A1)+
         BNE      ML_LF
         SUBQ.L   #1,A1             Point to last char, and
ML_FLEN  MOVE.B   #'"',(A1)+        replace it with closing quote
         MOVE.B   #LF,(A1)+
         MOVE.L   A1,D1
         LEA      RESBUF(PC),A1
         SUB.L    A1,D1
         MOVEQ    #REP_END-REPORT,D0  Length of "Modem reports" message
         MOVEQ    #3,D2
         ADD.W    D0,D2
         ADD.W    D1,D2
         ANDI.B   #$FE,D2
         SUBA.W   D2,A7
         MOVE.L   A7,A3
         MOVE.W   D0,(A3)
         ADD.W    D1,(A3)+
         LEA      REPORT(PC),A2
ML_LP1   MOVE.B   (A2)+,(A3)+       Copy "Modem reports " string
         SUBQ.W   #1,D0
         BHI      ML_LP1
ML_LP2   MOVE.B   (A1)+,(A3)+       ...followed by modem message
         SUBQ.W   #1,D1
         BHI      ML_LP2
         MOVE.L   A7,A1
         MOVE.W   D2,-(A7)
         JSR      (A4)              ...and send this to the log file
         ADDA.W   (A7)+,A7
ML_END   RTS

         SECTION  MSG

CHANID   DC.L     -1
EXT_DRVR DC.B     -1
REPORT   DC.B     'Modem reports "'
REP_END  EQU      *
         DC.W     0
RESBUF   DCB.B    50,0
         DC.B     LF
EXTRABUF DCB.B    50,0

         END

