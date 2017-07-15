MACRO   PUSH( _data_, _ptr_)
        sto     _data_,_ptr_
        add   _ptr_,r0,1
ENDMACRO

MACRO   PUSH4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        sto     _d0_,_ptr_
        sto     _d1_,_ptr_,1
        sto     _d2_,_ptr_,2
        sto     _d3_,_ptr_,3
        add   _ptr_,r0,4
ENDMACRO

MACRO   POP( _data_, _ptr_)
        add   _ptr_,r0,-1
        ld      _data_, _ptr_
ENDMACRO

MACRO   POP4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        add   _ptr_,r0,-4
        ld      _d3_, _ptr_
        ld      _d2_, _ptr_,1
        ld      _d1_, _ptr_,2
        ld      _d0_, _ptr_,3
ENDMACRO

MACRO   CLC()
        add r0,r0
ENDMACRO

MACRO   SEC()
        ror r0,r0,1
ENDMACRO

MACRO   ROL( _reg_ )
        adc   _reg_, _reg_
ENDMACRO



        mov    r14, r0,STACK   # Setup global stack pointer
        mov    r10,r0, DATA0-2 # R10 points to multiplier data (will be preincremented)
        mov    r12,r0, RESULTS # R12 points to area for results

outer:  add   r10,r0,2        # increment data pointer by 2
        ld      r2,r10          # check if we reached the (0,0) word
        z.ld    r2,r10,1
        z.mov  pc,r0,end       # .. if yes, bail out
        mov    r11,r0, DATA0   # reset multiplicand pointer
inner:
        mov    r1, r10         # get multiplier address A
        mov    r2, r11         # get multiplicand address B
        mov    r3, r12         # get result area pointer
        mov    r13,r0, next    # save return address
        mov    pc, r0, multiply32      # JSR multiply32
next:   add   r12,r0,4        # increment result pointer by 4
        add   r11,r0,2        # increment multiplicand address by 2
        ld      r2,r11          # get multiplicand data LSW
        z.ld    r2,r11,1        # get multiplicand data MSW
        z.mov  pc,r0,outer     # if (0,0) then next outer loop
        mov    pc,r0,inner     # else next inner loop

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
        PUSH4   (r13,r12,r11,r3,r14)  # save return address, globals r12,r11 and pointer to return data

        ld      r8, r2, 1       # Get B into r7,r8 (pre-shifted)
        ld      r7, r2
        mov    r6, r0
        mov    r5, r0

        mov    r4, r0          # Get A into r1..r4
        mov    r3, r0
        ld      r2, r1, 1
        ld      r1, r1

        mov    r9, r0,-32      # Setup a loop counter
        mov    r11,r0,1        # constant 1 for use in inner loop
        mov    r12,r0,mcont    # Put mcont label in register
        mov    r13,r0,mulstep32 # Put mulstep32 label in register
        CLC()                   # Clear carry outside of loop - reentry from bottom will always have carry clear
mulstep32:
        ror   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        nc.mov pc,r12          # if not carry skip adds to mcont (r12)
        add   r1,r5
        adc   r2,r6
        adc   r3,r7
        adc   r4,r8
mcont:  add   r9,r11          # increment counter
        nz.mov pc,r13          # next iteration if not zero

        add   r0,r0           # clear carry
        ror   r4,r4
        ror   r3,r3
        ror   r2,r2
        ror   r1,r1
        POP4     (r5,r11,r12,r13,r14) # get result pointer and other register from stack
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
