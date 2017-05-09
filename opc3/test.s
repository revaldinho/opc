
TOP:    ORG     0x0000
        lda.i   0x00
        sta     RESULT                # Comments ignored but preserved in listing
        not     RESULT
        sta     RESULT+1
        lda.i   (10*2+9) << 7 & 0xFF  # Demo of Python expression parsing
        and.i   0xFF                  # CLC - always clear carry before add
        lda.i   0xFFF0
LOOP:   add.i   0x01
        jpz     NEXT
        jp      LOOP
NEXT:   and.i   0x33
        jp      END
        add.i   0x01


END:    jsr     SUB1
        halt

SUB1:   sta MEM1    # save return address
        lda.i 0x1
        bsw
        lda.i 0xFFFF
SUBLP:  add.i 0x01
        jpc SUBEXT
        jp SUBLP
SUBEXT: lda MEM1    # retrieve return address
        rts

DATA:   ORG 0x30


MEM1:   WORD 0x00
MEM2:   WORD 0x00

RESULT: WORD  0x00
        WORD 1,2,3
        WORD 5,6,7,8,9,10
        WORD 555
        WORD 0x0123
        WORD 0o4567

DATAEND
