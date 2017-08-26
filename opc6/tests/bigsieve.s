        #
        # bigsieve.s
        #
        # Find all prime numbers less than ~1.7M limited by memory storage
        #
        # MAX = 10000
        # mem = [0] * MAX
        # for ptr in range (2, MAX, 1 ):
        #     if not mem[ptr]:        
        #         for p2 in range (ptr+ptr, MAX, ptr):
        #             mem[p2] = 1
        #
        # ## Read through array and print the primes
        # for ptr in range (2, MAX, 1 ) :
        #     if not mem[ptr]:
        #         print ptr
        #
        # NB All mem[] markers are packed 16 to a word to save space, so get_bit/set_bit
        # routines here need to find the relevant bit in each 16 bit word which holds
        # the marker for any given number. In fact we only ever store 'odd' flags to mem[]
        # so there's another factor of 2 saving. In 64KWords then we can handle up to
        # 64K x 32 = >2M. With current arrangement for monitor etc mem[] starts at 0x2000 so has
        # 0xD000 available = 53248 words -> largest prime < 1.7M
        #
        # Register Usage
        #
        # r15 = PC
        # r14 = SP
        # r13 = link
        # r11,r12 = 32b outer loop counter (ptr) - r11 = LSW
        # r9,r10 = MAX number to sift
        # r7,r8 = inner loop counter (p2)        
        # ----------------------------------------------------------------------

MACRO   RTS ()
        mov     pc,r13
ENDMACRO
MACRO   PUSHALL()
        push     r13, r14
        push     r12, r14
        push     r11, r14
        push     r10, r14
        push      r9, r14
        push      r8, r14
        push      r7, r14
        push      r6, r14
        push      r5, r14
ENDMACRO

MACRO   POPALL()
        pop     r5, r14
        pop     r6, r14
        pop     r7, r14
        pop     r8, r14
        pop     r9, r14
        pop    r10, r14
        pop    r11, r14
        pop    r12, r14
        pop    r13, r14
ENDMACRO

        mov   r14,r0,0x0FFE
        # Initialise registers to stop PUSHALL/POPALL ever loading X's to stack for regression runs
        mov   r13,r0
        mov   r12,r0
        mov   r11,r0
        mov   r10,r0
        mov   r9,r0
        mov   r8,r0
        mov   r7,r0
        mov   r6,r0
        mov   r5,r0

        mov   pc,r0,start

        ORG   0x1000
        EQU   MAX,1000                          # set max number to sift through (<1.7M)
start:
        push  r13,r14                           # for running via monitor
        mov   r10,r0, (MAX & 0xFFFF0000) >> 16  # upper word
        mov   r9, r0, MAX & 0xFFFF              # lower word

        # Zero all entries first
        mov   r1,r0
        mov   r2,r0,1+MAX//32   # 16 entries per word but store only odd flags
L0:     sto   r0,r1,results
        inc   r1,1
        cmp   r1,r2
        nz.dec pc,PC-L0

        # output 2 to console - first prime number
        mov   r1,r0,2 + 48
        jsr   r13,r0,oswrch
        mov   r1,r0,10
        jsr   r13,r0,oswrch
        mov   r1,r0,13
        jsr   r13,r0,oswrch
        
        mov   r11,r0,3          # Start sieve at first odd number
        mov   r12,r0
L1:     mov   r1,r11            # Copy pointer val into r1,r2
        mov   r2,r12
        mov   r3,r0             # function:0 = get_bit
        jsr   r13,r0,bit        # Is bit set ?
        nz.mov pc,r0,L3         # If yes then next bit else...

        mov   r1,r11
        mov   r2,r12
        jsr   r13,r0,printdec32
        
        mov   r8,r12            # p2 <- 2 * ptr
        mov   r7,r11
        add   r7,r7
        adc   r8,r8
L2:     
        mov   r1, r7            # Copy number into r1,r2
        mov   r2, r8
        not   r3,r0             # Function: 1 = get_bit
        jsr   r13,r0,bit        # Set the bit
        add   r7,r11            # Next bit = p2 + ptr
        adc   r8,r12
        cmp   r7,r9
        cmpc  r8,r10            # Reached the end ?
        nc.dec pc,PC-L2         # Next bit if < MAX
        
L3:     inc   r11,2             # skip even numbers so always increment by 2
        adc   r12,r0
        cmp   r11,r9
        cmpc  r12,r10
        nz.mov pc,r0,L1

        halt    r0,r0,0xBEEB
        pop     r13,r14         # for running via monitor
        RTS     ()
        
        # ----------------------------
        # bit
        #
        # Set or check and return the value of an numbered bit in the sieve area, packed 16 to a word
        # and since we never store even flags we can make another factor 2 saving
        # Entry:
        #       r3 = function: LSB=1 setbit, LSB=0 getbit
        #       r2,r1 = bit number (0< r2,r1 < MAX)
        #       r13 = link register
        # Exit:
        #       Z  = bit value 
        #       r2-r4 used for workspace and trashed
        # ----------------------------
bit:
        lsr     r4,r1           # Check if incoming number is even
        nc.inc  r1,1            # if even then set the NZ flag, preserve C
        nc.mov  pc,r13          # and bail out
        push    r3,r14          # save the function type
        lsr     r2,r2           # First divide original number by 2 - storing odds only
        ror     r1,r1
        lsr     r4,r2           # Now complete divide by 16 into r4,r3 
        ror     r3,r1
        lsr     r4,r4
        ror     r3,r3
        lsr     r4,r4
        ror     r3,r3           # r4,r3 point at word number, but actually only r3 now relevant (must be in lowest 64K)
        lsr     r4,r4           # And one more shift because we never store even flags
        ror     r3,r3        

        and     r1,r0,0x000F    # bit position = remainder from original number div 16
        ld      r1,r1,bitmask   # Get the bitmask for that bit position        
        ld      r4,r3,results   # Load the word into r4
        pop     r2,r14          # Pop the function type
        ror     r2,r2           # rotate LSB of r2 into carry
        nc.and  r4,r1           # if 'get' then check if bit is set and set Z or NZ (C preserved)
        c.or    r4,r1           # otherwise 'Or' in the bitmask value if carry set (and C preserved)
        c.sto   r4,r3,results   # Write back the word (C and Z preserved)
        RTS     ()
        
        # ------------------------------------------------------------        
        # printdec32
        #
        # Print unsigned decimal integer from a 32b number to console
        # suppressing leading zeroes and including a linefeed/CR at the
        # end
        #
        # Entry:
        #       r1,r2 holds 32 b number to print, r1 = LSW
        # Exit:
        #       r5-r13 preserved
        #       r1-r4 used for workspace
        # ------------------------------------------------------------
        # Register usage
        # r9    = Decimal table pointer for repeated subtraction
        # r8    = Q (quotient)
        # r7    = Leading zero flag (nonzero once a digit is printed)
        # r5,r6 = Divisor for each round of subtraction
        # r3,r4 = Remainder (eventually bits only in r3)
        # ------------------------------------------------------------

printdec32:   
        PUSHALL    ()          # Save all registers above r4 to stack

        mov r7,r0,0            # leading zero flag     
        mov r9,r0,16           # r9 points to end of 9 entry table, two words per entry
        mov r3,r1              # move number into r3,r4 to sav juggling over oswrch call
        mov r4,r2       
pd32_l1:        
        ld r5,r9,pd32_table    # get 32b divisor from table low word first
        ld r6,r9,pd32_table+1  # .. then high word
        mov r8,r0              # set Q = 0
pd32_l1a:
        cmp  r3,r5             # Is number > decimal divisor
        cmpc r4,r6             # 
        nc.inc pc,pd32_l2-PC   # If no then skip ahead and decide whether to print the digit
        sub r3,r5              # If yes, then do the subtraction
        sbc r4,r6              #
        inc r8,1               # Increment the quotient
        dec pc, PC-pd32_l1a    # Loop again to try another subtraction
        
pd32_l2:
        mov r1,r8,48           # put ASCII val of quotient in r1
        add r7,r8              # Add digit into leading zero flag        
        nz.jsr r13,r0,oswrch   # Print only if the leading zero flag is non-zero

pd32_l3:
        dec r9,2               # Point at the next divisor in the table 
        pl.mov pc,r0, pd32_l1  # If entry number >= 0 then loop again
        mov r1,r3,48           # otherwise convert remainder low word to ASCII
        jsr r13,r0,oswrch      # and print it
        
        mov   r1, r0, 10       # LF/CR pair to finish
        jsr   r13,r0,oswrch
        mov   r1, r0, 13
        jsr   r13,r0,oswrch

        POPALL  ()             # Restore all high registers and return
        RTS()

        
        # Divisor table for printdec32, all in  little endian format
pd32_table:
        WORD            10 % 65536,        10 // 65536 
        WORD           100 % 65536,       100 // 65536 
        WORD          1000 % 65536,      1000 // 65536 
        WORD         10000 % 65536,     10000 // 65536 
        WORD        100000 % 65536,    100000 // 65536 
        WORD       1000000 % 65536,   1000000 // 65536 
        WORD      10000000 % 65536,  10000000 // 65536 
        WORD     100000000 % 65536, 100000000 // 65536 
        WORD    1000000000 % 65536,1000000000 // 65536 

        # Bit masks for set_bit, get_bit
bitmask:
        WORD 0x0001,0x0002,0x0004,0x0008
        WORD 0x0010,0x0020,0x0040,0x0080
        WORD 0x0100,0x0200,0x0400,0x0800
        WORD 0x1000,0x2000,0x4000,0x8000


results: WORD   0       # results will go here


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
