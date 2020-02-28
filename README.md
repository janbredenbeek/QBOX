# QBOX

## Description

A Bulletin Board System for the Sinclair QL, originally written in 1987-94 for analogue modems. But thanks to its **QSPIL** interface, it can be made to work with TCP/IP too! You just need an emulator supporting the TCP device. QBOX has been tested successfully with [QPC2](https://www.kilgus.net/qpc/), [SMSQmulator](http://www.wlenerz.com/SMSQmulator/), and [uqlx](http://www.dilwyn.me.uk/emu/index.html#uQLx_for_Linux_etc.). In theory, it should work with [Qemulator](http://www.terdina.net/ql/q-emulator.html) too but tests with this emulator haven't been successful so far (Qemulator just hangs when waiting for an incoming connection, and when it comes in it gets disconnected immediately).

## Installation

The file QBOXRUN.ZIP is a ready-to-run installation for use with QPC2, SMSQmulator or UQLX. It contains a QBOXRUN.WIN file which contains the QBOX system files, example files and the complete archive of QL file areas of the original QBOX BBS, maintained by Jan Bredenbeek from 1987 to 2003. You should configure your emulator to make device win8_ point to this container file. If you want to use a different device, you have to run QSETUP and change the directories manually. Also, you have to edit the files MAREAS_BBS and FAREAS_BBS which contain the names of the directories where the MESSAGES_BBS files (for MAREAS_BBS) and FILES_BBS reside. You can also use QSETUP to change any settings to suit your preferences.

You can now do a local 'test run' by entering **EX win8_QBOX;'-L -T -D win8_'** from the command line. A terminal program opens and you will see the login page displayed; now you can log in using the user name 'Sysop' and password 'QBOX' (don't forget to change it if you are going to do anything serious!).

You can edit the files LOGON_BBS, LOGOFF_BBS, BULLETIN_BBS, INFOxx_BBS to suit. In order to create new message or file areas, you have to edit the text files MAREAS_BBS and FAREAS_BBS. Each line contains a message or file area definition, which must start with the device and directory name containing the messages or files, followed by a space and the description (see the documentation files for more info). In a message area directory, there should be a file named MESSAGES_BBS (when creating an area you should copy the file EMPTY_MESSAGES_BBS to this directory). In a file area directory, there should be a file FILES_BBS which is a text file containing file names and descriptions of files within the area.

Finally, to start the online BBS, enter **EX win8_QBOX;'-D win8_'** from the command line. If you do **PROG_USE win8_** first then you can simply enter **EX QBOX** as QBOX searches the Toolkit II default program and data directories for its SETUP_BBS file. If all is well then QBOX will start up and print a message 'Waiting for call'. You can now try to connect by starting a Telnet session to the IP address of the machine where QBOX is running, on port 5000 (default setting on QSPILTCP). If QBOX is running on the same machine, use **localhost** or **127.0.0.1** to connect.

## Use in a TCP/IP environment

QBOX was originally written for use with analogue modems, but designed in such a way that the low-level routines which communicate with the 'outside world' were isolated in a so-called QSPIL driver (QSPIL stands for QBOX Serial Port Interface Layer, which is a bit akin to the FOSSIL interface used by DOS-based BBS software at the time). The reason for this was the variety of modems originally in use before most modem manufacturers settled for the 'Hayes' (AT-command) standard. From 1990 onwards, these routines were incorporated in the QSPHAYES driver which is a configurable driver for Hayes-compatible modems.

Now that analogue modems are obsoleted by IP networks and popular QL emulators support communication via the TCP device, the QSPIL interface comes in handy as interface layer between QBOX and IP networks. And so, QSPHAYES has been replaced by QSPILTCP! There is no need to emulate a Hayes-compatible modem as QSPIL can interface to the TCP device directly. Some functions have limitations though depending on the emulator used: 

* Versions of SMSQ/E up to and including 3.35 (used by QPC2 and SMSQmulator) do not signal a TCP connection closed by the client back to QBOX, leading to a hung session when a user closes the connection without properly logging off. Eventually, QBOX will force a user log-off after a timeout of about 3 minutes. In SMSQ/E 3.36 and later, this bug will have been fixed.

* UQLX does signal a closed TCP connection back to QBOX (giving EOF on input), but has a quirk when the connection was closed by QBOX itself after a user log-off: while the closed TCP connection is in a TIME_WAIT state (usually for one minute after closing), uqlx doesn't allow re-binding of a socket to wait for a new connection. QSPILTCP will detect this and pause for one minute before trying again (giving a log message). During this period, it cannot accept new connections.

* On UQLX, it is not possible for QSPILTCP to listen on ports below 1024 since these are 'privileged' ports which can only be bound to by processes running as root. (You can of course circumvent this by running UQLX as root, but this is not desirable from a security point of view). For this reason, QSPILTCP will by default listen on port 5000. If you really need to listen on a privileged port, use iptables to redirect this port to the port QSPILTCP listens on (Example: sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j DNAT --to-destination :5000)

* Note that UQLX releases earlier than 2018-10-28 have a bug in the TCP driver (it was incorrectly named \*tcp), causing QSPILTCP to fail. The corrected release can be downloaded [here](http://www.dilwyn.me.uk/emu/uqlx2018a.zip).

* Qemulator will hang when QBOX starts listening on a TCP port. When I made a connection to this port, QBOX was able to signal this but Qemulator then immediately disconnected. So far, tests with Qemulator haven't been successful.

When an incoming connection has been established, QSPILTCP monitors the first bytes of the incoming data stream for Telnet IAC characters ($FF). If detected, it will send the Telnet options Binary Transmission (WILL/DO), Echo (WILL), and Suppress Go-Ahead (WILL/DO) to initialise the client. This may be changed by editing the teln_opt string. It will also respect the IAC character during send and receive, meaning that a $FF character in the actual data will be escaped by doubling it in the data stream. This will allow file up- and download to work correctly over Telnet sessions when using programs such as TeraTerm or a TCP-to-serial converter such as TCPSER.

If QSPILTCP does not detect the Telnet IAC character during the handshake phase, it will revert to 'raw' mode and send and receive the data 'as-is'. This is fine for terminal programs like QLTERM which can communicate with a Telnet host using redirected I/O but do not support the Telnet IAC escape character by itself. NOTE: you should NOT use the Telnet S\*BASIC procedure in the QLTERM package to start Telnet since this does send a Telnet handshake, which caused QSPILTCP to enable IAC escape which QLTERM doesn't support! Just open a channel using chan=FOP_IN("tcp_A.B.C.D:5000"):EW QLTERM,#chan (of course you should fill in the correct IP address and port number!)

If you want to download files using SEAlink, you might consider turning off the Overdrive option in QSETUP, else it might fail because the large buffers used by TCP connections will cause it to send the whole file at once, causing it to time-out waiting for the acknowledge from the receiver.

Since QBOX was designed to use a modem, it can only handle one connection at a time - subsequent attempts to connect will be refused. However it is still possible to have a remote user *and* a local sysop logged in at the same time. Chat sessions are also supported.

## Configuring QSPILTCP

Although QSPILTCP comes pre-configured with options which I believe are reasonable, it does allow for some configuring. This can either be done by re-assembling the source code (please use the free Quanta/GST assembler followed by the linker to build the binary, do NOT just assemble the _asm with -NOLINK option), or patching the configuration data at the beginning of the QSPILTCP binary using a binary file editor or (B)PUT commands in S\*BASIC. The latter should of course be done with care or you'll end up with an unusable QSPIL. The QSETUP program hasn't been updated so far to include a more user-friendly way, but might be somewhere in the future.

The options which are configurable are:


| Offset | Type | Property                                                                  |
|:------:| ---- |:------------------------------------------------------------------------- |
|   72   | word | Check value, should be 301 decimal                                        |
|   84   | word | TCP port to listen on (default 5000)                                      |
|   86   | long | IP address to listen on (default 0.0.0.0 for 'all')                       |
|   98   | byte | Data transfer protocol to use: 0 raw TCP, 1 Telnet, -1 adaptive (default) |
|  100   |string| Telnet commands to send on connect, only used when above byte is nonzero. Length word followed by max. 30 bytes|
|  132   |string| Name of TCP device (length word followed by max. 30 bytes). Default 'TCP_'|
|  164   |string| Name of SCK device (length word followed by max. 30 bytes). Default 'SCK_'|

## Securing your system

First, a word of warning: QBOX was designed in the 1980s, when security standards were quite different from what we would consider today as minimal. Communication is not encrypted and even the user's password is stored in the USERS_BBS database as plain text! I would recommend *not* using it for communication which should remain private, and even not exposing its IP address to the world. You have been warned!

If you still want to run a publicly available BBS, consider using SSH (Secure Shell) as an extra layer of security. On Linux systems, an SSH server is usually already installed by default. It can be easily configured as a gateway for QBOX using the following steps:

1. Create a new user which will be used as login for the gateway to QBOX. A good example might be 'qbox' (note that, as usual in Linux systems, the name is case sensitive). Assign a password that you can communicate to users (it doesn't have to be secret since users will authenticate themself within QBOX after logging in to SSH). Do *not* use this account for any other purposes; even running the QBOX environment under UQLX should be done under a different user account.

2. Next, edit the /etc/ssh/sshd_config file and include the following lines:

   Match User qbox
        DisableForwarding yes
        PermitTTY yes
        ForceCommand telnet -E -8 localhost 5000

This locks down the user qbox so after the SSH login it forces execution of the telnet command to connect to the BBS running on the same machine on port 5000. Of course, if your BBS is running on a different port or even a different machine, you should replace 'localhost 5000' to suit. The -E switch avoids the user being able to use the Telnet escape character to escape into Telnet command mode.

## Further reading

If you want to use a QL or compatible system as a BBS client using TCP/IP, please read the [QL-client.md] file for more info.

Jan Bredenbeek, February 2020.
