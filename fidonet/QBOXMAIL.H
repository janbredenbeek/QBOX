* QBoss definitions

* Constants

CR       EQU      $0D
LF       EQU      $0A
SOFTCR   EQU      $8D
QON      EQU      $1E
QOFF     EQU      $1F

MAX_AKA  EQU      10       Maximum AKA net/node numbers
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
MS_RSDAT EQU      28       Date & time when received/sent
MS_TOUSR EQU      32       Start of TOUSER field

* MS_ATTR flags

MS..PRIV EQU      0        Private
MS..CRSH EQU      1        Crash
MS..RCVD EQU      2        Received
MS..SENT EQU      3        Sent
MS..FATT EQU      4        File attached
MS..TRNS EQU      5        In transit
MS..ORPH EQU      6        Orphan
MS..KSNT EQU      7        KillSent
MS..LOC  EQU      8        Local
MS..HOLD EQU      9        Hold for pickup
MS..FREQ EQU      11       File Request
MS..UREQ EQU      15       File Update Request

MS.PKMSK EQU      1+(1<<1)+(1<<4)+(1<<10)+(1<<12)+(1<<13)+(1<<14)
*                          Mask for packing

MAXAREA  EQU      256      Highest possible message area
