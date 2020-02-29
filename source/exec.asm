* exec: load & execute a [list of] QDOS program[s] with I/O channels and/or
*       commandline
*
* Entry: D6 priority for executed job(s)
*        D7 wait flag (0 execute in parallel, -1 wait for completion)
*        A0 ptr to NULL-terminated string in format
*           progname [command string]
*           or @proglist (name of batch file)
*
*        A2 ptr to function for cmdline preprocessing:
*           Call regs:   D1 length of initial cmdline
*                        A0 ptr to filename (QDOS string)
*                        A1 ptr to cmdline (NULL-terminated)
*           Return regs: D1/A1 updated if necessary
*
*        A3 ptr to function for opening I/O channels:
*           Call regs:   D1: job ID
*                        D5: 0
*                        A0: ptr to JB.START of job
*                        A1: ptr to command line (before preprocessing)
*                        A5: ptr to job's stack
*           Return regs: D5: must be incremented for each channel opened
*                        A5: updated ptr to job's stack
*
*        A2 and/or A3 may be zero if appropriate function not needed

         include  win1_qdos_in_mac

         section  code

         xdef     exec

exec     move.l   a0,a5
         bsr      skipspc
         beq.s    exec_ok
         cmpi.b   #'@',(a5)
         bne.s    exec_one
         addq.w   #1,a5
         bsr      getfname
         moveq    #-1,d1
         moveq    #IO.SHARE,d3
         qdos     io.open
         bsr      popstack
         tst.l    d0
         bne.s    exec_end
         move.l   a0,a4
         suba.w   #128,a7
exb_loop moveq    #127,d2
         moveq    #-1,d3
         move.l   a4,a0
         move.l   a7,a1
         qdos     io.fline
         cmpi.l   #ERR.EF,d0
         beq.s    exb_ok
         tst.l    d0
         bne.s    exb_end
         clr.b    -1(a1)
         suba.w   d1,a1
         move.l   a1,a5
         bsr.s    exec_one
         bne.s    exb_end
         bra      exb_loop
exb_ok   moveq    #0,d0
exb_end  move.l   d0,-(a7)
         move.l   a4,a0
         qdos     io.close
         move.l   (a7)+,d0
         adda.w   #128,a7
         bra.s    exec_end
exec_ok  moveq    #0,d0
exec_end tst.l    d0
         rts

exec_one bsr      getfname
         moveq    #-1,d1
         moveq    #IO.SHARE,d3
         qdos     io.open
         tst.l    d0
         bne      eo_end
         moveq    #10,d2
         moveq    #-1,d3
         suba.w   #10,a7
         move.l   a7,a1
         qdos     fs.headr
         move.l   (a7),d2
         move.b   5(a7),d1
         move.l   6(a7),d3
         adda.w   #10,a7
         tst.l    d0
         bne      exe_cl
         moveq    #ERR.BP,d0
         subq.b   #1,d1
         bne      exe_cl
         bsr      skipspc
         move.l   a5,a1
exe_flen tst.b    (a1)+
         bne      exe_flen
         move.l   a1,d1
         move.l   a5,a1
         sub.l    a1,d1
         subq.w   #1,d1
         move.l   a2,d0
         beq.s    exe_cjob
         movem.l  d2-d7/a0/a2-a5,-(a7)
         lea      11*4(a7),a0
         jsr      (a2)
         movem.l  (a7)+,d2-d7/a0/a2-a5
         tst.l    d0
         bne.s    exe_cl
exe_cjob move.l   a0,-(a7)
         move.l   a1,-(a7)
         move.l   d1,-(a7)
         add.l    d1,d3             add cmdline length to dataspace
         addq.l   #3,d3             ... including length word
         bclr     #0,d3             ... and make sure total is even
         moveq    #-1,d1
         suba.l   a1,a1
         qdos     mt.cjob
         tst.l    d0
         beq.s    exe_cmdl
         addq.l   #8,a7
         move.l   (a7)+,a0
         bra.s    exe_cl
exe_cmdl move.l   d1,d4
         move.l   a0,d5
         move.l   $5c-$68(a0),a1
         move.l   (a7)+,d1
         move.l   d1,d0
         addq.l   #3,d0
         bclr     #0,d0
         suba.l   d0,a1
         clr.w    -(a1)
         move.l   a1,$5c-$68(a0)
         addq.l   #2,a1
         move.w   d1,(a1)+
         move.l   (a7)+,a0
         bra.s    exe_cmd2
exe_cmd1 move.b   (a0)+,(a1)+
exe_cmd2 dbra     d1,exe_cmd1
         move.l   (a7)+,a0
         move.l   d5,a1
         moveq    #-1,d3
         qdos     fs.load
         tst.l    d0
         beq.s    exe_cl
         movem.l  d0/a0/a2-a3,-(a7)
         move.l   d4,d1
         qdos     mt.frjob
         movem.l  (a7)+,d0/a0/a2-a3
exe_cl   move.l   d0,-(a7)
         qdos     io.close
         move.l   (a7)+,d0
         bne.s    eo_end
         move.l   a3,d0
         beq.s    exec_act
         move.l   d4,d1
         move.l   d5,a0
         move.l   a5,a1
         move.l   $5c-$68(a0),a5
         addq.l   #2,a5
         moveq    #0,d5
         movem.l  d4/d6-d7/a0/a2-a4,-(a7)
         jsr      (a3)
         movem.l  (a7)+,d4/d6-d7/a0/a2-a4
         move.w   d5,-(a5)
         move.l   a5,$5c-$68(a0)
         tst.l    d0
         beq.s    exec_act
         movem.l  d0/a2-a3,-(a7)
         move.l   d4,d1
         qdos     mt.frjob
         movem.l  (a7)+,d0/a2-a3
         bra.s    eo_end
exec_act move.l   d4,d1
         move.b   d6,d2
         move.w   d7,d3
         movem.l  a2-a3,-(a7)
         qdos     mt.activ
         movem.l  (a7)+,a2-a3
eo_end   bsr.s    popstack
         tst.l    d0
         rts

popstack move.l   (a7)+,a1
         addq.w   #1,(a7)
         andi.w   #$fffe,(a7)
         adda.w   (a7)+,a7
         jmp      (a1)

* skip spaces on cmd line

skip_skp addq.l   #1,a5
skipspc  tst.b    (a5)
         beq.s    skip_end
         cmpi.b   #' ',(a5)
         beq.s    skip_skp
         cmpi.b   #9,(a5)
         beq.s    skip_skp
skip_end rts

getfname bsr      skipspc
         move.l   a5,a1
gfn_lp   move.b   (a1)+,d1
         beq.s    gfn_stk
         cmpi.b   #' ',d1
         beq.s    gfn_stk
         cmpi.b   #9,d1
         bne      gfn_lp
gfn_stk  move.l   a1,d1
         sub.l    a5,d1
         subq.l   #1,d1
         moveq    #3,d0
         add.l    d1,d0
         bclr     #0,d0
         move.l   (a7)+,a1
         suba.l   d0,a7
         move.l   a7,a0
         move.w   d1,(a0)+
         bra.s    gfn_nm2
gfn_nm1  move.b   (a5)+,(a0)+
gfn_nm2  dbf      d1,gfn_nm1
         move.l   a7,a0
         jmp      (a1)

* Get environment variable
* Entry: A0 ptr to variable name (QLSTR)
*        A4 ptr to ptr to environment area
* Exit : D0 0 if found, ERR.NF if not
*        A1 ptr to value (null or after "=") if found
*        A1 ptr to last byte of environment (terminating NULL) if not found
*        D1 smashed, other regs preserved

         xdef     getenv

getenv   move.l   (a4),a1
         move.l   a1,d0
         beq.s    ge_notf
ge_nxvar tst.b    (a1)
         beq.s    ge_notf
         move.l   a0,-(a7)
         move.w   (a0)+,d0
ge_nxchr subq.w   #1,d0
         blt.s    ge_ckend
         move.b   (a1)+,d1
         cmpi.b   #'a',d1
         blo.s    ge_cmp
         cmpi.b   #'z',d1
         bhi.s    ge_cmp
         subi.b   #'a'-'A',d1
ge_cmp   cmp.b    (a0)+,d1
         beq      ge_nxchr
         move.l   (a7)+,a0
         subq.l   #1,a1
ge_skip  tst.b    (a1)+
         bne      ge_skip
         bra      ge_nxvar
ge_ckend move.l   (a7)+,a0
         tst.b    (a1)
         beq.s    ge_found
         cmpi.b   #'=',(a1)+
         bne      ge_skip
ge_found moveq    #0,d0
         rts
ge_notf  moveq    #ERR.NF,d0
         rts

* Set environment variable
* Entry: A0 ptr to variable name (QLSTR)
*        A1 ptr to value (QLSTR), A1 = 0 to remove variable from environment
*        A4 ptr to ptr & length of environment (2 longs)
* Exit : D0 0=OK, ERR.OM if out of memory
*        (A4) & 4(A4) updated
*        D1/A0-A2 smashed

         xdef     setenv

setenv   move.l   a1,-(a7)
         bsr      getenv
         bne.s    se_appnd
         move.l   a1,a2
se_bkup  cmpa.l   (a4),a1
         bls.s    se_nxvar
         tst.b    -(a1)
         bne      se_bkup
         addq.l   #1,a1
se_nxvar tst.b    (a2)+
         bne      se_nxvar
se_cpold move.b   (a2)+,(a1)+
         bne      se_cpold
         tst.b    (a2)
         bne      se_cpold
         clr.b    (a1)
se_appnd move.l   (a7)+,a2
         move.l   a2,d0
         beq.s    se_ok
         moveq    #3,d1
         add.w    (a0),d1
         add.w    (a2),d1
         add.l    a1,d1
         sub.l    (a4),d1
         cmp.l    4(a4),d1
         bls.s    se_cpnew
         addi.l   #512,d1
         movem.l  d1-d3/a0/a2-a3,-(a7)
         moveq    #-1,d2
         qdos     mt.alchp
         tst.l    d0
         bne.s    se_error
         move.l   (a4),a2
         move.l   a0,a1
se_move  move.b   (a2)+,(a1)+
         bne      se_move
         tst.b    (a2)
         bne      se_move
         movem.l  a0-a1,-(a7)
         move.l   (a4),a0
         qdos     mt.rechp
         movem.l  (a7)+,a0-a1
         move.l   a0,(a4)
         movem.l  (a7)+,d1-d3/a0/a2-a3
         move.l   d1,4(a4)
se_cpnew move.w   (a0)+,d0
se_cpnam move.b   (a0)+,(a1)+
         subq.w   #1,d0
         bhi      se_cpnam
         move.b   #'=',(a1)+
         move.w   (a2)+,d0
         bra.s    se_nxval
se_cpval move.b   (a2)+,(a1)+
se_nxval dbf      d0,se_cpval
         clr.b    (a1)+
         clr.b    (a1)+
se_ok    moveq    #0,d0
         rts
se_error movem.l  (a7)+,d1-d3/a0/a2-a3
         tst.l    d0
         rts

         end

