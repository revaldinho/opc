TOP   ORG     0x00
      lda.i   0x00
      not
      sta     RESULT

      and.i   0x33
      jp END
      add.i   0x01

END   halt

      ORG 0x200
RESULT  BYTE  0x00
