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
        mov    r10,r0, DATA0-2 # R10 points to divider data (will be preincremented)
        mov    r12,r0, RESULTS # R12 points to area for results

outer:  add    r10,r0,2        # increment data pointer by 2
        ld     r2,r10          # check if we reached the (0,0) word
        z.ld   r2,r10,1
        z.mov  pc,r0,end       # .. if yes, bail out
        mov    r11,r0, DATA0   # reset multiplicand pointer
inner:
        mov    r1, r10         # get dividend address A
        mov    r2, r11         # get divisor address B
        mov    r3, r12         # get result area pointer
        mov    r13,r0, next    # save return address
        mov    pc, r0, udiv32  # JSR udiv32
next:   add    r12,r0,4        # increment result pointer by 4
        add    r11,r0,2        # increment divisor address by 2
        ld     r2,r11          # get divisor data LSW
        z.ld   r2,r11,1        # get divisor data MSW
        z.mov  pc,r0,outer     # if (0,0) then next outer loop
        mov    pc,r0,inner     # else next inner loop

end:
        halt    r0,r0,0x99

# --------------------------------------------------------------
#
# udiv32
#
# Divide a 32 bit number by a 32 bit number to yield a 32 b quotient and
# remainder
#
# Entry:
# - r1 points to block of two words holding 32 bit dividend (A), LSB in lowest word
# - r2 points to block of two words holding 32 bit divisor (B), LSB in lowest word
# - r3 points to area of memory large enough to take the 2 word quotient + 2 word remainder
# - r13 holds return address
#   (r14 is global stack pointer)
# Exit
# - r10-13 preserved, r1-9 trashed
# - Result written to memory (see above)
# --------------------------------------------------------------

udiv32:
        PUSH    (r13, r14)      # save return address
        PUSH4   (r12,r11,r10,r3, r14)

        ld      r6, r2          # Get divisor into r6,r7
        ld      r7, r2,1

        mov    r5, r0          # Get divident/quotient into r2,3,4,5
        mov    r4, r0
        ld      r3, r1,1
        ld      r2, r1

        mov    r1, r0, 1            # r1 = constant 1
        mov    r10, r0,-32          # Setup a loop counter
        mov    r11, r0, udiv32_loop # stash inner loop top in a register
        mov    r8, r0, udiv32_next  # stash inner loop label in register
        CLC()                       # ok to clear carry outside loop: will be clear on re-entry from bottom
udiv32_loop:
        # shift left the quotient/dividend
        ROL(r2)
        ROL(r3)
        ROL(r4)
        ROL(r5)
        # Check if quotient is larger than divisor
        cmp    r4,r6
        cmpc   r5,r7
        # If carry not set then dont copy the result and dont update the quotient
        nc.mov  pc,r8         # r8=udiv32_next
        sub   r4,r6
        sbc   r5,r7
        or    r2,r1           # set LSB of quotient
udiv32_next:
        add   r10, r1          # increment loop counter
        nz.mov pc, r11         # loop again if not finished
        # remainder/quotient in r2,3,4,5
        POP     (r1, r14)       # Get results pointer from stack
        sto     r2,r1,0         # save results
        sto     r3,r1,1
        sto     r4,r1,2
        sto     r5,r1,3
        # restore other registers
        POP4    (r10,r11,r12,r13, r14)
        mov    pc,r13          # and return


        ORG     0x100
STACK:  WORD 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  # Reserve some stack space

DATA0:
        WORD 0x02,0x04,0x01,0x00
        WORD 0x00,0x09,0x18,0x23
        WORD 0x13,0x03,0x08,0x00
        WORD 0x00,0x44,0x33,0x99
        WORD 0x11,0x00,0xF8,0x03
        WORD 0xC2,0x04,0xAB,0x03
        WORD 0x00,0x00,0x00,0x00        # all zero words to finish

        ORG     0x180
RESULTS:
