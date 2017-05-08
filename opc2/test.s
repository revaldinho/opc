MACRO   JSR (_n_)
        ldb.i _n_ &0xFF
        axb
        ldb.i _n_ >>8
        jal
ENDMACRO

MACRO   CLC ()
        ldb.i 0xFF
        and
ENDMACRO



TMP:    BYTE 0x0
        ORG 0x100
        ldb.i 0x00
        axb
        CLC()
        ldb.i 0x10
        axb
        ldb.i 0x11
        adc
        not
        sta TMP
        JSR(SUB)

        halt

SUB:    jal     # Jump back
