RETADR: BYTE 0
        BYTE 0
        
DATA:   BYTE 0
        BYTE 0
        BYTE 0

RSPTR:  BYTE 0
LPCTR:  BYTE 0

RSPTR:  BYTE 0

# Sequence of numbers will go here ... up to 0x0FF
RSLTS:  BYTE 0     

        # cpu starts execution at 0x100 on reset
        ORG 0x100
        
        lda.i RSLTS # initialise the results pointer
        sta RSPTR
        
        lda.i 0x1    # initialize the data sequence with 1,1
        sta DATA
        sta DATA+1

        lda.i 256-10 # set up a counter to do 10 iterations
        sta LPCTR

LOOP:   jsr FIB
        lda LPCTR
        and.i 0xFF # Clear carry
        add.i 0x1  
        sta LPCTR
        jpz END
        jp  LOOP

END:    halt
 
FIB:        
        sta RETADR
        lxa
        sta RETADR+1
        
        lda DATA
        and.i 0xFF      # CLC
        add DATA+1
        sta DATA+2        
        sta.p RSPTR

        lda RSPTR
        and.i 0xFF
        add.i 0x1
        sta RSPTR

        lda DATA+1
        sta DATA
        lda DATA+2
        sta DATA+1

        lda RETADR+1
        lxa
        lda RETADR
        rts
        
