#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
# Based on pi-spigot-rev.s but updated to allow 16x16=32b multiplies and 32b/16b division
MACRO   PUSH( _data_)
    mov     r14, r14, -1
    sto     _data_, r14, 1
ENDMACRO

MACRO   POP( _data_ )
    ld      _data_, r14, 1
    mov     r14, r14, 1
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
        mov     r13,pc,2
        mov     pc,r0,_addr_
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

# r14 = stack pointer
# r13 = link register
# r12 = inner loop counter
# r11 = Q
# r10 = CONSTANT 1
# r9  = outer loop counter
# r8  = next pi output digit pointer
# r7  = remainder pointer
# r3..r5 = local registers
# r1,r2  = temporary registers, parameters and return registers

        EQU     digits,   12
        EQU     cols,     1+(12*10//3)            # 1 + (digits * 10/3)

# preamble for a bootable program
# remove this for a monitor-friendly loadable program
    	ORG 0
    	mov r14, r0, 0xFFFF
    	mov pc, r0, start

        ORG 0x100
start:
        mov     r10,r0,1                # CONSTANT 1
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
        mov     r7,r0,remain            # point at start of array
        mov     r5,r0,cols-1            # loop counter top of range
L1:     sto     r2,r7                   # store remainder value to pointer
        add     r7,r10                  # update pointer
        sub     r5,r10                  # reached bottom of range?
        nz.mov  pc,r0,L1

        mov     r9,r0,digits            # set up outer loop counter
L3:     mov     r11,r0                  # r11 = Q
        #
        # All loop counters count down from
        # RHS of the arrays in this loop
        #
        mov     r12,r0,cols-1           # r4 inner loop counter
        mov     r7,r0,remain+(cols)-1
        mov     r2,r12,1                # r2 = i+1
L4:
        mov     r1,r11
        JSR     (mul16s)                # r11=Q * i+1 -> result in r1,r2
        ld      r3,r7                   # r4 <- *remptr
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
        add     r3,r10                  # add 1 to get 10 (i==0) or (i*2)+1

        mov     r4,r0
        JSR     (udiv32s)               # [r1,r2],[r3,r4] = [r1,r2]/[r3,r4]

        sto     r3, r7                  # rem[i] <- r2 (remainder)
        mov     r11,r1                  # Q <- quotient
        sub     r7,r10                  # dec rem/denom ptr
        mov     r2,r12                  # get loop ctr into r2 before decr so it's r12+1 on next iter
        sub     r12,r10                 # decr loop counter
        c.mov   pc,r0,L4                # loop if >=0

        # Pre-digit correction loop
        # r11 = Q
        # r8  = mypi pointer (pointing at next free digit)
        # r2 = predigit pointer
        # r1 = temp store/predigit value
        #
        cmp     r11,r0,10               # check if Q==10 and needing correction?
        nz.sto  r11,r8                  # Save digit if Q <10
        z.mov   pc,r0, correction       # if no correction needed then continue else start corrections
L5:     add     r8,r10                  # incr pi digit pointer

        cmp     r8,r0,4+mypi            # allow buffer of 4 chars for corrections
        nc.mov  pc,r0,L6
        ld      r1,r8,-4                # Get digit 3 places back from latest
        JSR     (oswrdig)
        cmp     r8,r0,4+mypi            # Emit decimal point after first digit
        nz.mov  pc,r0,L6
        mov      r1,r0,46
        JSR     (oswrch)
L6:
        sub     r9,r10                  # dec loop counter
        nz.mov  pc,r0,L3

        # empty the buffer
        mov     r9,r8,-3
L7:     ld      r1,r9
        JSR     (oswrdig)
        add     r9,r10
        cmp     r9,r8
        nz.mov  pc,r0,L7

        halt    r0,r0

correction:
        sto     r0,r8                   # overwrite 0 if Q=10
        mov     r2,r8                   # r2 is predigit pointer, start at current digit
pdcloop:
        sub     r2,r10                  # update pointer to next predigit
        ld      r1,r2                   # get next predigit
        cmp     r1,r0,9                 # is predigit=9 (ie would it overflow if incremented?)
        z.sto   r0,r2                   # store 0 to predigit if yes (preserve Z)
        z.mov   pc,r0,pdcloop           # loop again to correct next predigit
        add     r1,r0,1                 # if predigit wasnt 9 fall thru to here and add 1
        sto     r1,r2                   # store it
        mov     pc,r0,L5                # return to execution

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
        # - r10 is constant 1
        # Exit
        # - r10-13 preserved, r1-9 trashed
        # - r3,r4 holds remainder
        # - r1,r2 holds quotient
        # --------------------------------------------------------------

udiv32s:
        # need more registers so save all from 7 upwards as required
        PUSH    (r7)
        PUSH    (r8)
        PUSH    (r9)
        mov     r6, r3                  # Get divisor into r6,r7
        mov     r7, r4
        mov     r4, r0                  # Get divident/quotient into r1,2,3,4
        mov     r3, r0                  # Upper  two words start off at zero

        mov     r8, r0,-32              # Setup a loop counter
        mov     r9, r0,udiv32_next
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
        nc.mov  pc,r9
        sub   r3,r6
        sbc   r4,r7
        or    r1,r10                    # set LSB of quotient
udiv32_next:
        add   r8, r10                   # increment loop counter
        nz.mov pc,r0,udiv32_loop        # loop again if not finished
        # remainder/quotient in r1,2,3,4
        POP     (r9)
        POP     (r8)
        POP     (r7)
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
        #       r10   is constant 1
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
        mov     r6,r0,m16s_loop
        CLC     ()
        ror     r1,r1                   # shift right multiplier
m16s_loop:
        nc.mov  pc,r0,m16s_skip
        add     r4,r2                   # add copy of multiplicand into accumulator if carry
        adc     r5,r3
m16s_skip:
        ASL     (r2)                    # shift left multiplicand
        ROL     (r3)
        CLC     ()
        ror     r1,r1                   # shift right multiplier
        nz.mov  pc,r6                   # no need for loop counter - just stop when r1 is empty

m16s_exit:
        nc.mov  pc,pc,2                 # skip next two (one word) instructions
        add     r4,r2                   # add last copy of multiplicand into accumulator if carry
        adc     r5,r3

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
        ld      r2, r0, 0xfe08
        and     r2, r0, 0x8000
        nz.mov  pc, r0, oswrch_loop
        sto     r1, r0, 0xfe09
        RTS     ()


mypi:      WORD 0                         # Space for pi digit storage

         ORG mypi + digits + 8
remain:  WORD 0                          # Array space for remainder/denominator data interleaved
