MACRO   JSR (_n_)
        lda.i _n_ >>8
        axb
        lda.i _n_ &0xFF
        jal        
ENDMACRO

TMP:    BYTE 0x0
        ORG 0x100
        lda.i 0x10
        axb
        lda.i 0x11
        adc
        not
        sta TMP
        JSR(SUB)
        
        halt

SUB:    jal     # Jump back
