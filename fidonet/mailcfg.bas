100 REMark MAIL configuration utility v1.19a
110 CLS:PRINT "*** MAIL CONFIGURATION ***":PRINT
120 INPUT "Name of device containing MAIL: ";dev$
130 OPEN#3,dev$&"MAIL"
140 GET#3\14;zone%,net%,node%,point%,sysdir$
150 GET#3\72;log$:GET#3\122;inbd_dir$:GET#3\172;outbd_dir$:GET#3\222;qspil$
160 getstring 272,dial_pre$:getstring 297,dial1$:getstring 322,dial2$
170 getstring 347,dial3$:getstring 372,dial4$
180 CLS:PRINT "Current Values:":PRINT
190 PRINT "FidoNet Zone      : ";zone%
200 PRINT "FidoNet Net       : ";net%
210 PRINT "FidoNet Node      : ";node%
215 PRINT "FidoNet Point     : ";point%
220 PRINT "System Directory  : ";sysdir$
225 PRINT "Log File          : ";log$
230 PRINT "Inbound Directory : ";inbd_dir$
240 PRINT "Outbound Directory: ";outbd_dir$
250 PRINT "QSPIL Driver      : ";qspil$
260 PRINT "Dial Prefix       : ";dial_pre$
270 PRINT "Dial Code 1       : ";dial1$
280 PRINT "Dial Code 2       : ";dial2$
290 PRINT "Dial Code 3       : ";dial3$
300 PRINT "Dial Code 4       : ";dial4$
310 PRINT\"Press ENTER to keep old value"
320 INPUT\"FidoNet Zone      : ";a$:IF a$<>"":zone%=a$
330 INPUT "FidoNet Net       : ";a$:IF a$<>"":net%=a$
340 INPUT "FidoNet Node      : ";a$:IF a$<>"":node%=a$
345 INPUT "FidoNet Point     : ";a$:IF a$<>"":point%=a$
350 INPUT "System Directory  : ";a$:IF a$<>"":sysdir$=a$
355 INPUT "Log File          : ";a$:IF a$<>"":log$=a$
360 INPUT "Inbound Directory : ";a$:IF a$<>"":inbd_dir$=a$
370 INPUT "Outbound Directory: ";a$:IF a$<>"":outbd_dir$=a$
380 INPUT "QSPIL Driver      : ";a$:IF a$<>"":qspil$=a$
390 INPUT "Dial Prefix       : ";a$:IF a$<>"":dial_pre$=a$
400 INPUT "Dial Code 1       : ";a$:IF a$<>"":dial1$=a$
410 INPUT "Dial Code 2       : ";a$:IF a$<>"":dial2$=a$
420 INPUT "Dial Code 3       : ";a$:IF a$<>"":dial3$=a$
430 INPUT "Dial Code 4       : ";a$:IF a$<>"":dial4$=a$
440 PRINT\"Writing new values..."
450 PUT#3\14;zone%,net%,node%,point%,sysdir$
460 PUT#3\72;log$:PUT#3\122;inbd_dir$:PUT#3\172;outbd_dir$:PUT#3\222;qspil$
470 putstring 272,dial_pre$:putstring 297,dial1$:putstring 322,dial2$
480 putstring 347,dial3$:putstring 372,dial4$
490 CLOSE#3
500 PRINT\"Configuration Finished"
510 STOP
515 :
520 DEFine PROCedure getstring(pos,s$)
530 LOCal i$
540   GET#3\pos:s$=""
550   REPeat loop
560     i$=INKEY$(#3,-1):IF NOT CODE(i$):EXIT loop
570     s$=s$&i$
580   END REPeat loop
590 END DEFine getstring
600 :
610 DEFine PROCedure putstring(pos,s$)
620   GET#3\pos
630   PRINT#3;s$;CHR$(0);
640 END DEFine getstring
