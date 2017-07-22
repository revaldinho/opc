        #
        # Sieve.s
        #
        # Find all prime numbers less than 65535
        #
        # MAX = 100
        ## Need to zero all of sieve area first
        # mem = [0] * MAX//2
        # for ptr in range (3, MAX, 2 ):
        #     if not mem[ptr>>2]:
        #         for p2 in range (ptr+ptr, MAX, ptr):
        #             if (p2 & 0x1): # deal with odds only
        #                 mem[p2>>1] = 1
        #
        ## Read through array and print the primes
        # for ptr in range (3, MAX, 2 ) :
        #     if not mem[ptr>>1]:
        #         print ptr
        #
        # Markers are stored one per 16 bit word, but we don't bother with the even
        # numbers. So primes are calculated from 3 upwards and 32K of address space
        # is enough to deal with all primes less than 64K.
        #
        # Register Usage
        #
        # r15 = PC
        # r14 = SP
        # r13 = link
        # r12 = outer loop counter (ptr))
        # r11 = inner loop counter (p2)
        # r10 = MAX number to sift
        # ----------------------------------------------------------------------

MACRO   SEC()
        nc.dec     r0,1
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

MACRO   PUSH( _data_)
        mov     r14, r14, -1
        sto     _data_, r14, 1
ENDMACRO

MACRO   POP( _data_ )
        ld      _data_, r14, 1
        mov     r14, r14, 1
ENDMACRO

MACRO   ROL(_reg_)
        adc     _reg_, _reg_
ENDMACRO

        mov   r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs        
        mov   r14,r0,0xFDFF           # Set stack to grow down from here for monitor
        mov   pc,r0,0x100             # Program start at 0x100 for use with monitor/copro

        ORG   0x100
        EQU   MAX,1024                # Can use up to 65535 here

        PUSH  (r13)

        mov   r10,r0,MAX              # Counter will run to MAX
        mov   r2,r0,1+MAX//2          # But we're only going to store odd markers so init an array half that size
        not   r9, r0                  # non-zero marker

        # Set all entries to match the number first and then zero non-primes later
        mov   r1,r0
L0:     sto   r0,r1,results
        inc   r1,1
        cmp   r1,r2
        nz.dec pc,PC-L0

        # Print out the first primes
        mov   r1,r0,2
        jsr   r13,r0,PrintDec   # Print it
        jsr   r13,r0,osnewl

        # Now start the sieve at value 3
        mov   r12,r0,3
L1:     lsr   r8,r12
        ld    r1,r8,results     # Is marker set ?
        nz.inc pc,L3-PC         # If yes then next bit else...
        mov   r1, r12           # Copy number into r1
        jsr   r13, r0, PrintDec # Print it
        jsr   r13, r0, osnewl
        mov   r11,r12           # p2 <- 2*ptr
        add   r11,r11
L2:     lsr   r2,r11            # shift right into r2 to inspect LSB in carry
        c.sto r11,r2,results    # Set bits in the marker if odd (just use the actual number - easy to see non-primes in the dump)
        add   r11,r12           # Next bit = p2 <- p2 + ptr
        cmp   r11,r10           # Reached the end ?
        nc.dec pc,PC-L2         # Next bit if < MAX
L3:     inc   r12,2             # next odd
        cmp   r12,r10
        nc.mov pc,r0,L1

        halt    r0,r0,0xBEEB
        POP     (r13)
        RTS     ()


        # -------------------------------
        # PrintDec
        #
        # Print decimal values to up 99999 with leading zeroes
        #
        # taken from Dave's code and optimized for OPC6 instructions
        #
        # Entry:
        #      r1  holds value to print
        #      r13 link register hold return address
        # Exit:
        #      r1..r6 used as workspace and trashed
        #      (r2 used by oswrch call)
        # -------------------------------

PrintDec:
        mov     r5,r13          # save link register locally
        mov     r6, r1          # copy decimal value into r6
        mov     r3, r0, 4       # Digits numbered 4 down to 0
        mov     r1, r0, 0x2006
PrintDec1:
        ld      r4, r3, DecTable
        lsr     r6, r6
PrintDec2:
        adc     r6, r6
        nc.cmp  r6, r4
        nc.inc  pc, PrintDec4-PC
PrintDec3:
        sub     r6, r4
        SEC     ()
PrintDec4:
        adc     r1, r1
        nc.dec  pc, PC-PrintDec2
        jsr     r13,r0,oswrch
        mov     r1, r0, 0x1003
        dec     r3, 1
        pl.mov  pc,r0,PrintDec1
        mov     pc,r5             # Return to link value in r5

osnewl:
        PUSH (r13)
        mov  r1, r0, 0x0A
        jsr  r13, r0, oswrch
        mov  r1, r0, 0x0D
        jsr  r13, r0, oswrch
        POP  (r13)
        RTS  ()

DecTable:
        WORD        8 * (2**11)
        WORD       80 * (2** 8)
        WORD      800 * (2** 5)
        WORD     8000 * (2** 2)
        WORD    40000 * (2** 0)

Limit:
    EQU dummy, 0 if (Limit < 0x200) else limit_error

        ORG 0x200

results:


ORG 0xFFEE

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
        in      r2, r0, 0xfe08
        and     r2, r0, 0x8000
        nz.dec  pc, PC-oswrch_loop
        out     r1, r0, 0xfe09
        RTS     ()
