#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
# Based on pi-spigot-rev.s but updated to allow 16x16=32b multiplies and 32b/16b division
MACRO   PUSH( _data_)
    push    _data_,r14
ENDMACRO

MACRO   POP( _data_ )
    pop     _data_, r14
ENDMACRO

MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   SEC()
        nc.ror     r0,r0,1
ENDMACRO

MACRO   ASL( _reg_ )
        add     _reg_, _reg_
ENDMACRO

MACRO   ROL( _reg_ )
        adc     _reg_, _reg_
ENDMACRO

MACRO   JSR( _addr_ )
        jsr     r13,r0,_addr_
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO


# r14 = stack pointer
# r13 = link register
# r12 = inner loop counter
# r10 = remainder pointer        
# r11 = Q
# r9  = outer loop counter
# r8  = next pi output digit pointer
# r3..r7 = local registers
# r1,r2  = temporary registers, parameters and return registers

        EQU     digits,   12
        EQU     cols,     1+(12*10//3)            # 1 + (digits * 10/3)

# preamble for a bootable program
# remove this for a monitor-friendly loadable program
    	ORG 0
        mov   r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs        
        mov   r14,r0,0xFDFF           # Set stack to grow down from here for monitor
        mov   pc,r0,0x100             # Program start at 0x100 for use with monitor/copro

        ORG 0x100
start:
        PUSH  (r13)
        mov     r8,r0,mypi

        ;; trivial banner
        mov     r1, r0, 0x4f
        JSR     (oswrch)
        mov     r1, r0, 0x6b
        JSR     (oswrch)
        mov     r1, r0, 0x20
        JSR     (oswrch)

                                        # Initialise remainder array using temp vars
        mov     r2,r0,2                 # r2=const 2 for initialisation, used as data for rem[] and increment val
        mov     r3,r0,cols              # loop counter i starts at index = 1
L1:     sto     r2,r3,remain-1          # store remainder value to pointer
        dec     r3,1                    # increment loop counter
        nz.dec  pc,PC-L1

        mov     r9,r0,digits            # set up outer loop counter
L3:     mov     r11,r0                  # r11 = Q
        #
        # All loop counters count down from
        # RHS of the arrays in this loop
        #
        mov     r12,r0,cols-1           # r4 inner loop counter
        mov     r10,r0,remain+(cols)-1
        mov     r2,r12,1                # r2 = i+1
L4:
        mov     r1,r11
        JSR     (mul16s)                # r11=Q * i+1 -> result in r1,r2
        ld      r3,r10                   # r4 <- *remptr
        mov     r4,r0                   # r4,r5 = 32b number
        ASL     (r3)                    # Compute 32b result for r2 * 10, accumulating into r1,r2 (N)
        ROL     (r4)
        add     r1,r3
        adc     r2,r4
        ASL     (r3)
        ROL     (r4)
        ASL     (r3)
        ROL     (r4)
        add     r1,r3
        adc     r2,r4                   # 32b N now in r1,r2
                                        # Calculate denominator each loop to save storage
        mov     r3,r12                  # r12 is loop counter i
        add     r3,r3                   # denominator  =(i*2)
        z.add   r3,r0,9                 # or ... set to 9 if i==1
        inc     r3,1                    # add 1 to get 10 (i==0) or (i*2)+1

        mov     r4,r0
        JSR     (udiv32s)               # [r1,r2],[r3,r4] = [r1,r2]/[r3,r4]

        sto     r3, r10                  # rem[i] <- r2 (remainder)
        mov     r11,r1                  # Q <- quotient
        dec     r10,1                  # dec rem/denom ptr
        mov     r2,r12                  # get loop ctr into r2 before decr so it's r12+1 on next iter
        dec     r12,1                   # decr loop counter
        c.mov   pc,r0,L4                # loop if >=0

        # Pre-digit correction loop (multi-digi)
        # r11 = Q
        # r8  = mypi pointer (pointing at next free digit)
        # r2 = predigit pointer
        # r1 = temp store/predigit value
        #
        cmp     r11,r0,10               # check if Q==10 and needing correction?
        nz.sto  r11,r8                  # Save digit if Q <10
        nz.inc   pc,MDCL5-PC            # if no correction needed then continue else start corrections
        sto     r0,r8                   # overwrite 0 if Q=10
        mov     r2,r8                   # r2 is predigit pointer, start at current digit
pdcloop:
        dec     r2,1                    # update pointer to next predigit
        ld      r1,r2                   # get next predigit
        cmp     r1,r0,9                 # is predigit=9 (ie would it overflow if incremented?)
        z.sto   r0,r2                   # store 0 to predigit if yes (preserve Z)
        z.dec   pc,PC-pdcloop           # loop again to correct next predigit
        inc     r1,1                    # if predigit wasnt 9 fall thru to here and add 1
        sto     r1,r2                   # store it and return to execution

MDCL5:  inc     r8,1                    # incr pi digit pointer
        cmp     r8,r0,4+mypi            # allow buffer of 4 chars for corrections
        nc.inc  pc,MDCL6-PC
        ld      r1,r8,-4                # Get digit 3 places back from latest
        mov     r1,r1,48                # Make it ASCII
        jsr     r13,r0,oswrch        
        mov     r1,r0,46                # get '.' into r1 in case...
        cmp     r8,r0,mypi+4            # is this the first digit ?
        z.jsr   r13,r0,oswrch           #  ..yes, print the '.'

MDCL6:
        dec     r9,1                    # dec loop counter
        nz.mov  pc,r0,L3                # back to main program

        # empty the buffer
        mov     r9,r8,-3
MDCL7:  ld      r1,r9
        mov     r1,r1,48                # Make it ASCII        
        jsr     r13,r0,oswrch
        inc     r9,1
        cmp     r9,r8
        nz.dec  pc,PC-MDCL7
        
        halt    r0,r0
        POP     (r13)
        RTS     ()

        
        # --------------------------------------------------------------
        #
        # udiv32s
        #
        # Divide a 32 bit number by a 32 bit number to yield a 32 b quotient and
        # remainder
        #
        # Entry:
        # - r1,r2 holding 32 bit dividend (A), LSB in r1
        # - r3,r4 holding 32 bit divisor (B), LSB in r3
        # - r13 holds return address
        #   (r14 is global stack pointer)
        # Exit
        # - r8-13 preserved, r1-7 trashed
        # - r3,r4 holds remainder
        # - r1,r2 holds quotient
        # --------------------------------------------------------------

udiv32s:
        mov     r6, r3                  # Get divisor into r6,r7
        mov     r7, r4
        mov     r4, r0                  # Get divident/quotient into r1,2,3,4
        mov     r3, r0                  # Upper  two words start off at zero

        mov     r5, r0,-32              # Setup a loop counter
        CLC()                           # ok to clear carry outside loop: will be clear on re-entry from bottom
udiv32_loop:
        # shift left the quotient/dividend
        ROL(r1)
        ROL(r2)
        ROL(r3)
        ROL(r4)
        # Check if dividend is larger than divisor
        cmp    r3,r6
        cmpc   r4,r7
        # If carry not set then dont copy the result and dont update the quotient
        nc.inc  pc,udiv32_next-PC
        sub   r3,r6
        sbc   r4,r7
        or    r1,r0,1                   # set LSB of quotient
udiv32_next:
        inc   r5, 1                     # increment loop counter
        nz.dec pc,PC-udiv32_loop        # loop again if not finished
        # remainder/quotient in r1,2,3,4
        RTS()

        # --------------------------------------------------------------
        #
        # mul16s
        #
        # Multiply 2 16 bit numbers to yield a 32b result
        # Entry:
        #       r1    16 bit multiplier (A)
        #       r2    16 bit multiplicand (B)
        #       r13   holds return address
        #       r14   is global stack pointer
        # Exit
        #       r7    upwards preserved
        #       r3,r6 uses as workspace registers and trashed
        #       r1,r2 holds 32b result (LSB in r11)
        #
        #   NB no need to actually use a zero word for LSW of B - just skip
        #   additions of A_L + B_L and use R2 in addition of A_H + B_H
        # --------------------------------------------------------------
mul16s:
                                        # Get B into [r2,r3]
        mov     r3,r0                   # Use r4,r5 as 32b accumulator
        mov     r4,r0
        mov     r5,r0
        lsr     r1,r1                   # shift right multiplier 
m16s_loop:
        nc.inc  pc,m16s_skip-PC
        add     r4,r2                   # add copy of multiplicand into accumulator if carry
        adc     r5,r3
m16s_skip:
        ASL     (r2)                    # shift left multiplicand
        ROL     (r3)
        lsr     r1,r1                   # shift right multiplier
        nz.dec  pc,PC-m16s_loop         # no need for loop counter - just stop when r1 is empty

m16s_exit:
        nc.inc  pc,m16s_exit2-PC        # skip next two (one word) instructions
        add     r4,r2                   # add last copy of multiplicand into accumulator if carry
        adc     r5,r3
m16s_exit2:     
        mov     r1,r4
        mov     r2,r5
        RTS     ()

        # --------------------------------------------------------------
        #
        # oswrch
        #
        # output a single ascii character to the uart
        #
        # entry:
        # - r1 is the character to output
        #
        # exit:
        # - r2 used as temporary
oswrdig: mov     r1,r1,48                # Convert digit number to ASCII
oswrch:
oswrch_loop:
        in      r2, r0, 0xfe08
        and     r2, r0, 0x8000
        nz.dec  pc, PC-oswrch_loop
        out     r1, r0, 0xfe09
        RTS     ()


mypi:      WORD 0                         # Space for pi digit storage

         ORG mypi + digits + 8
remain:  WORD 0                          # Array space for remainder/denominator data interleaved
