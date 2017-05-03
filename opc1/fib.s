MACRO INCPTR ( _p_ , _v_ )
        lda _p_
        and.i 0xFF # Clear carry
        add.i _v_
        sta _p_
ENDMACRO

MACRO ADD16 ( _data0_, _data1_, _result_)
        lda _data0_
        and.i 0xff   # CLC
        add _data1_
        sta _result_
        lda _data0_+1
        add _data1_+1
        sta _result_+1
ENDMACRO


RETADR: BYTE 0
        BYTE 0

DATA:   BYTE 0, 0
        BYTE 0, 0
        BYTE 0, 0

RSPTR:  BYTE 0
LPCTR:  BYTE 0

# Sequence of numbers will go here ... up to 0x0FF
RSLTS:  BYTE 0

        # cpu starts execution at 0x100 on reset
        ORG 0x100

        lda.i RSLTS # initialise the results pointer
        sta RSPTR

        lda.i 0x1    # initialize the data sequence with 0x0001,0x0001 (LSByte first)
        sta DATA
        sta DATA+2
        lda.i 0x0
        sta DATA+1
        sta DATA+3

        lda.i 256-20 # set up a counter to do 10 iterations
        sta LPCTR

LOOP:   jsr FIB

        INCPTR(LPCTR,1)
        jpz END
        jp  LOOP

END:    halt


FIB:
        sta RETADR
        lxa
        sta RETADR+1

        ADD16( DATA, DATA+2, DATA+4)
        lda DATA+4
        sta.p RSPTR
        INCPTR( RSPTR,1)
        lda DATA+5
        sta.p RSPTR
        INCPTR ( RSPTR, 1)

        lda DATA+2
        sta DATA
        lda DATA+3
        sta DATA+1
        lda DATA+4
        sta DATA+2
        lda DATA+5
        sta DATA+3

        lda RETADR+1
        lxa
        lda RETADR
        rts
