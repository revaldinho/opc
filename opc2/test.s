TMP:    BYTE 0x0
        ORG 0x100
        lda.i 0x10
        axb
        lda.i 0x11
        adc
        not
        sta TMP
        
        lda.i SUB>>8
        axb
        lda.i SUB&0xFF
        jal
        
        halt

SUB:    jal     # Jump back
