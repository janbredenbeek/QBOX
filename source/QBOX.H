** QBOX INCLUDE FILE ***

version  SETSTR   1.19m
REV_MAJ  EQU      1
REV_MIN  EQU      19

* Macro definitions for calling various routines

CALLSUB  MACRO    A,B,C
[.LAB]   LEA      .S.[.L],[C]
         JSR      [A]
         SECTION  MSG
.S.[.L]  DC.W     .E.[.L]-*-2
         DC.B     [B]
.E.[.L]  EQU      *
         SECTION  CODE
         ENDM

LOG      MACRO    A
[.LAB]   CALLSUB  LOG,{[A]},A1
         ENDM

TXSTR    MACRO    A
[.LAB]   CALLSUB  TXSTR,{[A]},A1
         ENDM

TXMSG    MACRO    A
[.LAB]   CALLSUB  TXMSG,{[A]},A1
         ENDM

INPUT    MACRO    A
[.LAB]   CALLSUB  INPUT,{[A]},A0
         ENDM

GETNAM1  MACRO    A
[.LAB]   CALLSUB  GETNAM1,{[A]},A0
         ENDM

GETNAM2  MACRO    A
[.LAB]   CALLSUB  GETNAM2,{[A]},A0
         ENDM

* D0 keys for QSPIL calls

SP.INIT  EQU      0        Initialise modem
SP.WTCAL EQU      1        Wait for call
SP.DSCON EQU      2        Disconnect
SP.CLOSE EQU      3        Closedown
SP.FBAUD EQU      4        Find possible baud rates
SP.DIAL  EQU      5        Originate call
*
SP.PEND  EQU      8        Test pending input
SP.FBYTE EQU      9        Fetch byte
SP.SBYTE EQU      $0A      Send byte
SP.SSTRG EQU      $0B      Send string
SP.FLUSH EQU      $0C      Flush output buffer
SP.DUMP  EQU      $0D      Dump unsent data
SP.PARIT EQU      $0E      Set parity

* Return keys for SP.WTCAL (D1)

CONN_FAX EQU      -2
CON_UNKN EQU      -1       Connection speed unknown
CONN300  EQU      0        Connection at 300 bps
CONN1275 EQU      1        Connection at 1200/75 bps
CONN1200 EQU      2        Connection at 1200 bps
CONN2400 EQU      3        Connection at 2400 bps
CONN4800 EQU      4        Connection at 4800 bps
CONN9600 EQU      5        Connection at 9600 bps
CONN19K2 EQU      6        Connection at 19200 bps
CONN38K4 EQU      7        Connection at 38400 bps
CONN7200 EQU      8
CONN12K  EQU      9
CONN14K4 EQU      10
CONN16K8 EQU      11
CONN21K6 EQU      12
CONN24K  EQU      13
CONN26K4 EQU      14
CONN28K8 EQU      15
CONN31K2 EQU      16
CONN33K6 EQU      17
CONN36K  EQU      18
MAXMODEM EQU      18

* Extra TRAP #3 calls for serial device driver

IO.DUMP  EQU      $350     Dump unsent data
IO.PARIT EQU      $351     Set parity

* Parity keys for SP.PARIT (D1)

PA.NONE  EQU      0        No parity
PA.ODD   EQU      1        Odd parity
PA.EVEN  EQU      2        Even parity
PA.MARK  EQU      3        Mark parity
PA.SPACE EQU      4        Space parity

* Bit flags for RX_CLINK and TX_CLINK (D7)

CRCMODE  EQU      0                 1 if CRC mode
TELINK   EQU      8                 1 if Telink mode
SEALINK  EQU      9                 1 if SEAlink mode
SLO      EQU      10                1 if in Overdrive mode
RESYNC   EQU      11                1 if RESYNC mode
* B_ALLOC  EQU      12                1 = allocate own buffer (RCFILE)
NOCLOSE  EQU      13                1 = don't close output file (RCFILE)
WANT_C   EQU      14                1 = want SEAlink mode

XR..SKIP EQU      15                1 = got first character
S_XOFF   EQU      16                1 = waiting for other end to stop

XR.OK    EQU      0
XR.NOMOR EQU      1
XR.CAN   EQU      2
XR.FAIL  EQU      3
XR.SYNC  EQU      4
XR.IOERR EQU      5
XR.NRERR EQU      6
XR.NSERR EQU      7

* Constants

SOH      EQU      1
ETX      EQU      3
EOT      EQU      4
ENQ      EQU      5
ACK      EQU      6
BELL     EQU      7
BS       EQU      8
CR       EQU      $0D
LF       EQU      $0A
FF       EQU      $0C
XON      EQU      $11
XOFF     EQU      $13
NAK      EQU      $15
SYN      EQU      $16
ETB      EQU      $17
CAN      EQU      $18
SUB      EQU      $1A
ESC      EQU      $1B
QON      EQU      $1E
QOFF     EQU      $1F
C        EQU      $43
DEL      EQU      $7F
TSYNC    EQU      $AE
FXBUFLEN EQU      8192
MAXAREA  EQU      256

* Values for ONLINE variable

ISHUMAN  EQU      1        Human caller
INMAIL   EQU      2        Mail call (inbound)
OUTMAIL  EQU      3        Mail call (outbound)
INFAX    EQU      4        Fax call

* Values for S_MONLY

MAILONLY EQU      1
BBS_ONLY EQU      2

* User privilege levels

LV.TWIT  EQU      0        Twit level (for Commander Frankie etc.)
LV.DISGR EQU      1        New users
LV.NORM  EQU      2        Normal users
LV.SPEC  EQU      3        Special users
LV.EXTRA EQU      4        Extra (not implemented yet)
LV.COSYS EQU      8        Co-sysop
LV.SYSOP EQU      9        Sysop
LV.MAX   EQU      9

* User record

US_NAME  EQU      0        Name (max. 36 chars)
US_CITY  EQU      37       City (max. 25 chars)
US_PASSW EQU      63       Password (max. 16 chars)
US_DAYTM EQU      80       Minutes online today (SIGNED!)
US_CALLS EQU      82       Number of calls
US_LSTLG EQU      84       Time & date of last login
US_MACCS EQU      88       Msg area access bits
US_FACCS EQU      92       File area access bits
US_LEVEL EQU      96       Level (bits 0 to 3)
US_HELPL EQU      96       Help level (bits 4 to 7)
US_WIDTH EQU      97       Terminal width - 1
US_LINES EQU      98       Number of lines on terminal (bits 0 to 6)
US_MORE  EQU      98       "More?" flag (bit 7)
* US_TIME  EQU      99     !Not used anymore!
US_DWNLD EQU      100      Download limit for today (Kbytes)
US_MBCMD EQU      102      Command to be given on <ENTER> in mailbox menu
*                          Gap of 7
US_MAREA EQU      110      Current message area
US_FAREA EQU      111      Current file area
* US_CMSGS EQU      112      32 x current message in area
US_LEN   EQU      144      Length of user record

US.NMAX  EQU      36       Maximum length of name
US.CMAX  EQU      25       Maximum length of city
US.PMAX  EQU      16       Maximum length of password
US.LEVEL EQU      %00001111  Mask for user level
US.HELPL EQU      %11110000  Mask for user help level

* Stored message offsets

MS_DATE  EQU      0        Date & time (QDOS format)
MS_OZONE EQU      4        Origin zone
MS_ONET  EQU      6        Origin net
MS_ONODE EQU      8        Origin node
MS_OPNT  EQU      10       Origin point
MS_DZONE EQU      12       Destination zone
MS_DNET  EQU      14       Destination net
MS_DNODE EQU      16       Destination node
MS_DPNT  EQU      18       Destination point
MS_ATTR  EQU      20       Attribute word
MS_COST  EQU      22       Cost
MS_REPTO EQU      24       Message # to which this replies
MS_NXREP EQU      25       Message # which is reply to this
MS_NREAD EQU      26       Times read
MS_RSDAT EQU      28       Date & time when msg received/sent
MS_TOUSR EQU      32       Name of ToUser
*                          followed by FromUser, Subject and text

* Attribute bits
                           
MS..PRIV EQU      0        Private
MS..CRSH EQU      1        Crash
MS..RCVD EQU      2        Received
MS..SENT EQU      3        Sent
MS..FATT EQU      4        File Attached
MS..TRNS EQU      5        In Transit
MS..ORPH EQU      6        Orphan
MS..KSNT EQU      7        Kill/Sent
MS..LOC  EQU      8        Local
MS..HOLD EQU      9        Hold
MS..FREQ EQU      11       File Request
MS..UREQ EQU      15       File Update Request

* User server variables (offsets from register A6)

FINGERPR EQU      'QSET'
THISREV  EQU      1
COMPREV  EQU      1
MAXPATH  EQU      18
MAXNAME  EQU      38
MAXFNAME EQU      46
MAX_AKA  EQU      10
BUFSZ    EQU      32768

         OFFSET   0

SETUP    EQU      *
S_FPRINT DS.L     1        fingerprint of SETUP_BBS file
S_THISRV DS.W     1        revision level
S_COMPRV DS.W     1        rev. lvl for backwards compat.
S_TOTLEN DS.L     1        Total length of setup file
S_SYSDIR DS.B     MAXPATH  system directory
S_INBND  DS.B     MAXPATH  inbound directory
S_OUTBND DS.B     MAXPATH  outbound directory
S_MSGTMP DS.B     MAXPATH  temporary message path
S_QSPIL  DS.B     22       QSPIL filename
S_LOG1   DS.B     MAXFNAME log file for remote server
S_LOG2   DS.B     MAXFNAME log file for local server
S_EDITOR DS.B     MAXFNAME local message editor
S_TERM   DS.B     MAXFNAME local terminal emulator
S_SYSNAM DS.B     MAXNAME  system's name
S_SYSOP  DS.B     MAXNAME  Sysop's name
S_MAILPR DS.B     MAXFNAME Progspec for rcvd mail (NULL terminated)
S_AFTUSR DS.B     MAXFNAME Program executed after each user
S_FAXPRG DS.B     MAXFNAME Program to handle FAX connects
S_SPARE1 DS.B     344
S_INISEC DS.W     1        initial security level
S_MGROUP DS.L     1
S_FGROUP DS.L     1        initial area groups
S_MAREA  DS.W     1
S_FAREA  DS.W     1        init_msgarea, init_filearea
S_DTIME  DS.W     LV.MAX+1 time limit for each level
S_SYSOPM DS.W     1        msg area for log-off message */
S_YSTART DS.W     1
S_YEND   DS.W     1        yell_start, yell_end
S_YELL   DS.B     1        Yell enabled if != 0
S_LOCAL  DS.B     1        Always start up in local mode
S_MONLY  DS.B     1        Mail-only/BBS-only/Mail and BBS
S_TXSLO  DS.B     1        SEALink Transmit Overdrive enable
S_RXSLO  DS.B     1        SEALink Receive Overdrive enable
S_BUFSIZ DS.B     1        SEALink buffer size (-1=none, 0=8K, 1=32K)
S_SPARE2 DS.B     26
S_MYADDR DS.W     MAX_AKA*4  network addresses
S_PNTNET DS.W     MAX_AKA    pointnets
S_MSTART DS.W     1          start/end time of mail-only period
S_MEND   DS.W     1          (in minutes; 0-1439)

S_LEN    EQU      *        Length of setup file

QSPILVEC DS.L     1        Vector for QSPIL
LOGCHAN  DS.L     1        ID of log window
LOGFILE  DS.L     1        ID of log file
COM_IN   DS.L     1        ID of input communication channel
COM_OUT  DS.L     1        ID of output communication channel
DIRCHAN  DS.L     1        Secondary disk file (mainly for Catalog)
INPCHAN  DS.L     1        Primary disk file
OWNERJOB DS.L     1        ID of owner job (main QBOX job)
SPSAV    DS.L     1        Bottom of machine stack
LASTCALL DS.L     1        Date & time of last call for this user
ORIGDATE DS.L     1        Original date of message being changed/replied to
TIMEOUT  DS.L     1
FILE_Q   DS.L     1
BYTECNT  DS.L     1
SECSCNT  DS.L     1
CON_XTRA DS.L     1
FILECNT  DS.W     1
USERPOS  DS.W     1        USERS_BBS record number
MYZONE   DS.W     1
MYNET    DS.W     1
MYNODE   DS.W     1
MYPOINT  DS.W     1
DESTZONE DS.W     1
DESTNET  DS.W     1
DESTNODE DS.W     1
DESTPNT  DS.W     1
BUFSIZE  DS.W     1
LOGDATE  DS.W     1
CUR_AREA DS.W     1
TIMELEFT DS.W     1
LINENR   DS.B     1        Port number
LOCALMOD DS.B     1        Local user ($FF) or not (0)
NOLOG    DS.B     1        Suppress console log ($FF) or not (0)
ECHOPNT  DS.B     1        Echo dots on line input ($FF) or not (0)
PRINTLIN DS.B     1        Print line ($FF) or not (0)
SPEC_OUT DS.B     1
LINUMFLG DS.B     1        Display line numbers ($FF) or not (0)
KLUDGE   DS.B     1        Display kludge lines ($FF) or not (0)
A_GROUP  DS.B     1        Group letter of current message/file area
ISNET    DS.B     1        Current area is netmail ($FF) or not (0)
ISECHO   DS.B     1        Current area is echomail ($FF) or not (0)
ISPRIV   DS.B     1        Current area is private ($FF) or not (0)
ESCMODE  DS.B     1        Received ESC ($FF) or not (0)
ONLINE   DS.B     1        Online ($FF) or not (0)
TMWARNED DS.B     1        "2 minutes left" given ($FF) or not (0)
CHATFLG  DS.B     1        Chatmode entered ($FF) or not (0)
YELLFLG  DS.B     1        Yell alarm on ($FF) or off (0)
WAITCHAR DS.B     1        Waiting for character input ($FF) or not (0)
SYSOPMSG DS.B     1        Entering sysop message ($FF) or not (0)
RINGBACK DS.B     1        Call-back retry counter (0 if no call-back)
BPS      DS.B     1        BPS number from QSPIL (-1 if unknown BPS)
CONN_ARQ DS.B     1        Auto-reliable connect ($FF) or not (0)
QSPILREV DS.B     1
FXPROT   DS.B     1        File transfer protocol chosen
FXBATCH  DS.B     1        Can do batch file xfers ($FF) or not (0)
ALT_DIR  DS.B     1        File area directory overridden ($FF) or not (0)
GOTMAIL  DS.B     1        Got mail/files during session ($FF) or not (0)
         DS.W     0
LASTREAD DS.W     MAXAREA  Lastread msg# for each area
MSCANNED DS.B     MAXAREA  Mail of this area scanned ($FF) or not (0)
AREANAME DS.B     2+60     Description of current msg/file area
DIRBUF   DS.B     2+48     Current subdirectory for msg/file area
FNAMBUF  DS.B     2+48     Buffer for file name
USERBUF  DS.B     US_LEN   Primary user parameters buffer
FILENAME EQU      *        File-Xfer routines workspace (overlayed)
USERBUF2 DS.B     US_LEN   Secondary user parameters buffer
MSGHDR   EQU      *        Message header buffer (overlayed)
XMODBUF  DS.B     US_LEN   XMODEM packet buffer (and tertiary user buffer)
FROMUSER DS.B     36       Current "From:" name
TOUSER   DS.B     36       Current "To:" name
ORIGFROM DS.B     36       Original "From:" name
ORIGTO   DS.B     36       Original "To:" name
SUBJECT  DS.B     72
REPLY_ID DS.B     80       MSGID of message being replied to
NODEBUF  DS.B     100
PASSWORD DS.B     8
OF_ADDR  DS.W     4
OT_ADDR  DS.W     4
         DS.W     1        Length word for LOGBUF
LOGBUF   DS.B     80
BUFFER   EQU      *        General workspace

MSG_BASE EQU      BUFFER+256  Base of message text buffer

