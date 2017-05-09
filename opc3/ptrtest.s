        ORG   0x0000
        lda.i RESLOC
        sta   RESPTR

        lda.i 0xF0
        sta.p RESPTR
        lda.p RESPTR
        lda.i RESLOC+1
        sta   RESPTR
        lda.i 0xF1
        sta.p RESPTR
        lda.p RESPTR
        halt

        ORG 0x10
RESPTR: WORD 0

        ORG 0x20
RESLOC: WORD 0
