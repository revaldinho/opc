
MACRO CLC ()
        and.i 0xFF
ENDMACRO

MACRO SEC()
        lda.i 0x01
        lxa
ENDMACRO

MACRO INCPTR ( _p_ , _v_ )
        CLC()
        lda _p_
        add.i _v_
        sta _p_
ENDMACRO

MACRO DECPTR ( _p_ , _v_ )
        SEC()
        lda _p_
        add.i ~_v_
        sta _p_
ENDMACRO

MACRO ADD16 ( _data0_, _data1_, _result_)
        CLC()
        lda _data0_
        add _data1_
        sta _result_
        lda _data0_+1
        add _data1_+1
        sta _result_+1
ENDMACRO

# 16 b word store for the addition routine
DATA:   BYTE 0, 0
        BYTE 0, 0
        BYTE 0, 0
TMP:    BYTE 0

# Loop counter variable
LPCTR:  BYTE 0

# 8 deep return address stack and stack pointer
RETSP:  BYTE 0
RETSTK: BYTE 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSPTR:  BYTE 0
RSLTS:  BYTE 0

        # cpu starts execution at 0x100 on reset
        ORG 0x100

        lda.i RSLTS # initialise the results pointer
        sta RSPTR
        lda.i RETSTK # initialise the return address stack
        sta RETSP

        lda.i 0x0   # initialize the data sequence with 0x0000,0x0001 (LSByte first)
        sta DATA
        sta DATA+1
        sta DATA+3
        lda.i 0x1
        sta DATA+2
        sta.p RSPTR
        INCPTR(RSPTR,1)
        lda.i 0x0
        sta.p RSPTR
        INCPTR(RSPTR,1)
        lda.i 256-23 # set up a counter
        sta LPCTR

LOOP:   jsr FIB

        INCPTR(LPCTR,1)
        jpz END
        jp  LOOP

END:    halt


FIB:
        sta.p RETSP         # store lower ret addr byte on stack
        lxa                 # get upper ret addr byte into A
        sta TMP             # save it because A and link will get zapped by next instr
        INCPTR(RETSP,1)
        lda TMP             # retrieve upper ret addr byte
        sta.p RETSP         # save it on the stack
        INCPTR(RETSP,1)

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

        DECPTR(RETSP,1)
        lda.p RETSP        # retrieve the upper ret addr byte
        sta TMP            # save it
        DECPTR(RETSP,1)
        lda TMP            # retrieve upper ret addr byte
        lxa                # pop it in the link register
        lda.p RETSP        # get the lower ret addr byte off the stack
        rts                # ...and finally return!
