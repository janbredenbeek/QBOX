; *** QSPIL driver for TCP communications ***
; Based on QSPIL Level 1 specification
;
; Copyright (C) 1990-2020 by Jan Bredenbeek. Licenced under GPL v3

; Version history:
;
; 0.01   16 Oct 2019       Start of work
; 0.90   14 Feb 2020       Implemented full Telnet handshake + IAC escape
; 0.91   15 Feb 2020       Escaped IACs weren't sent if $FF $FF in data 
; 0.92   17 Feb 2020       Fixed endless WILL-DO loops in Telnet handshake
; 0.93   19 Feb 2020       Cleaned up code, fixed wrong flag settings in SP.FBYTE
; 1.00   26 Feb 2020       First release version

version  SETSTR   1.00

* Macro for calling QBOX's PRLOG routine

string$  macro    a
[.lab]   dc.w     .e.[.l]-*-2
         dc.b     [a]
.e.[.l]  equ      *
         endm

prlog    macro    a
[.lab]   lea      .s.[.l],a1
         jsr      (a4)
         section  msg
.s.[.l]  string$  {[a]}
         section  code
         endm

print    macro    a
[.lab]   lea      .s.[.l],a1
         move.w   ut_mtext,a2
         jsr      (a2)
         section  msg
.s.[.l]  string$  {[a]}
         section  code
         endm

QSPIL_ID EQU      $51535031         "QSP1"

CR       equ      $0d
LF       equ      $0a
IAC      equ      $ff               ; Telnet IAC escape
T_DONT   equ      $fe               ; Telnet DONT option
T_DO     equ      $fd               ; Telnet DO option
T_WONT   equ      $fc               ; Telnet WONT option
T_WILL   equ      $fb               ; Telnet WILL option

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
UT_ERR   EQU      $CC

* Extra TRAP #3 keys for IP driver

IP.LISTEN EQU     $50              ; Listen for incoming connections
IP.SEND   EQU     $51
IP.SENDTO EQU     $52
IP.RECV   EQU     $53
IP.RECVFM EQU     $54
IP.GETOPT EQU     $55
IP.SETOPT EQU     $56
IP.SHUTDWN EQU    $57
IP.BIND   EQU     $58
IP.CONNECT EQU    $59
IP.FCNTL EQU      $5A

* D0 keys for QSPIL calls

SP.INIT  EQU      0                 ; Initialise driver
SP.WTCAL EQU      1                 ; Wait for call
SP.DSCON EQU      2                 ; Disconnect
SP.CLOSE EQU      3                 ; Closedown
SP.FBAUD EQU      4                 ; Find baud rates allowed
SP.DIAL  EQU      5                 ; Dial number
SP.DIALS EQU      6                 ; Dial with specific command
SP.ANSWR EQU      7                 ; Answer immediately
SP.PEND  EQU      8                 ; Test pending input
SP.FBYTE EQU      9                 ; Fetch byte
SP.SBYTE EQU      $0A               ; Send byte
SP.SSTRG EQU      $0B               ; Send string
SP.FLUSH EQU      $0C               ; Flush output buffer
SP.DUMP  EQU      $0D               ; Dump unsent data
SP.PARIT EQU      $0E               ; Set parity
SP.FLOW  EQU      $0F               ; Set XON/XOFF flow control
SP.DCD   EQU      $10               ; Set DCD detect capability
SP.MAXOP EQU      $10               ; Highest operation code

* Return keys for SP.WTCAL

CON_300  EQU      0                 ; Connection at 300/300 bps
CON_1275 EQU      1                 ; Connection at 1200/75 bps (main channel)
CON_1200 EQU      2                 ; Connection at 1200/1200 bps
CON_2400 EQU      3                 ; Connection at 2400 bps
CON_4800 EQU      4                 ;               4800 ...
CON_9600 EQU      5                 ;               ... and so on
CON_19K2 EQU      6
CON_38K4 EQU      7
CON_7200 EQU      8                 ; extended rates; not always supported by QBOX!
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

CON_ARQ  EQU      $100              ; ORed with connect code when MNP/V42

CON_UNKN EQU      -1                ; Unknown speed
CON_FAX  EQU      -2                ; Fax connect

         SECTION  CODE

         jmp      start(pc)
         dc.l     qspil_id
SIGNON   STRING$  {'QSPILTCP v[version]  Copyright (C) 1990-2020 by Jan Bredenbeek'}
         DCB.B    64-(*-SIGNON),0   ; fill

; Configuration data (start at offset 72 or $48)

cfgver   dc.w     301               ; configuration version
speed    dc.l     $107              ; for 38400/ARQ (QBOX doesn't recognise higher)
spdbits  dc.l     $ff               ; return value for SP.FBAUD (currently unused)

; sockaddr for listening (offset 82 or $52)

lis_sock dc.w     2                 ; address family
lis_port dc.w     5000              ; port may be user-configured
lis_addr dc.l     0                 ; 0.0.0.0 but configurable
         dc.l     0,0               ; fill to 16 bytes

; Use raw TCP (0), Telnet protocol (1) or adaptive (-1); offset 98 ($62)

t_do_iac dc.b     $ff               ; do Telnet IAC escape: 0 no, 1 yes, -1 auto

; Telnet options: DO binary transmission, WILL binary transmission
;                 WILL Echo
;                 DO Suppress Go-Ahead; WILL Suppress Go-Ahead

T_BINARY equ      0
T_ECHO   equ      1
T_SUPGA  equ      3

; Telnet options to send on connect (offset 100 or $64)

teln_opt string$  {IAC,T_DO,T_BINARY,IAC,T_WILL,T_BINARY,IAC,T_WILL,T_ECHO,IAC,T_DO,T_SUPGA,IAC,T_WILL,T_SUPGA}
         dcb.b    32-(*-teln_opt),0

; Device name for TCP device

tcpname  string$  'TCP_'
         dcb.b    32-(*-tcpname),0

; Device name for socket device

sockname string$  'SCK_'
         dcb.b    32-(*-sockname),0

start    cmpi.w   #sp.maxop,d0      ; valid function call?
         bhi.s    err_ni            ; jump if not implemented yet
         add.w    d0,d0             ; calculate table offset
         move.w   optbl(pc,d0.w),d0
         jmp      start(pc,d0.w)    ; jump to handling routine
err_ni   moveq    #err.ni,d0        ; "not implemented"
         rts
optbl    dc.w     sp_init-start
         dc.w     sp_wtcal-start
         dc.w     sp_dscon-start
         dc.w     sp_close-start
         dc.w     sp_fbaud-start
         dc.w     sp_dial-start
         dc.w     sp_dials-start
         dc.w     sp_answr-start
         dc.w     sp_pend-start
         dc.w     sp_fbyte-start
         dc.w     sp_sbyte-start
         dc.w     sp_sstrg-start
         dc.w     sp_flush-start
         dc.w     sp_dump-start
         dc.w     sp_parit-start
         dc.w     sp_flow-start
         dc.w     sp_dcd-start

; Initialise driver
                                    
sp_init  bsr      openchan
         bne.s    init_end
         move.l   #QSPIL_ID,d1
init_end rts
         
; Wait for incoming connection

sp_wtcal move.l   d1,d4             ; job ID
         move.w   d3,d5             ; save timeout
         bsr      openchan          ; (re-)open TCP channel if necessary
         bne      wtcal_rt
wtcal_bi moveq    #16,d1            ; length of sockaddr structure
         moveq    #-1,d3
         lea      lis_sock,a2       ; sockaddr structure
         moveq    #ip.bind,d0
         trap     #3
         tst.l    d0
         beq.s    wtcal_ac

; The following lines added because uqlx cannot immediately re-bind a socket
; for listening, we'll have to wait until the TIME_WAIT status times out!

         prlog    {'QSPILTCP: Bind socket failed, retrying in 60 seconds',lf}
         move.w   #60*50,d3
         bsr      pause
         bra      wtcal_bi
wtcal_ac moveq    #1,d1             ; accept just one connection
         moveq    #-1,d3
         moveq    #ip.listen,d0
         trap     #3                ; set queue size

; Now wait for a connection to come in. Loop until we get one or we reach
; timeout as specified in D3 on entry

wtcal_lp move.l   d4,d1             ; job id
         move.l   chanid(pc),d3     ; id of TCP channel
         lea      sockname(pc),a0   ; socket name
         moveq    #io.open,d0
         trap     #2                ; try open
         tst.l    d0
         beq.s    wtcal_ok          ; OK
         cmpi.l   #err.nc,d0        ; 'not complete'?
         beq.s    wtcal_1s          ; yes, wait 1 second
         move.l   d0,-(a7)
         bsr      close_ch
         prlog    {'QSPILTCP: Failed to open socket for incoming connection!',lf}
         suba.l   a0,a0
         print    {'QSPILTCP: io.open in sp.wtcal returned error: '}
wtcal_er move.l   (a7)+,d0
         move.w   ut_err,a2
         jsr      (a2)
         bra.s    wtcal_rt

; Nothing has come in yet. Of course we must loop around now, but we'll be nice
; and give other jobs some timeslices as well. We'll wait one second until we
; get a connection or time in D5 runs out.
; (TBH, I feel a bit awkward at this. Note that Qemulator never returns NC, it
; just waits forever until a connection comes in).
; It's also interesting that Minerva always increments the channel tag even on
; failed open attempts. This is quite harmless as channel tags on Minerva never
; get bumped beyond $7FFF to avoid breaking code with negative channel ids.

wtcal_1s moveq    #50,d3            ; one second
         tst.w    d5                ; finite timeout in D5?
         bmi.s    wtcal_wt          ; no, skip
         sub.w    d3,d5             ; subtract one second
         blt.s    wtcal_rt          ; time up, return NC
wtcal_wt bsr      pause             ; wait and give up timeslices
         bra      wtcal_lp
wtcal_ok lea      iac_stat(pc),a1
         move.b   t_do_iac(pc),(a1) ; Observe Telnet IAC?
         beq.s    wtcal_en          ; no, done
         sf       got_iac-iac_stat(a1) ; clear flags
         clr.l    conf_var-iac_stat(a1)
         lea      teln_opt(pc),a1   ; telnet options to send
         move.w   (a1)+,d2
         moveq    #-1,d3
         moveq    #io.sstrg,d0
         trap     #3                ; send them
wtcal_en move.l   speed(pc),d1
         suba.l   a1,a1             ; no extra info
wtcal_rt rts

; SP.ANSWR, currently does nothing

sp_answr moveq    #0,d0
         rts

; Disconnect line

sp_dscon 
;        move.l   chanid(pc),a0     ; close sck_ channel not tcp_ channel!
         moveq    #-1,d3
         bsr      sp_flush          ; flush output first
         bsr      purge_in
dscon_cl moveq    #io.close,d0
         trap     #2                ; close sck_ channel, do not clear chanid
         bsr      close_ch          ; now close tcp_ channel
         moveq    #50,d3
         bra      pause             ; wait 1 second before returning

; Closedown
                                    
sp_close add.b    d1,d1             ; d1=$80 only closes channel (undocumented!)
         bvs.s    sp_clos2
         beq.s    sp_clos2          ; if not online, skip
         bsr      sp_dscon          ; else, disconnect line
sp_clos2 bsr      close_ch          ; at last, close channel
sp_closr rts

; Return possible originate modes (currently not much of use)

sp_fbaud move.l   spdbits(pc),d1
         moveq    #0,d0
         rts

; Originate call (not yet implemented)

sp_dials 
sp_dial  moveq    #err.ni,d0
         rts

; I/O routines
; They all have the timeout in D3 and channel ID in A0 already set up

; Test for pending input
                                    
sp_pend  moveq    #io.pend,d0
         trap     #3
         rts

; fetch byte from channel

sp_fbyte moveq    #io.fbyte,d0      ; fetch a byte
         trap     #3
         tst.l    d0
         bne.s    spf_rts           ; error return
         lea      iac_stat(pc),a3
         tst.b    (a3)              ; Observing IACs?
         beq.s    spf_rts           ; no, return
         tst.b    got_iac-iac_stat(a3); previous char was IAC?
         bne.s    spf_cmd           ; yes, go process command
         cmpi.b   #IAC,d1           ; current is IAC?
         bne.s    spf_niac          ; no, skip
         move.b   #1,(a3)+          ; set flag to 'active state'
         st       (a3)+             ; signal 'got IAC'
         sf       (a3)              ; clear command byte
         bra.s    sp_fbyte          ; loop back

; character is other than IAC

spf_niac tst.b    (a3)              ; flag is LT when still in detection phase
         bge.s    spf_rts           ; return otherwise
         sf       (a3)              ; cancel detection phase
spf_ret  sf       got_iac-iac_stat(a3) ; return from escaped IAC; cancel flag
spf_rts  rts                        ; return

; Previous character was IAC, now consider command

spf_cmd  cmpi.b   #IAC,d1           ; current char is IAC escape?
         beq.s    spf_ret           ; yes, clear flag and return escaped IAC char
         move.b   got_cmd-iac_stat(a3),d2 ; got command byte already?
         bne.s    spf_opt           ; yes, consider option
         cmpi.b   #T_WILL,d1        ; command is WILL/WONT/DO/DONT?
         bcs.s    spf_clr           ; no, eat it
         move.b   d1,got_cmd-iac_stat(a3) ; else, store it
         bra      sp_fbyte          ; loop back for next
spf_clr  sf       got_iac-iac_stat(a3) ; clear flag
         bra      sp_fbyte          ; and loop back

; consider Telnet command (either WILL or DO, drop other commands)
; for BINARY, ECHO and Suppress Go-Ahead options confirm WILL with DO v.v.
; for other options refuse them (answer WILL with DONT and DO with WONT)

spf_opt  cmpi.b   #T_WILL,d2
         beq.s    spf_opt2
         cmpi.b   #T_DO,d2
         bne.s    spf_clr           ; ignore other than WILL or DO
spf_opt2 cmpi.b   #T_BINARY,d1
         beq.s    spf_conf
         cmpi.b   #T_SUPGA,d1
         beq.s    spf_conf          ; confirm BINARY, ECHO or SUPGA, deny others
         cmpi.b   #T_ECHO,d1
         bne.s    spf_deny
         cmpi.b   #T_WILL,d2        ; for ECHO, only confirm DO (terminals shouldn't echo!)
         beq.s    spf_deny
spf_conf ext.w    d1                ; make D1 word-sized
         tst.b    conf_var-iac_stat(a3,d1.w) ; Have we already confirmed this option?
         bne.s    spf_clr           ; yes, stay silent
         st       conf_var-iac_stat(a3,d1.w) ; else, set flag
         eori.b   #%00000110,d2     ; flipping bits 1 and 2 flips WILL/DO - clever!
         bra.s    spf_send

spf_deny ext.w    d2                ; extend D2.W to -5 for WILL or -3 for DO
         addq.w   #$100-T_WILL,d2   ; D2 is now 0 for WILL and 2 for DO
         move.b   spf_otab(pc,d2.w),d2 ; get DONT or WONT for WILL and DO
spf_send subq.l   #4,a7             ; make room on stack for 4 chars (actually 3)
         move.l   a7,a1
         move.b   #IAC,(a1)         ; IAC char
         move.b   d2,1(a1)          ; WILL/DO/WONT/DONT as appropriate
         move.b   d1,2(a1)          ; The option itself
         moveq    #3,d2             ; We have three bytes to send
         move.l   d3,-(a7)          ; save timeout for sp_fbyte!
         moveq    #-1,d3            ; ensure it gets sent
         moveq    #io.sstrg,d0      ; send string
         trap     #3
         move.l   (a7)+,d3          ; restore original timeout
         addq.l   #4,a7             ; tidy stack
         bra      spf_clr           ; clear flag and loop back

spf_otab dc.b     T_DONT,0,T_WONT,0

; Send a byte

sp_sbyte moveq    #io.sbyte,d0
         lea      iac_stat(pc),a1
         tst.b    (a1)              ; are we observing IACs?
         beq.s    spb_out           ; no
         cmpi.b   #IAC,d1           ; test for IAC char
         bne.s    spb_out
sps_iac  lea      iac_esc(pc),a1    ; send double IAC atomic
         moveq    #2,d2
         moveq    #io.sstrg,d0
spb_out  trap     #3
spb_rts  rts

iac_esc  dc.b     IAC,IAC

; Send a string
; We'll scan it for IAC first so we can send it as a string up to the IAC char

sp_sstrg move.b   iac_stat(pc),d0   ; are we observing IACs?
         beq.s    sps_out           ; no
sps_agn  move.w   d2,d0             ; initial length
         move.l   a1,a2             ; start of string
sps_loop subq.w   #1,d0             ; decrement
         blt.s    sps_out           ; end reached
         cmpi.b   #IAC,(a2)+        ; test for IAC
         bne      sps_loop          ; loop unless found
         move.w   d2,-(a7)          ; save length
         move.l   a2,d2
         sub.l    a1,d2             ; get length of string up to and including IAC
         sub.w    d2,(a7)           ; subtract from initial length
         subq.w   #1,d2             ; length before IAC
         ble.s    sps_rest          ; do not print a null string
         moveq    #io.sstrg,d0
         trap     #3                ; send string
sps_rest bsr      sps_iac           ; followed by double IAC
         move.l   a2,a1             ; step past IAC
         move.w   (a7)+,d2          ; restore remaining length
         bgt.s    sps_agn           ; loop back for any remaining part
         rts

; no (more) IACs found, send (remaining) string

sps_out  moveq    #io.sstrg,d0
         trap     #3
         rts

; The following entries check for the precense of an extended SER-driver
; If no extended driver, they return ERR.NI

sp_flush
sp_dump
sp_parit
sp_flow
sp_dcd
         moveq    #err.ni,d0
         rts

* Get channel ID or open channel

openchan move.l   chanid(pc),a0
         move.w   a0,d0             Channel already open?
         bmi.s    opench_2          No, skip
         move.l   d1,-(a7)
         moveq    #-1,d3
         bsr      sp_dump           Clear output- and input buffers
         bsr      purge_in
         cmpi.l   #err.ef,d0        EOF?
         beq.s    opench_c          Yes, jump to close and re-open it
         moveq    #0,d1
         bsr      sp_parit          Ensure no parity
         moveq    #1,d1
         bsr      sp_dcd            And enable DCD detect
         move.l   (a7)+,d1          Restore job ID
         moveq    #0,d0             Return OK
         bra.s    opench_r
opench_c bsr.s    close_ch          Channel was EOF so close it
         move.l   (a7)+,d1
opench_2 moveq    #io.open,d0
         moveq    #0,d3
         lea      tcpname(pc),a0
         trap     #2                Open the channel
         tst.l    d0
         beq.s    opench_3
         move.l   d0,-(a7)
         suba.l   a0,a0
         print    {'QSPILTCP: openchan returned error: '}
         move.l   (a7)+,d0
         move.w   ut_err,a2
         jsr      (a2)
         bra.s    opench_r
opench_3 lea      chanid(pc),a1
         move.l   a0,(a1)           and store ID
         bsr.s    purge_in          Purge input (required for Minnie!)
         moveq    #-1,d3
         bsr      sp_flush          This checks for extended driver
         tst.l    d0
         beq.s    opench_r
         lea      ext_drvr(pc),a1   ; no extended driver, reset flag
         sf       (a1)
         moveq    #0,d0
opench_r rts

; Close channel

close_ch move.l   chanid(pc),a0     ; get channel ID
         move.w   a0,d0             ; is it valid?
         bmi.s    close_ok          ; no, skip
         moveq    #io.close,d0
         trap     #2                ; Close the channel
         moveq    #-1,d0
         lea      chanid(pc),a0
         move.l   d0,(a0)           ; ...and set ID to -1
close_ok moveq    #0,d0
         rts

; Pause for D3 frames
                                    
pause    movem.l  d1/a0-a1,-(a7)
         moveq    #mt.susjb,d0
         moveq    #-1,d1
         suba.l   a1,a1
         trap     #1
         movem.l  (a7)+,d1/a0-a1
         rts

; Purge input buffer

purge_in moveq    #0,d3
         moveq    #io.fbyte,d0
         trap     #3
         tst.l    d0
         beq      purge_in
         rts

; Message and variables section

         SECTION  MSG

CHANID   DC.L     -1                ; channel ID
EXT_DRVR DC.B     0                 ; indicates extended SER driver

; the following 3 bytes should be kept in order!

iac_stat dc.b     0                 ; Telnet IAC status
got_iac  dc.b     0
got_cmd  dc.b     0                 ; Got Telnet IAC escape (receive)

; flags for Telnet options

conf_var ds.w     0                 ; next vars on a word boundary
conf_bin dc.b     0                 ; Confirmed binary transmission option (0)
conf_ech dc.b     0                 ; Confirmed echo option (1)
         dc.b     0                 ; gap
conf_sup dc.b     0                 ; Confirmed Suppress Go-Ahead option (3)

         END

