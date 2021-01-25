# QBOX FidoNet(tm)-technology network capabilities

This section deals with the FidoNet(tm)-technology Network (hereafter FTN) capabilities of QBOX. QBOX itself can act as an FTN-server, serving inbound connections for receiving mail and files and sending mail and files to remote systems which call (poll) QBOX in an FTN-session.

Outbound FTN-sessions are handled by a commandline program called MAIL (previously called POLL which might actually have been a better name) which dials (or connects to) a remote FTN system, sends mail and files and picks up any mail and files the remote has waiting for it.

For importing and exporting mail from and to FTN-networks, the programs TOSSMAIL and SCANMAIL are used respectively.

Given the fact that FTN-networks have almost gone into oblivion now (except the original FidoNet, see https://fidonet.org), this section will probably only have nostalgic value. However, the MAIL utility might still be useful to transfer files from and to a QBOX (or other FTN-compatible) system, even over TCP/IP (see QSPILTCP in the main section). The protocol used is SEAlink, an enhancement from XMODEM which supports streaming, and might be faster over TCP/IP than the QL's original networking protocol used by FSERVE. A quick test performed between QBOX systems running on a PC (under QPC2) and a Raspberry Pi (under UQLX) resulted in a throughput of 300Kbps - now try this with FSERVE!

The current implementation may need a number of improvements in order to be more useful:

- COMPNL: The source is incomplete and needs improvement (work in progress)
- MAIL: command line options need to be added for sending files directly, without having to manually create _ATT files and a nodelist
- QBOX: handling of inbound file requests needs to be implemented

## File list

| Name         | Description
| ---------    | -----------------------------------------------------------------------
| ARCCRC.IN    | Table with pre-calculated CRC values for SCANARC.ASM
| CHANGES.TXT  | List of changes until version 1.19j
| CLINK.ASM    | SEAlink file transfer
| COMMON.ASM   | Common routines (QNET.LIB)
| COMPNL.ASM   | Nodelist Compiler 
| CRCCITT.IN   | Table with pre-calculated CRC values for XMODEM/SEAlink
| EDITNL.ASM   | Utility to create new NODELIST from NODEDIFF files
| exec.asm     | Execute external programs
| FSC39.H      | FSC-0039 packet header fields
| FTSCPROD.ASM | FTSC assigned product codes
| MACRO.LIB    | Macro library
| MAIL.ASM     | MAIL main source
| MAIL.LINK    | MAIL linker file
| MAIL119J.zip | MAIL 1.19j distribution zip
| mailcfg.bas  | MAIL 1.19j configuration program
| NLUTIL.ZIP   | EDITNL and COMPNL binaries for compiling FTN nodelists
| notes.txt    | Some notes
| PROCNL.ASM   | Nodelist lookup utility
| QBOXMAIL.H   | Header (include) file
| QDOS_IN.MAC  | QDOS definitions, macros etc
| README.md    | This file
| SCANARC.ASM  | SCANMAIL ARC compression routines
| SCANMAIL.ASM | SCANMAIL main source (for scanning and packing echomail)
| SCANMAIL.LINK| SCANMAIL linker file
| SEENBY.ASM   | Utility to modify SEEN-BY lines in echomail
| SESSION.ASM  | FTS-1 session routines
| SETMARK.ASM  | Utility to set high-water marker for SCANMAIL
| TF.ASM       | TempFront mail front-end for QBOX (obsolete, QBOX now has it built in)
| TFconfig     | Configuration utility for TempFront
| TOSS119C.TXT | TOSSMAIL changes list
| TOSSMAIL.ASM | TOSSMAIL main source (for unpacking and importing echomail)
| TOSSMAIL.LINK| TOSSMAIL linker file
