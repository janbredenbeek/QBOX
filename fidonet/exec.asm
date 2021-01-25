* exec: load & execute a [list of] QDOS program[s] with I/O channels and/or
*       commandline
*
* Entry: D6 priority for executed job(s)
*        D7 wait flag (0 execute in parallel, -1 wait for completion)
*        A1 ptr to NULL-terminated string in format
*        A2 ptr to function to be called before execution of each prg:
*                  D1: job ID
*                  A0: JB.START of job
*                  A1: ptr to command line
*                  A5: ptr to job's stack (JB.A7 updated after return)
*
*        progname [command string]
* or     @proglist
*
* proglist: Name of batch file containing one or more program specifications

         include  flp1_qdos_in_mac

         section  code

         xdef     exec

exec     move.l   a1,a5
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
         suba.w   #80,a7
exb_loop moveq    #80,d2
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
         tst.l    d0
         bne.s    exb_end
         bra      exb_loop
exb_ok   moveq    #0,d0
exb_end  adda.w   #80,a7
         bra.s    exec_end
exec_ok  moveq    #0,d0
exec_end tst.l    d0
         rts

exec_one bsr      getfname
         moveq    #-1,d1
         moveq    #IO.SHARE,d3
         qdos     io.open
         bsr      popstack
         tst.l    d0
         bne      exec_end
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
         bne.s    exe_cl
         moveq    #ERR.BP,d0
         subq.b   #1,d1
         bne.s    exe_cl
         move.l   a0,-(a7)
         moveq    #-1,d1
         suba.l   a1,a1
         qdos     mt.cjob
         move.l   a0,a1
         move.l   (a7)+,a0
         tst.l    d0
         bne.s    exe_cl
         move.l   d1,d4
         moveq    #-1,d3
         qdos     fs.load
         tst.l    d0
         beq.s    exe_cl
         movem.l  d0/a0,-(a7)
         move.l   d4,d1
         qdos     mt.frjob
         movem.l  (a7)+,d0/a0
exe_cl   move.l   d0,-(a7)
         qdos     io.close
         move.l   (a7)+,d0
         bne      exec_end
         bsr.s    skipspc
         move.l   d4,d1
         moveq    #0,d2
         qdos     mt.jinf
         move.l   a2,d0
         beq.s    exec_cmd
         move.l   d4,d1
         move.l   a5,a1
         move.l   $5c-$68(a0),a5
         movem.l  d4/d6-d7/a0/a2/a4,-(a7)
         jsr      (a2)
         movem.l  (a7)+,d4/d6-d7/a0/a2/a4
         move.l   a5,$5c-$68(a0)
         tst.l    d0
         beq.s    exec_act
         move.l   d0,-(a7)
         move.l   d4,d1
         qdos     mt.frjob
         move.l   (a7)+,d0
         bra      exec_end
exec_cmd move.l   a5,a1
exec_nul tst.b    (a5)+
         bne      exec_nul
         move.l   a5,d1
         sub.l    a1,d1
         subq.l   #1,d1
         moveq    #1,d0
         add.l    d1,d0
         bclr     #0,d0
         move.l   $5c-$68(a0),a5
         suba.l   d0,a5
         move.l   a5,$5c-$68(a0)
         clr.w    (a5)+
         move.w   d1,(a5)+
         bra.s    exec_cpy
exec_cp  move.b   (a1)+,(a5)+
exec_cpy dbf      d1,exec_cp
exec_act move.l   d4,d1
         move.b   d6,d2
         move.w   d7,d3
         qdos     mt.activ
         bra      exec_end

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

popstack move.l   (a7)+,a1
         move.w   (a7)+,d1
         addq.w   #1,d1
         bclr     #0,d1
         adda.w   d1,a7
         jmp      (a1)

         end

