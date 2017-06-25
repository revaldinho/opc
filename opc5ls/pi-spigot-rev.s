#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
#

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
# r7  = remainder/denominator pointer (data interleaved)
# r3..r5 = local registers
# r1,r2  = temporary registers, parameters and return registers

        EQU     digits,   6
        EQU     cols,     1+(6*10//3)            # 1 + (digits * 10/3)

# preamble for a bootable program
# remove this for a monitor-friendly loadable program
    	ORG 0
    	mov r14, r0, 0xFFFF
    	mov pc, r0, start

        ORG 0x1000
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

                                        # Initialise remainder/denominator array using temp vars
        mov     r2,r0,2                 # r2=const 2 for initialisation, used as data for rem[] and increment val
        mov     r1,r0,10                # store 10 in first column of denominator array
        mov     r7,r0,remain            # point at start of array
        sto     r2,r7                   # store first remainder
        sto     r1,r7,1                 # store first denominator
        add     r7,r0,2                 # point at start of next pair
        mov     r3,r10                  # loop counter i starts at index = 1
        mov     r5,r0,cols+2            # loop counter top of range
L1:     sto     r2,r7                   # store remainder value to pointer
        mov     r4,r3
        add     r4,r4,1                 # r4 = (i*2)+1
        sto     r4,r7,1                 # store denominator value to pointer
        add     r7,r2                   # update pointer by 2
        add     r3,r10                  # increment loop counter
        cmp     r3,r5                   # reached top of range ?
        nz.mov  pc,r0,L1

        mov     r9,r0,digits            # set up outer loop counter
L3:     mov     r11,r0                  # r11 = Q
        #
        # All loop counters count down from
        # RHS of the arrays in this loop
        #
        mov     r12,r0,cols-1           # r4 inner loop counter
        mov     r7,r0,remain+(cols*2)-2
        mov     r2,r12,1                # r2 = i+1
L4:
        JSR     (mul16s)                # r11=Q * i+1 -> result in r11
        ld      r2,r7                   # r2 <- *remptr
        ASL     (r2)                    # Compute 16b result for r2 * 10
        mov     r1,r2
        ASL     (r2)
        ASL     (r2)
        add     r1,r2
        add     r11,r1                  # add it to Q as second term
        ld      r3,r7,1                 # r3 <- *denomptr
        JSR     (udiv16)                # r11 <- quo, r2 <- rem
        sto     r2, r7                  # rem[i] <- r2
        sub     r7,r0,2                 # dec rem/denom ptr
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
        cmp     r8,r0,4+mypi              # Emit decimal point after first digit
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
        # udiv16 - special Pi version - rejig input/output registers to
        # save cycles shuffling them around compared with the generic
        # version in math16.s
        #
        # Divide a 16 bit number by a 16 bit number to yield a 16 b quotient and
        # remainder
        #
        # Entry:
        # - r11 16 bit dividend (A)
        # - r3 16 bit divisor (B)
        # - r13 holds return address
        # - r10 hold constant 1
        # - r14 is global stack pointer
        # Exit
        # - r6  upwards preserved (except r11)
        # - r3-5 trashed
        # - r2 = quotient
        # - r11 = remainder
        # --------------------------------------------------------------
udiv16:
        mov     r2,r0                   # Get dividend/quotient into double word r1,2
        mov     r4,r0, udiv16_loop      # Stash loop target in r4
        mov     r5,r0,-16               # Setup a loop counter
udiv16_loop:
        ASL     (r11)                   # shift left the quotient/dividend
        ROL     (r2)                    #
        cmp     r2,r3                   # check if quotient is larger than divisor
        c.sub   r2,r3                   # if yes then do the subtraction for real
        c.adc   r11,r0                  # ... set LSB of quotient using (new) carry
        add     r5,r10                  # increment loop counter zeroing carry
        nz.mov  pc,r4                   # loop again if not finished (r5=udiv16_loop)
        RTS     ()                      # and return with quotient/remainder in r1/r2

        # --------------------------------------------------------------
        #
        # mul16s
        #
        # Multiply 2 16 bit numbers to yield only a 16b result
        #
        # Entry:
        #       r11    16 bit multiplier (A)
        #       r2    16 bit multiplicand (B)
        #       r13   holds return address
        #       r14   is global stack pointer
        # Exit
        #       r6    upwards preserved
        #       r3,r5 uses as workspace registers and trashed
        #       r11   holds 16b result
        # --------------------------------------------------------------
mul16s:
        mov     r3,r0
        mov     r5,r0,mul16s_loop0
        CLC     ()
        ror     r11,r11                 # shift right multiplier
mul16s_loop0:
        c.add   r3,r2                   # add copy of multiplicand into accumulator if carry
        ASL     (r2)                    # shift left multiplicand
        CLC     ()
        ror     r11,r11                 # shift right multiplier
        nz.mov  pc,r5                   # no need for loop counter - just stop when r1 is empty

        c.add   r3,r2                   # add last copy of multiplicand into accumulator if carry
        mov     r11,r3
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
