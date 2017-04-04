TOP   ORG     0x00
      lda.i   0x00
      sta     RESULT
      not     RESULT
      sta     RESULT
      lda.i   0x0F0
LOOP  add.i   0x1
      jpz     NEXT
      jp      LOOP
NEXT  and.i   0x33
      jp END
      add.i   0x01

END   halt

      ORG 0x200
RESULT  BYTE  0x00
