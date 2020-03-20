; window save and restore

; this routines must be called as sd.extop operations

mt.alchp equ      $18
mt.rechp equ      $19
sd.extop equ      9
sd.xmin  equ      $18
sd.ymin  equ      $1a
sd.xsize equ      $1c
sd.ysize equ      $1e
sd.borwd equ      $20
sd.scrb  equ      $32

.text
.even
.globl _wsave
.globl __wsave

_wsave:
__wsave:
         link     a6,#0
         movem.l  d3/a2,-(a7)
         move.l   8(a6),a0
         move.l   12(a6),d3
         move.l   16(a6),a1
         lea      savwin,a2
         moveq    #sd.extop,d0
         trap     #3
         movem.l  (a7)+,d3/a2
         unlk     a6
         tst.l    d0
         bne      ws_err
         move.l   a1,d0
         rts
ws_err:  
         moveq    #0,d0
         rts

scr_addr: 
         movem.w  d0-d1,-(a7)
         move.l   sd.scrb(a0),a1
         lsl.w    #7,d1
         adda.w   d1,a1
         moveq    #15,d7
         and.b    d0,d7             ; d7 = bit position (0 to 7)
         lsl.w    #2,d7
         lsr.w    #4,d0
         lsl.w    #2,d0
         adda.w   d0,a1             ; a1 = screen addr (long word aligned)
         movem.w  (a7)+,d0-d1
         rts

; save window's contents into common heap

; entry: no parameters
; exit : d0 address of save area; 0 if out of memory

savwin:  
         movem.w  (a1)+,d2-d3       ; d2 = width, d3 = height
         movem.w  (a1)+,d0-d1       ; d0 = xorg, d1 = yorg
         bclr     #0,d0
         bclr     #0,d2
         movem.l  d0-d3/a0,-(a7)
         bsr      scr_addr
         move.l   a1,a4             ; top lhs addr to a4
         add.w    d2,d0
         subq.w   #1,d0
         bsr      scr_addr          ; top rhs addr to a1
         move.l   a1,d7
         sub.l    a4,d7
         move.l   d7,d1
         lsr.w    #2,d7
         addq.w   #4,d1             ; d1 = number of bytes per row
         mulu     d3,d1
         addq.l   #8,d1             ; include window coords & size
         moveq    #-1,d2
         moveq    #mt.alchp,d0
         trap     #1                ; reserve space
         move.l   a0,a1
         movem.l  (a7)+,d1-d4/a0
         tst.l    d0
         bne      sw_end
         move.l   a1,a2
         movem.w  d1-d4,(a2)
         addq.l   #8,a2
sw_rowlp: 
         move.w   d7,d0
         move.l   a4,a3
sw_wloop: 
         move.l   (a3)+,(a2)+
         dbf      d0,sw_wloop
         adda.w   #128,a4
         subq.w   #1,d4
         bgt      sw_rowlp
         moveq    #0,d0
sw_end:  
         rts

.globl _wrest
.globl __wrest

_wrest:
__wrest:
         link     a6,#0
         movem.l  d3/a2,-(a7)
         move.l   8(a6),a0
         move.l   12(a6),d3
         move.l   16(a6),a1
         lea      restwin,a2
         moveq    #sd.extop,d0
         trap     #3
         movem.l  (a7)+,d3/a2
         unlk     a6
         rts

; restore window's contents from heap

; entry: a1 base of heap contents
; exit: none, d1 and a1 smashed

restwin: 
         movem.w  (a1)+,d0-d3
         move.l   a1,-(a7)
         bsr      scr_addr
         move.l   a1,a4
         lea      masktbl,a2
         move.l   0(a2,d7.w),d4
         add.w    d2,d0
         subq.w   #1,d0
         bsr      scr_addr
         move.l   a1,d1
         sub.l    a4,d1
         lsr.w    #2,d1
         move.l   (a7)+,a1
         move.l   a0,-(a7)
         move.l   a1,a0
         move.l   4(a2,d7.w),d6
         subq.w   #1,d1
         bge      rw_1
         eor.l    d6,d4
rw_1:    
         move.l   d4,d5
         not.l    d5
         move.l   d6,d7
         not.l    d6
rw_rowlp: 
         move.l   a4,a2
         move.l   (a1)+,d0
         and.l    d4,d0
         and.l    d5,(a2)
         or.l     d0,(a2)+
         move.w   d1,d0
         bge      rw_cmp
         bra      rw_next
rw_wloop: 
         move.l   (a1)+,(a2)+
rw_cmp:  
         dbf      d0,rw_wloop
         move.l   (a1)+,d0
         and.l    d6,d0
         and.l    d7,(a2)
         or.l     d0,(a2)
rw_next: 
         adda.w   #128,a4
         subq.w   #1,d3
         bgt      rw_rowlp
         moveq    #mt.rechp,d0
         trap     #1
         move.l   (a7)+,a0
         moveq    #0,d0
         rts

masktbl: 
         dc.l     $ffffffff,$7f7fffff,$3f3fffff,$1f1fffff
         dc.l     $0f0fffff,$0707ffff,$0303ffff,$0101ffff
         dc.l     $0000ffff,$00007f7f,$00003f3f,$00001f1f
         dc.l     $00000f0f,$00000707,$00000303,$00000101,$00000000

         end
