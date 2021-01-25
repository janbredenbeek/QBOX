* QBOSS SETMARK UTILITY
* FEBRUARY 22, 1989

         INCLUDE  FLP1_QDOS_IN_MAC

         DATA     512

         SECTION  CODE

START    BRA.S    START2
         DS.B     6-(*-START)
         DC.W     $4AFB
         STRING$  'SETMARK'

START2   ADDA.L   A4,A6
         MOVE.L   A7,A5
         MOVE.W   (A5)+,D0
         SUBQ.W   #1,D0
         BNE.S    SM_BADP
         MOVE.L   (A5)+,A0
         MOVEQ    #14,D2
         MOVEQ    #-1,D3
         MOVE.L   A6,A1
         QDOS     FS.HEADR
         TST.L    D0
         BNE.S    ERR_EXIT
         MOVE.W   (A5)+,D7
         BEQ.S    SM_BADP
         EXG      A0,A5
         CMPI.B   #'+',(A0)
         BEQ.S    SM_SKIP
         CMPI.B   #'-',(A0)
         BEQ.S    SM_SKIP
         CLR.B    9(A6)
SM_SKIP  SUBA.L   A6,A0
         ADD.L    A0,D7
         MOVE.L   A7,A1
         SUBA.L   A6,A1
         SUBQ.W   #2,A7
         MOVE.W   CN_DTOI,A2
         JSR      (A2)
         MOVE.W   (A7)+,D1
         TST.L    D0
         BNE.S    ERR_EXIT
         ADD.B    D1,9(A6)
         MOVEQ    #-1,D3
         EXG      A0,A5
         MOVE.L   A6,A1
         QDOS     FS.HEADS
ERR_EXIT MOVEQ    #-1,D1
         MOVE.L   D0,D3
         QDOS     MT.FRJOB

SM_BADP  SUBA.L   A0,A0
         LEA      BADPMSG,A1
         MOVE.W   UT_MTEXT,A2
         JSR      (A2)
         MOVEQ    #ERR.BP,D0
         BRA      ERR_EXIT

BADPMSG  STRING$  {'Use EW SETMARK,<file name>;"<position>"',10}

         DC.W     0

         END
