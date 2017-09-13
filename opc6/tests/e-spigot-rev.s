#
# Program to generate E using the Spigot Algorithm from
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

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

        # r14 = stack pointer
        # r13 = link register
        # r12 = inner loop counter
        # r11 = Q
        # r10 = (i+1) value in main loop
        # r9  = outer loop counter
        # r8  = next e output digit pointer
        # r4,5,6,7 = unused
        # r1..r3  = local registers

        EQU     digits,   64            # Digits to be printed
        EQU     saved_digits, 16        # Max digits to be save in memory (for regression)
        EQU     cols,     digits+2      # Needs a few more columns than digits to avoid occasional errors in last digit or few

# preamble for a bootable program
# remove this for a monitor-friendly loadable program
        ORG 0
        mov r14, r0, 0x0FFE             # Stack below code (will be taken care of by monitor on hw)
        mov r13,r0                      # Initialise r13 for simulation
        mov pc, r0, start

        ORG 0x1000
start:
        push    r13,r14                 # Save r13 return address if running via the monitor
        mov     r8,r0,my_e+1

        ;; trivial banner + first digit and decimal point
        mov     r10, r0
L0:     ld      r1, r10, banner
        z.inc   pc, L7-PC
        jsr     r13, r0, oswrch
        inc     r10,1
        dec     pc, PC-L0

L7:     
                                        # Initialise remainder array 
        mov     r2,r0,1                 # r2=const 1 
        mov     r3,r0,cols-2            # loop counter i starts at index = RHS
L1:     sto     r2,r3,remain            # store remainder value to pointer
        dec     r3,1                    # decrement loop counter
        nz.dec  pc,PC-L1                # loop again if not zero
        sto     r0,r0,remain            # write 0 into first entry
        
        mov     r9,r0,digits            # set up outer loop counter
L3:     mov     r11,r0                  # r11 = Q
        mov     r12,r0,cols-1           # r12 inner loop counter start at RHS of array
        mov     r10,r12,1               # r10 = i+1
L4:
        ld      r2,r12,remain           # r2 <- remain[i]
        ASL     (r2)                    # Compute 16b result for r2 * 10
        mov     r1,r2
        ASL     (r2)
        ASL     (r2)
        add     r1,r2
        add     r11,r1                  # accumulate into Q
        jsr     r13,r0,udiv16           # r11/r10; r11 <- quo, r2 <- rem, r10 preserved
        sto     r2,r12,remain           # rem[i] <- r2
        
        mov     r10,r12                 # get loop ctr into r10 before decr so it's i+1 on next iter
        dec     r12,1                   # decr loop counter
        c.dec   pc,PC-L4                # loop if >=0
        
L6:     mov     r1, r11, 48             # Convert quotient into ASCII digit
        jsr     r13,r0,oswrch

        cmp     r9,r0,saved_digits      # Need to save a digit ?
        nc.sto  r11,r8                  # Yes 
        nc.inc  r8,1                    # and increment the pointer

        dec     r9,1                    # dec loop counter
        nz.mov  pc,r0,L3                # jump back into main program

        mov     r1, r0, 10              # Print Newline to finish off
        jsr     r13,r0,oswrch
        mov     r1, r0, 13
        jsr     r13,r0,oswrch

        halt    r0,r0
        pop     r13,r14                 # restore return address for monitor
        RTS     ()

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
        # - r10 16 bit divisor (B)
        # - r13 holds return address
        # Exit
        # - r3 upwards preserved (except r11)
        # - r2 = quotient
        # - r11 = remainder
        # --------------------------------------------------------------
udiv16:
        mov     r2,r0                   # Get dividend/quotient into double word r1,2
        mov     r1,r0,-16               # Setup a loop counter
udiv16_loop:
        ASL     (r11)                   # shift left the quotient/dividend
        ROL     (r2)                    #
        cmp     r2,r10                  # check if quotient is larger than divisor
        c.sub   r2,r10                  # if yes then do the subtraction for real
        c.adc   r11,r0                  # ... set LSB of quotient using (new) carry
        inc     r1,1                    # increment loop counter zeroing carry
        nz.dec  pc,PC-udiv16_loop       # loop again if not finished 
        RTS     ()                      # and return with quotient/remainder in r1/r2

banner:  STRING "OK 2."                 # Banner and first digit and dp
         WORD 0        
my_e:    WORD 0                         # reserve space for digits to be stored for regression

        ORG    my_e + saved_digits + 2
         WORD 0
remain:  WORD 2                         # Array space for remainder date
         WORD 2


        ORG  0xFFEE
        # --------------------------------------------------------------
        #
        # oswrch
        #
        # Output a single ascii character to the uart
        #
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporary
        # ---------------------------------------------------------------
oswrch:
oswrch_loop:
#        in      r2, r0, 0xfe08
#        and     r2, r0, 0x8000
#        nz.dec  pc, PC-oswrch_loop
        out     r1, r0, 0xfe09
        RTS     ()
