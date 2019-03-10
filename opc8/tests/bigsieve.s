        #
        # bigsieve.s
        #
        # Find all prime numbers limited by memory storage
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
        # so there's another factor of 2 saving.
        #
        # CPU   Data bits   Addr bits   Prime size
        # OPC6      16          16    : 64K x 32 => 2M. 
        # OPC8      32          20    : 2^20 x 64 => 2M. 
        # OPC7      24          24    : 2^24 x 32 => ??? (16 bits used for flags only)
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

        lmov   r14,r0,0x0FFE
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

        lmov   pc,r0,start

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
        lsto    r1,r0,0xfffe09
        RTS     ()

        ORG   0x1000
        EQU   MAX,100                          # set max number to sift through
start:
        PUSH    (r13) # for running via monitor
        lmov    r9,r0, MAX
        # Zero all entries first
        mov     r1,r0
        mov     r2,r0,1+MAX//32   # 16 entries per word but store only odd flags
L0:     lsto    r0,r1,results
        add     r1,r0,1
        cmp     r1,r2
        nz.mov  pc,pc,L0-PC

        # output 2 to console - first prime number
        mov     r1,r0,2 + 48
        jsr     r13,r0,oswrch
        mov     r1,r0,10
        jsr     r13,r0,oswrch
        mov     r1,r0,13
        jsr     r13,r0,oswrch

        mov     r11,r0,3          # Start sieve at first odd number
L1:     mov     r1,r11            # Copy pointer val into r1,r2
        mov     r2,r0
        ljsr    r13,r0,bit        # Is bit set ?
        nz.mov  pc,pc,L3-PC       # If yes then next bit else...

        mov     r1,r11
        mov     r2,r0             # Suppress leading zeroes
        ljsr    r13,r0,printdec24
        ljsr    r13,r0,newline
        
        mov     r7,r11            # r7 <- ptr
L2:
        add     r7,r11            # increment by ptr
        mov     r1, r7            # Copy number into r1,r2
        not     r2, r0            # Function: 1 = get_bit, 0=set bit
        ljsr    r13,r0,bit        # Set the bit
        cmp     r7,r9
        mi.mov  pc,pc,L2-PC       # Next bit if < MAX

L3:     add     r11,r0,2          # skip even numbers so always increment by 2
        cmp     r11,r9
        mi.mov  pc,pc,L1-PC

        mov     r1,r0             # Write NUL to stdout before end of test
        jsr     r13,r0,oswrch        
        halt    r0,r0,0x0001
        POP     (r13)             # for running via monitor
        RTS     ()
        
        # ----------------------------
        # bit
        #
        # Set or check and return the value of an numbered bit in the sieve area, packed 32 to a word
        # and since we never store even flags we can make another factor 2 saving
        # Entry:
        #       r2 = function: LSB=1 setbit, LSB=0 getbit
        #       r1 = bit number (0< r1 < MAX)
        #       r13 = link register
        # Exit:
        #       Z  = bit value
        #       r2-r4 used for workspace and trashed
        # ----------------------------
bit:
        lsr     r4,r1           # Check if incoming number is even
        nc.add  r1,r0,1         # if even then set the NZ flag, preserve C
        nc.mov  pc,r13          # and bail out
        lsr     r1,r1           # First divide original number by 2 - storing odds only
        lsr     r3,r1           # Now complete divide by 16 into r3
        lsr     r3,r3
        lsr     r3,r3           # r3 point at word number
        lsr     r3,r3           # And one more shift because we never store even flags
        and     r1,r0,0x000F    # bit position = remainder from original number div 16
        lld     r1,r1,bitmask   # Get the bitmask for that bit position
        lld     r4,r3,results   # Load the word into r4
        ror     r2,r2           # rotate LSB of r2 (function type) into carry
        nc.and  r4,r1           # if 'get' then check if bit is set and set Z or NZ (C preserved)
        c.or    r4,r1           # otherwise 'Or' in the bitmask value if carry set (and C preserved)
        c.lsto   r4,r3,results   # Write back the word (C and Z preserved)
        RTS     ()

        # ------------------------------------------------------------        
        # printdec24
        #
        # Print unsigned decimal integer from a 24b number to console
        # with option to suppress leading zeroes
        #
        # Entry:
        #       r1 - 24 bit number to print
        #       r2 - leading zero flag:
        #                     0= suppress leading zeros
        #              non-zero= print leading zeros
        # Exit:
        #       all registers above r1 preserved via stack
        # ------------------------------------------------------------
        # Register usage
        # r6    = Q (quotient)
        # r5    = Decimal table pointer for repeated subtraction       
        # r4    = Divisor for each round of subtraction
        # r3    = Remainder (eventually bits only in r3)
        # r2    = leading zero flag
        # r1    = temporary/parameter to oswrch
        # ------------------------------------------------------------

printdec24:   
        PUSH6   (r13,r6,r5,r4,r3,r2)    # Save all registers used to stack
        mov     r5,r0,6                 # r5 points to end of 7 entry table
        mov     r3,r1                   # move number into r3 to sav juggling over oswrch call
pd24_l1:        
        lld      r4,r5,pd24_table        # get 24b divisor from table
        mov     r6,r0                   # set Q = 0
pd24_l1a:
        cmp     r3,r4              	# Is number > decimal divisor
        nc.mov  pc,pc,pd24_l2-PC   	# If no then skip ahead and decide whether to print the digit
        sub     r3,r4              	# If yes, then do the subtraction
        add     r6,r0,1            	# Increment the quotient
        mov     pc, pc,pd24_l1a-PC 	# Loop again to try another subtraction       
pd24_l2:
        mov     r1,r6,48                # put ASCII val of quotient in r1
        add     r2,r6                   # Add digit into leading zero flag        
        nz.jsr  r13,r0,oswrch           # Print only if the leading zero flag is non-zero
pd24_l3:
        sub     r5,r0,1                 # Point at the next divisor in the table 
        pl.mov  pc,pc, pd24_l1-PC       # If entry number >= 0 then loop again
        mov     r1,r3,48                # otherwise convert remainder low word to ASCII
        jsr     r13,r0,oswrch           # and print it
        POP6   (r2,r3,r4,r5,r6,pc)      # Restore all registers used to stack with last (link reg) direct into PC to return

newline:
        PUSH  (r1)
        PUSH  (r2)
        PUSH  (r13)                
        mov   r1, r0, 10       # LF/CR pair to finish
        jsr   r13,r0,oswrch
        mov   r1, r0, 13
        jsr   r13,r0,oswrch        
        POP   (r13)
        POP   (r2)
        POP   (r1)                
        RTS   ()

pd24_table:
        WORD            10 
        WORD           100 
        WORD          1000 
        WORD         10000 
        WORD        100000 
        WORD       1000000 
        WORD      10000000 

        # Bit masks for set_bit, get_bit
bitmask:
        WORD 0x000001,0x000002,0x000004,0x000008
        WORD 0x000010,0x000020,0x000040,0x000080
        WORD 0x000100,0x000200,0x000400,0x000800
        WORD 0x001000,0x002000,0x004000,0x008000

results: WORD   0       # results will go here


