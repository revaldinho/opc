MACRO   PUSH( _data_)
        push     _data_,r14
ENDMACRO

MACRO   POP( _data_)
        pop      _data_, r14
ENDMACRO

        mov    r14, r0,STACK    # Setup global stack pointer
        mov    r10,r0, DATA0-2  # R10 points to multiplier data (will be preincremented)
        mov    r12,r0, RESULTS  # R12 points to area for results

outer:  inc    r10,2            # increment data pointer by 2
        ld      r2,r10          # check if we reached the (0,0) word
        z.ld    r2,r10,1
        z.mov  pc,r0,end        # .. if yes, bail out
        mov    r11,r0, DATA0    # reset multiplicand pointer
inner:
        mov    r1, r10          # get multiplier address A
        mov    r2, r11          # get multiplicand address B
        mov    r3, r12          # get result area pointer
        jsr    r13, r0, multiply32
next:   inc   r12,4             # increment result pointer by 4
        inc   r11,2             # increment multiplicand address by 2
        ld      r2,r11          # get multiplicand data LSW
        z.ld    r2,r11,1        # get multiplicand data MSW
        z.mov  pc,r0,outer      # if (0,0) then next outer loop
        dec    pc,PC-inner      # else next inner loop

end:
        halt    r0,r0,0x99

        # --------------------------------------------------------------
        #
        # multiply32
        #
        # Entry:
        #       r1 points to block of two bytes holding 32 bit multiplier (A), LSB in lowest byte
        #       r2 points to block of two bytes holding 32 bit multiplicand (B), LSB in lowest byte
        #       r3 points to area of memory large enough to take the 4 byte result
        #       r13 holds return address
        #       (r14 is global stack pointer)
        # Exit
        #       r1..9 uses as workspace registers and trashed
        #       Result written to memory (see above)
        # --------------------------------------------------------------
multiply32:
        PUSH    (r3)
        
        ld      r8, r2, 1       # Get B into r7,r8 (pre-shifted)
        ld      r7, r2
        mov    r6, r0
        mov    r5, r0
        mov    r4, r0          # Get A into r1..r4
        mov    r3, r0
        ld      r2, r1, 1
        ld      r1, r1
        mov    r9, r0,-32      # Setup a loop counter
mulstep32:
        lsr   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        nc.inc pc,mcont-PC
        add   r1,r5
        adc   r2,r6
        adc   r3,r7
        adc   r4,r8
mcont:  inc   r9,1                  # increment counter
        nz.dec pc,PC-mulstep32      # next iteration if not zero
        lsr   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        POP     (r5)
        sto     r1,r5,0         # save results
        sto     r2,r5,1
        sto     r3,r5,2
        sto     r4,r5,3
        mov    pc,r13          # and return


        ORG     0x200
STACK:  WORD 0,0,0,0,0,0,0,0,0  # Reserve some stack space

DATA0:  WORD 0x02,0x04,0x08,0x03
        WORD 0x00,0x09,0x18,0x23
        WORD 0x13,0x03,0x08,0x00
        WORD 0x00,0x44,0x33,0x99
        WORD 0x11,0x00,0xF8,0x03
        WORD 0xC2,0x04,0xAB,0x03
        WORD 0x00,0x00,0x00,0x00        # all zero words to finish

        ORG     0x300
RESULTS:
