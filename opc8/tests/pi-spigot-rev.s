#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
#

MACRO   SINGLE_DIGIT_CORRECTION()
        # r11 = Q
        # r8  = mypi pointer (pointing at next free digit)
        # r3 = pointer to start of mypi 
        # r2 = predigit pointer
        # r1 = temp store/predigit value
        lmov    r3,r0,mypi              
        cmp     r11,r0,10               # check if Q==10 and needing correction?
        nz.sto  r11,r8                  # Save digit if Q <10        
        nz.mov  pc,pc,SDCL5-PC          # if no correction needed then continue else start corrections
        sto     r0,r8                   # overwrite 0 if Q=10
        ld      r1,r8,-1                # get predigit
        sub     r1,r0,9                 # need to add 1 and set to 0 if overflow to 10, so sub 9 first
        z.sub   r1,r0,10                # subtract another 10 if zero
        add     r1,r0,10                # and add 10 to get final value
        sto     r1,r8,-1                # store it

SDCL5:  add     r8,r0,1                 # incr pi digit pointer
        cmp     r8,r3,+1                # is pointer = mypi+1 ?
        z.mov   pc,pc,SDCL6-PC          # if first digit nothing to print yet
SDCL8:
        ld      r1,r8,-2                # Get digit 2 places back from latest
        jsr     r13,r0,wrdecdig         # Print it
        mov     r1,r0,46                # get '.' into r1 in case...
        cmp     r8,r3,+2                # is this the first digit ? (mypi+2)
        z.jsr   r13,r0,oswrch           #  ..yes, print the '.'

SDCL6:  sub     r9,r0,1                 # dec loop counter
        nz.lmov pc,r0,L3                # jump back into main program
        # empty the buffer
SDCL7:  ld      r1,r8,-1
        jsr     r13,r0,wrdecdig
ENDMACRO

MACRO   MULTI_DIGIT_CORRECTION()
        # Pre-digit correction loop
        # r11 = Q
        # r8  = mypi pointer (pointing at next free digit)
        # r2 = predigit pointer
        # r1 = temp store/predigit value
        #
        cmp     r11,r0,10               # check if Q==10 and needing correction?
        nz.sto  r11,r8                  # Save digit if Q <10
        nz.mov  pc,pc,MDCL5-PC          # if no correction needed then continue else start corrections
        sto     r0,r8                   # overwrite 0 if Q=10
        mov     r2,r8                   # r2 is predigit pointer, start at current digit
pdcloop:
        sub     r2,r0,1                 # update pointer to next predigit
        ld      r1,r2                   # get next predigit
        cmp     r1,r0,9                 # is predigit=9 (ie would it overflow if incremented?)
        z.sto   r0,r2                   # store 0 to predigit if yes (preserve Z)
        z.mov   pc,pc,pdcloop-PC        # loop again to correct next predigit
        add     r1,r0,1                 # if predigit wasnt 9 fall thru to here and add 1
        sto     r1,r2                   # store it and return to execution

MDCL5:  add     r8,r0,1                 # incr pi digit pointer
        lcmp    r8,r0,4+mypi            # allow buffer of 4 chars for corrections
        nc.mov  pc,pc,MDCL6-PC
        ld      r1,r8,-4                # Get digit 3 places back from latest
        jsr     r13,r0,wrdecdig
        mov     r1,r0,46                # get '.' into r1 in case...
        lcmp    r8,r0,mypi+4            # is this the first digit ?
        z.jsr   r13,r0,oswrch           #  ..yes, print the '.'

MDCL6:
        sub     r9,r0,1                 # dec loop counter
        nz.lmov pc,r0,L3                # jump back into main program        

        # empty the buffer
        mov     r9,r8,-3
MDCL7:  ld      r1,r9
        jsr     r13,r0,wrdecdig
        add     r9,r0,1
        cmp     r9,r8
        nz.lmov pc,r0,MDCL7
ENDMACRO

        # --------------------------------------------------------------
        # Machine startup
        # --------------------------------------------------------------
        
        mov    r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs
        lmov   r14,r0,0x0FFE           # Set stack to grow down from here for monitor
        lmov   pc,r0,0x1000            # Program start at 0x1000 for use with monitor/copro


        # --------------------------------------------------------------
        #
        # oswrch
        #
        # Output a single ascii character to the uart, or enter at wrdecdig
        # with a single decimal digit which will be converted to ASCII first.
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporar
        # ---------------------------------------------------------------
wrdecdig:
         mov     r1, r1, 48
oswrch:
        lsto     r1,r0,0xfffe09
        RTS     ()



        # ---------------------------------------------------------------
        # Main Loop
        # ---------------------------------------------------------------        
	# r14 = stack pointer
	# r13 = link register
	# r12 = inner loop counter
	# r11 = Q
	# r10 = denominator
	# r9  = outer loop counter
	# r8  = next pi output digit pointer
	# r7  = remainder pointer
	# r3..r5 = local registers
	# r1,r2  = temporary registers, parameters and return registers
        # ---------------------------------------------------------------
        EQU    digits,   32            # 16
        EQU    cols,     1+(digits*10//3)            # 1 + (digits * 10/3)

        
        
        ORG   0x1000
start:
        PUSH  (r13)

        lmov     r8,r0,mypi
        ;; trivial banner
        mov     r1, r0, 0x4f
        jsr     r13,r0,oswrch
        mov     r1, r0, 0x6b
        jsr     r13,r0,oswrch
        mov     r1, r0, 0x20
        jsr     r13,r0,oswrch

                                        # Initialise remainder/denominator array using temp vars
        mov     r2,r0,2                 # r2=const 2 for initialisation, used as data for rem[] and increment val
        lmov    r3,r0,cols              # loop counter i starts at index = 1
L1:     lsto    r2,r3,remain-1          # store remainder value to pointer
        sub     r3,r0,1                    # increment loop counter
        nz.lmov pc,r0,L1

        mov     r9,r0,digits            # set up outer loop counter
L3:     mov     r11,r0                  # r11 = Q
        #
        # All loop counters count down from
        # RHS of the arrays in this loop
        #
        lmov    r12,r0,cols-1           # r4 inner loop counter
        lmov    r7,r0,remain+cols-1
        mov     r2,r12,1                # r2 = i+1
        lmov    r10,r0,(cols-1)*2 + 1   # initial denominator at furthest colum
L4:
        ljsr    r13,r0,muls             # r11=Q * i+1 -> result in r11
        ld      r2,r7                   # r2 <- *remptr
        ASL     (r2)                    # Compute 16b result for r2 * 10
        mov     r1,r2
        ASL     (r2)
        ASL     (r2)
        add     r1,r2
        add     r11,r1                  # add it to Q as second term
        ljsr    r13,r0,udiv24           # r11/r10; r11 <- quo, r2 <- rem, r10 preserved
        sto     r2, r7                  # rem[i] <- r2
        sub     r7,r0,1                 # dec rem ptr
                                        # denom <- denom-2, but denom[0]=10
        sub     r10,r0,3                # oversubtract by 1
        z.add   r10,r0,9                # correct by 9 if zero
        add     r10,r0,1                # and always correct oversubtraction
        mov     r2,r12                  # get loop ctr into r2 before decr so it's r12+1 on next iter
        sub     r12,r0,1                # decr loop counter
        c.lmov  pc,r0,L4                # loop if >=0

        SINGLE_DIGIT_CORRECTION()
        #MULTI_DIGIT_CORRECTION()

        mov     r1, r0, 10              # Print Newline to finish off
        jsr     r13,r0,oswrch
        mov     r1, r0, 13
        jsr     r13,r0,oswrch

        mov     r1,r0             # Write NUL to stdout before end of test
        jsr     r13,r0,oswrch                
        halt    r0,r0,0x00
        POP     (r13)
        RTS     ()

        # --------------------------------------------------------------
        #
        # udiv24 - special Pi version - rejig input/output registers to
        # save cycles shuffling them around compared with the generic
        # version in math24.s
        #
        # Divide a 24 bit number by a 24 bit number to yield a 24 b quotient and
        # remainder
        #
        # Entry:
        # - r11 24 bit dividend (A)
        # - r10 24 bit divisor (B)
        # - r13 holds return address
        # Exit
        # - r3 upwards preserved (except r11)
        # - r2 =  remainder
        # - r11 = quotient
        # --------------------------------------------------------------
udiv24:
        mov     r2,r0                   # Get dividend/quotient into double word r1,2
        mov     r1,r0,24               # Setup a loop counter
udiv24_loop:
        ASL     (r11)                   # shift left the quotient/dividend
        ROL     (r2)                    #
        cmp     r2,r10                  # check if remainder is larger than divisor
        c.sub   r2,r10                  # if yes then do the subtraction for real
        c.mov   r11,r11,1               # ... set LSB of quotient using (new) carry
        sub     r1,r0,1                 # decrement loop counter zeroing carry
        nz.mov  pc,pc, udiv24_loop-PC   # loop again if not finished (r5=udiv24_loop)
        RTS     ()                      # and return with quotient/remainder in r1/r2

        # --------------------------------------------------------------
        #
        # muls
        #
        # Multiply 2 single word numbers to yield only a single word result
        #
        # Entry:
        #       r11   multiplier (A)
        #       r2    multiplicand (B)
        #       r13   holds return address
        #       r14   is global stack pointer
        # Exit
        #       r6    upwards preserved
        #       r3,r5 uses as workspace registers and trashed
        #       r11   result
        # --------------------------------------------------------------
muls:
        lsr     r3,r11                  # shift right multiplier into r3
        mov     r11,r0
muls_loop0:
        c.add   r11,r2                  # add copy of multiplicand into accumulator if carry
        ASL     (r2)                    # shift left multiplicand
        lsr     r3, r3                  # shift right multiplier
        nz.mov pc,pc,muls_loop0-PC      # no need for loop counter - just stop when r1 is empty
        c.add   r11,r2                  # add last copy of multiplicand into accumulator if carry
        RTS     ()

mypi:    WORD 0                          # Space for pi digit storage
         ORG mypi + digits + 8
remain:  WORD 0                          # Array space for remainder data
