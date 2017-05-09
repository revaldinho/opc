MACRO CLC ()
        and.i 0xFF
ENDMACRO

MACRO SEC()
        lda.i 0xFFFF
        add.i 0x1
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

        ORG 0x0000

        lda.i RSLTS # initialise the results pointer
        sta RSPTR
        lda.i RETSTK # initialise the return address stack
        sta RETSP

        lda.i 0x0000   # initialize the data sequence with 0x0000,0x0001 (LSByte first)
        sta DATA
        lda.i 0x0001
        sta DATA+1
        sta.p RSPTR
        INCPTR(RSPTR,1)
        lda.i 0x0
        sta.p RSPTR
        INCPTR(RSPTR,1)
        lda.i -23 # set up a counter
        sta LPCTR

LOOP:   jsr FIB

        INCPTR(LPCTR,1)
        jpz END
        jp  LOOP

END:    halt


FIB:
        sta.p RETSP         
        INCPTR(RETSP,1)
        CLC()
        lda DATA
        add DATA+1
        sta DATA+2
        sta.p RSPTR
        INCPTR( RSPTR,1)

        lda DATA+1
        sta DATA+0
        lda DATA+2
        sta DATA+1

        DECPTR(RETSP,1)
        lda.p RETSP        # retrieve the upper ret addr byte
        rts                # ...and finally return!

        ORG 0x100
        # 16 b word store for the addition routine
DATA:   WORD 0, 0
        WORD 0, 0
        WORD 0, 0
TMP:    WORD 0

# Loop counter variable
LPCTR:  WORD 0

# 8 deep return address stack and stack pointer
RETSP:  WORD 0
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSPTR:  WORD 0
RSLTS:  WORD 0

