TOP     ORG     0x00
        lda.i   0x00
        sta     RESULT
        not     RESULT
        sta     RESULT+1
        lda.i   10 * 2 + 9 <<7 & 0xFF
LOOP    add.i   0x1
        jpz     NEXT
        jp      LOOP
NEXT    and.i   0x33
        jp END
        add.i   0x01

END     halt

        ORG 0x200
RESULT  BYTE  0x00
        BYTE 1,2,3
        BYTE 5,6,7,8,9,10
