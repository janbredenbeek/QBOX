* MODIFIED SER-DRIVER FOR USE WITH QBOX
* This driver replaces the built-in SER-driver. The following new features are
* added:
* - Carrier status monitoring either via CTS of SER2 or DTR of SER1;
* - FS.FLUSH call supported to flush output buffer;
* - New IO.DUMP and IO.PARIT calls (TRAP #3; D0 = $50 and $51 respectively).

* QDOS definitions

ERR.NF   EQU      -7
ERR.BP   EQU      -15

PC_IPCRD EQU      $18020

SV_PLIST EQU      $3C
SV_CHBAS EQU      $78
SV_SER1C EQU      $98
SV_SER2C EQU      $9C

SER_CHNO EQU      $18
SER_PAR  EQU      $1A
SER_TXHS EQU      $1C
SER_PROT EQU      $1E
SER_RXQ  EQU      $20
SER_TXQ  EQU      $82
SER_LEN  EQU      $E4

Q_NXTIN  EQU      8
Q_NXTOUT EQU      $0C

MT.INF   EQU      0
MT.IPCOM EQU      $11
MT.ALCHP EQU      $18
MT.LPOLL EQU      $1C
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
IO.DCD   EQU      $54

MM_ALCHP EQU      $C0
MM_RECHP EQU      $C2
IO_QSET  EQU      $DC
IO_QTEST EQU      $DE
IO_QIN   EQU      $E0
IO_QOUT  EQU      $E2
IO_QEOF  EQU      $E4

BV_NTBAS EQU      $18
BV_NTP   EQU      $1C
BV_NLBAS EQU      $20
BV_RIP   EQU      $58

BP_INIT  EQU      $110
CA_GTINT EQU      $112

* Linkage block offsets

         OFFSET   0

LK_NXINT DS.L     1                 Link to next external interrupt handler
LK_AXINT DS.L     1                 Address of external interrupt (not used)
LK_NPOLL DS.L     1                 Id. for polled interrupt
LK_APOLL DS.L     1
LK_NSCHD DS.L     1                 Id. for scheduler interrupt
LK_ASCHD DS.L     1
LK_NIOD  DS.L     1                 Link to next I/O driver
LK_AIO   DS.L     1                 Address of I/O routine
LK_AOPEN DS.L     1                 Id. for OPEN
LK_ACLOS DS.L     1                 Id. for CLOSE
LK_OLDDR DS.L     1                 Address of old SER driver's linkage block
LK_CDQ   DS.W     1                 Either SV.SER1C, SV.SER2C or 0
LK_CDBIT DS.W     1                 Bit of PC.IPCRD to test for DCD (4 or 5)
LK_CDEOF DS.B     1                 Set RX queue to EOF on DCD loss or not
LK_CDSTA DS.B     1                 DCD line status
LK_COUNT DS.B     1                 DCD timer
         DS.W     0
LK_LEN   EQU      *                 Length of linkage block

         SECTION  CODE

* Initialisation routine

         LEA      PROCDEF,A1
         MOVE.W   BP_INIT,A2        First, add some SuperBASIC extras...
         JSR      (A2)

* the following code fixes the "bad name" problem that occurs when using a
* m/code procedure or function before defining it on pre-JS QL's (when will
* they finally be obsoleted?). Also, it ensures that the name is defined in
* uppercase.

         LEA      PROCDEF+2,A4      Point to first procedure defn.
         MOVE.W   #$0800,D5         NT type word for m/c proc
INIT_NLP MOVE.W   (A4)+,D0          Get rel. addr pointer
         BEQ.S    INIT_FNS          if zero, finished
         LEA      -2(A4,D0.W),A5    A5 = absolute addr now
         MOVE.L   BV_NTBAS(A6),A0   Get start of name table
INIT_NTL CMPA.L   BV_NTP(A6),A0     Loop until end of NT found
         BHS.S    INIT_NTE
         MOVE.L   (A6,A0.L),D0
         BEQ.S    INIT_NXN          Skip null entries...
         TST.W    D0
         BMI.S    INIT_NXN          ...and entries which aren't actual "names"
         MOVE.L   BV_NLBAS(A6),A1
         ADDA.W   D0,A1             A1 = ptr to name (len byte + chars)
         MOVE.L   A1,A2
         MOVE.L   A4,A3
         MOVEQ    #0,D2
         MOVE.B   (A6,A2.L),D2      Get name length
         MOVE.B   D2,D1             Copy to D1...
         BRA.S    INIT_CP           ...and do initial comparison on length
INIT_CPL ADDQ.L   #1,A2             Loop for next char in name
         MOVE.B   (A6,A2.L),D1
         CMPI.B   #$60,D1
         BLS.S    INIT_CP
         SUBI.B   #$20,D1           make it UPPERCASE
INIT_CP  CMP.B    (A3)+,D1
         DBNE     D2,INIT_CPL
         BNE.S    INIT_NXN          NE now if names do not match
         MOVE.W   D5,(A6,A0.L)      if match, make sure it's a m/c proc/fn...
         MOVE.L   A5,4(A6,A0.L)     ... and enter it's address
         MOVE.L   A4,A3
         MOVE.B   (A3)+,D0          Get name length byte
INIT_CPY MOVE.B   (A3)+,1(A6,A1.L)
         ADDQ.L   #1,A1
         SUBQ.B   #1,D0
         BNE      INIT_CPY          ...and copy the original name over
INIT_NTE MOVEQ    #0,D0
         MOVE.B   (A4)+,D0          Get length byte
         ORI.B    #1,D0             make it odd, together with the (A4)+ above
         ADDA.W   D0,A4             it ensures that A4 is now even
         BRA      INIT_NLP          Loop back for next proc/fn
INIT_NXN ADDQ.L   #8,A0             Skip to next NT entry
         BRA      INIT_NTL
INIT_FNS ADDQ.L   #2,A4             If all procs done, skip over to first fn
         BSET     #8,D5             $0800 goes to $0900
         BEQ      INIT_NLP          Loop back for fns, continue if fns done.

* SuperBASIC procs done now, so we can install the driver...

         TRAP     #0                Enter supervisor mode
         MOVE.L   #'SER1',-(A7)
         MOVE.W   #4,-(A7)          Put channel name on stack
INIT_AGN MOVE.L   A7,A0
         MOVEQ    #IO.OPEN,D0
         MOVEQ    #-1,D1
         MOVEQ    #0,D3
         TRAP     #2                Open channel
         TST.L    D0                Error?
         BEQ.S    INIT_INF          No, get info
         ADDQ.B   #1,5(A7)          Try other port
         CMPI.B   #'2',5(A7)
         BLS      INIT_AGN          ... if we haven't tried it yet
         BRA.S    INIT_END          Still no luck...

INIT_INF MOVE.L   A0,-(A7)          Save ID
         MOVE.W   A0,D3             Move channel table index to D3
         MOVEQ    #MT.INF,D0
         TRAP     #1                Get addr of sysvars in A0
         MOVE.L   SV_CHBAS(A0),A0   Get base addr of channel table
         LSL.W    #2,D3             Multiply index by 4
         ADDA.W   D3,A0             Point to SER-channel entry
         MOVE.L   (A0),A0           Get addr of channel definition block
         MOVE.L   4(A0),A4          Get pointer to old linkage block
         MOVE.L   (A7)+,A0          Restore channel ID and close channel
         MOVEQ    #IO.CLOSE,D0
         TRAP     #2
         MOVEQ    #MT.ALCHP,D0
         MOVEQ    #LK_LEN,D1
         MOVEQ    #-1,D2
         TRAP     #1                Allocate memory for new linkage block
         TST.L    D0                Error?
         BNE.S    INIT_END          Yes, exit
         MOVE.L   A0,A3
         LEA      LK_AIO(A3),A0     Point to I/O link
         LEA      SER_IO,A1         Point to new I/O routine
         MOVE.L   A1,(A0)+          Store addr
         LEA      SER_OPEN,A1
         MOVE.L   A1,(A0)+          New OPEN routine
         LEA      SER_CLOS,A1       Store addr of new CLOSE routine
         MOVE.L   A1,(A0)+
         LEA      -LK_NIOD(A4),A4
         MOVE.L   A4,(A0)+          Store addr of old driver's linkage blk
         MOVEQ    #MT.LIOD,D0
         LEA      LK_NIOD(A3),A0
         TRAP     #1                Link in new driver
         LEA      LK_NPOLL(A3),A0
         LEA      SER_POLL,A1       Store addr of poll routine
         MOVE.L   A1,4(A0)
         MOVEQ    #MT.LPOLL,D0
         TRAP     #1                Link in poll routine
         MOVEQ    #0,D0
INIT_END ADDQ.L   #6,A7             Remove channel name off stack
         ANDI.W   #$DFFF,SR         Back to user mode
         RTS

* SB procedure definitions

PROCDEF  DC.W     1                 One procedure
         DC.W     SER_DCD-*
         DC.B     7,'SER_DCD'
         DC.W     0                 End of procs
         DC.W     0,0               Number of fns + end marker

SER_DCD  MOVE.W   CA_GTINT,A2       Get integers
         JSR      (A2)
         BNE.S    SD_END
         MOVEQ    #0,D4             Assume 0 if no parameters
         TST.W    D3
         BEQ.S    SD_1PRM
         MOVE.W   (A6,A1.L),D4      Get first param (port # to monitor)
         ADDQ.L   #2,BV_RIP(A6)     Adjust RI stack
         CMPI.W   #2,D4
         BHI.S    SD_BP             Must be 0, 1 or 2
SD_1PRM  MOVE.W   D4,D5             D5 = port # for DCD line
         SUBQ.W   #2,D3             (default = same port)
         BLT.S    SD_GETLK
         BGT.S    SD_BP             Error if more than 2 params
         MOVE.W   2(A6,A1.L),D5     If 2 params, second goes to D5
         CMPI.W   #2,D5             ... and must be 0 to 2
         BHI.S    SD_BP
         ADDQ.L   #2,BV_RIP(A6)
SD_GETLK MOVEQ    #MT.INF,D0
         TRAP     #1
         LEA      SV_PLIST(A0),A0   Point to start of polled list
         LEA      SER_POLL,A1       The address we're looking for
SD_GETL1 MOVE.L   (A0),D0           Loop for the whole polled list until
         BEQ.S    SD_NF             we have found our entry
         MOVE.L   D0,A0
         CMPA.L   LK_APOLL-LK_NPOLL(A0),A1
         BNE      SD_GETL1
         LEA      -LK_NPOLL(A0),A3  ...so we can find our linkage block back
         MOVE.B   #-5,LK_COUNT(A3)  Reset counter first
         SF       LK_CDSTA(A3)      And DCD status
         MOVEQ    #0,D3             D3 is set up to hold either SV_SER1C or
         SUBQ.W   #1,D4             SV_SER2C, but zero if port # is 0
         BLT.S    SD_STQ            (meaning no EOF monitoring)
         MOVE.W   #SV_SER1C,D3
         LSL.W    #2,D4
         ADD.W    D4,D3
SD_STQ   MOVE.W   D3,LK_CDQ(A3)     This is saved now...
         TST.B    D5                If D5 = 0 (no monitoring), skip
         BEQ.S    SD_STB
         ADDQ.W   #3,D5             D5 = 4 for SER1 or 5 for SER2
SD_STB   MOVE.W   D5,LK_CDBIT(A3)   (the bit PC_IPCRD to test)
         MOVEQ    #0,D0             No error; finished.
SD_END   RTS
SD_BP    MOVEQ    #ERR.BP,D0
         RTS
SD_NF    MOVEQ    #ERR.NF,D0
         RTS

* Open routine (mainly the same as old)

SER_OPEN MOVE.L   A3,-(A7)
         MOVE.L   LK_OLDDR(A3),A3   Get old linkage blk ptr
         MOVE.L   LK_AOPEN(A3),A4   Get OPEN routine ptr
         JSR      (A4)              Call it...
         TST.L    D0                Did the OPEN succeed?
         BNE.S    SO_END            no
         MOVE.L   (A7),A3           Restore linkage block ptr
         SF       LK_CDSTA(A3)      Signal "no carrier" initially
         ST       LK_CDEOF(A3)      EOF on DCD loss is initially enabled
         MOVE.B   #-5,LK_COUNT(A3)  Reset DCD timer
         BCLR     #7,SER_RXQ(A0)    Ensure that rx queue is not EOF
*                                   (Minerva doesn't create a new queue if
*                                   it re-uses the existing chan. defn block)
SO_END   MOVE.L   (A7)+,A3
         RTS

* Commands to be sent to IPC on channel close (first SER1, then SER2)
                                    
CLOS_CMD DC.B     4,0,0,0,0,0,1,0
         DC.B     5,0,0,0,0,0,1,0

* Channel close routine
                                    
SER_CLOS MOVE.L   A0,-(A7)
         MOVEQ    #MT.INF,D0
         TRAP     #1
         MOVE.L   (A7)+,A0
         ANDI.L   #$FF00FFFF,D2
         CMPI.L   #$31003130,D2     QDOS version > 1.10?
         BHI.S    CLOS_OLD          Yes, skip "bugfix" code

* The following lines correct a bug in the SER-driver's CLOSE routine. This
* bug causes the IPC to actually close SER1 when SER2 should be closed!
* QDOS versions > 1.10 (i.e. MG ROM and later) don't have this bug, so the
* old driver's CLOSE routine is called to maintain compatibility with e.g.
* Minerva (which handles the CTRL-Z protocol differently).

         LEA      CLOS_CMD,A3       Point to SER1 close command
         MOVE.W   SER_CHNO(A0),D2   Get port number (1 or 2)
         SUBQ.W   #1,D2
         BEQ.S    CLOSE_2           Skip if port 1
         ADDQ.L   #8,A3             Else, point to SER2 close command
CLOSE_2  MOVEQ    #MT.IPCOM,D0      Send it to IPC
         TRAP     #1
         LEA      SER_TXQ(A0),A2
         MOVE.W   IO_QEOF,A1        Set transmit queue to EOF
         JSR      (A1)
         MOVEQ    #0,D0             Finished with JS and earlier
         RTS

CLOS_OLD MOVE.L   LK_OLDDR(A3),A3   For other versions, chain to the
         MOVE.L   LK_ACLOS(A3),A4   old driver's CLOSE routine
         JMP      (A4)

* I/O routine
                                    
SER_IO   CMPI.B   #FS.FLUSH,D0      Flush command?
         BEQ.S    IO_FLUSH          Jump if so
         CMPI.B   #IO.DUMP,D0       Dump command?
         BEQ.S    CLR_Q             Jump if so
         CMPI.B   #IO.PARIT,D0      Set parity command?
         BEQ.S    SET_PAR           Jump if so
         CMPI.B   #IO.DCD,D0
         BEQ.S    IO_DCD
         TST.W    SER_PAR(A0)       Parity enabled?
         BEQ.S    DO_IO             Skip if not
         CMPI.B   #IO.FBYTE,D0      Handling IO.FBYTE?
         BNE.S    DO_IO2            Skip if not
         MOVE.W   SER_PAR(A0),-(A7) Save parity mode
         CLR.W    SER_PAR(A0)       Set to "none" parity (avoids "XMIT error")
         BSR.S    DO_IO             Do actual I/O
         MOVE.W   (A7)+,SER_PAR(A0) Restore original parity mode
         ANDI.B   #$7F,D1           Clear parity bit
         RTS

* NOTE: The following lines have been added due to a bug in the QL SER-driver's
* IO.SBYTE. This bug sometimes causes incorrect parity on a "not complete" call
* because D1 is changed during the call.
                                    
DO_IO2   CMPI.B   #IO.SBYTE,D0      Handling IO.SBYTE?
         BNE.S    DO_IO             Skip if not
         MOVE.B   D1,-(A7)          Save byte to be sent
         BSR.S    DO_IO             Call actual I/O routine
         MOVE.B   (A7)+,D1          Restore byte to be sent
         RTS
DO_IO    MOVE.L   LK_OLDDR(A3),A3   Get linkage blk addr of old driver
         MOVE.L   LK_AIO(A3),A4     ...and jump to it's I/O routine
         JMP      (A4)

* IO.DUMP routine, clears output queue
                                    
CLR_Q    MOVE.L   SER_TXQ+Q_NXTIN(A0),SER_TXQ+Q_NXTOUT(A0)
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

* IO.DCD function. Turns EOF on DCD loss off (D1 = 0) or on (D1 = 1)
* Returns DCD status in bit 0 of D1.

IO_DCD   TST.B    D1                D1 < 0?
         BMI.S    DCD_READ          If so, only read DCD status
         MOVE.B   D1,LK_CDEOF(A3)
DCD_READ MOVEQ    #1,D1
         AND.B    LK_CDSTA(A3),D1
         MOVEQ    #0,D0
         RTS

* The "poll carrier status" routine. Monitors CTS status of SER2 or DTR status
* of SER1 (depending on the setting of LK_CDBIT). When the line drops low for 
* more than 5 frames (100 ms), the input queue is set to EOF.
                                    
SER_POLL MOVE.W   LK_CDBIT(A3),D6   Get PC.IPCRD bit to test (0, 4 or 5)
         BEQ.S    POLL_END          If 0, finished.
         LEA      PC_IPCRD,A4       Point to IPC status register
         TST.B    LK_COUNT(A3)      Test counter
         BLT.S    RUN_UP            Jump if running up
         BGT.S    RUN_DOWN          Jump if running down
         BTST     D6,(A4)           Test CD line status
         BEQ.S    POLL_END          Bit clear means "ON" and is OK
         MOVE.W   LK_CDQ(A3),D0
         BEQ.S    POLL_END
         MOVE.L   (A6,D0.W),D0
         BEQ.S    POLL_END
         MOVE.L   D0,A2             Addr of queue to set to EOF
         TST.B    (A2)              Queue already set to EOF?
         BLT.S    CLR_TXQ           Exit if so
         MOVE.B   #5,LK_COUNT(A3)   Set counter to 5 frames (100 ms)
POLL_END RTS

* When CD is turned on, allowance is made for a 100 ms settling time
                                    
RUN_UP   BTST     D6,(A4)           CD line "ON"?
         BNE.S    NO_CARR           No, reset counter to -5
         ADDQ.B   #1,LK_COUNT(A3)   Else, increment it
         BNE.S    RU_END
         ST       LK_CDSTA(A3)      and set DCD status to ON if expired
RU_END   RTS
NO_CARR  MOVE.B   #-5,LK_COUNT(A3)
         RTS

* When CD has dropped, it must remain OFF for at least 100 ms
                                    
RUN_DOWN BTST     D6,(A4)           CD line still OFF?
         BEQ.S    RD_CLEAR          Clear counter if not
         SUBQ.B   #1,LK_COUNT(A3)   Decrease counter
         BGT.S    RD_END            Exit if nonzero
         SF       LK_CDSTA(A3)      Clear DCD status
         TST.B    LK_CDEOF(A3)      Exit if EOF-on-DCD loss has been disabled
         BEQ.S    RD_END
         MOVE.W   LK_CDQ(A3),D0
         BEQ.S    RD_END
         MOVE.L   (A6,D0.W),D0
         BEQ.S    RD_END
         MOVE.L   D0,A2
         MOVE.W   IO_QEOF,A1        Else, set RQ queue to EOF
         JSR      (A1)
CLR_TXQ  ADDA.W   #SER_TXQ-SER_RXQ,A2
         MOVE.L   Q_NXTIN(A2),Q_NXTOUT(A2) Clear also output queue
         RTS
RD_CLEAR CLR.B    LK_COUNT(A3)
RD_END   RTS

         END
