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
        # NB All mem[] markers are packed 32 to a word to save space, so get_bit/set_bit
        # routines here need to find the relevant bit in each 32 bit word which holds
        # the marker for any given number. In fact we only ever store 'odd' flags to mem[]
        # so there's another factor of 2 saving. In 64KWords then we can handle up to
        # 64K x 32 = >4M. 
        #
        # Register Usage
        #
        # r15 = PC
        # r14 = SP
        # r13 = link
        # r11 = 32b outer loop counter (ptr) 
        # r9  = MAX number to sift
        # r7  = inner loop counter (p2)
        # ----------------------------------------------------------------------



MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   PUSH( _data_)
        push    _data_, r14
ENDMACRO

MACRO   POP( _data_ )
        pop     _data_, r14
ENDMACRO

MACRO   SEC()
        nc.ror     r0,r0,1
ENDMACRO

MACRO   ASL( _reg_ )
        add     _reg_, _reg_
ENDMACRO

MACRO   ROL( _reg_ )
        rol     _reg_, _reg_
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

MACRO   PUSHALL()
        PUSH (r13)
        PUSH (r12)
        PUSH (r11)
        PUSH (r10)
        PUSH ( r9)
        PUSH ( r8)
        PUSH ( r7)
        PUSH ( r6)
        PUSH ( r5)
ENDMACRO

MACRO   POPALL()
        POP ( r5)
        POP ( r6)
        POP ( r7)
        POP ( r8)
        POP ( r9)
        POP (r10)
        POP (r11)
        POP (r12)
        POP (r13)
ENDMACRO

MACRO   JSR ( _addr_ )
        ljsr r13, _addr_
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
        EQU   MAX,1000                         # set max number to sift through
start:
        PUSH (r13,r14) # for running via monitor
        mov   r9,r0, MAX 

        # Zero all entries first
        mov   r1,r0
        mov   r2,r0,1+MAX//64   # 32 entries per word but store only odd flags

L0:     sto   r0,r1,results
        add     r1,r0,1
        cmp   r1,r2
        nz.sub  pc,r0,PC-L0

        # output 2 to console - first prime number
        mov   r1,r0,2 + 48
        JSR   (oswrch)
        mov   r1,r0,10
        JSR   (oswrch)
        mov   r1,r0,13
        JSR   (oswrch)

        mov   r11,r0,3          # Start sieve at first odd number
L1:     mov   r1,r11            # Copy pointer val into r1
        mov   r2,r0             # function:0 = get_bit
        JSR   (bit)             # Is bit set ?
        nz.mov pc,r0,L3         # If yes then next bit else...

        mov   r1,r11
        JSR   (printdec32)
        JSR   (newline)

        mov   r7,r11            # p2 <- ptr
L2:
        add   r7,r11            # Increment by ptr         
        mov   r1,r7             # Copy number into r1
        not   r2,r0             # Function: 1 = get_bit, 0=set bit
        JSR   (bit)             # Set the bit
        cmp   r7,r9
        mi.sub  pc,r0,PC-L2         # Next bit if < MAX

L3:     add    r11,r0,2             # skip even numbers so always increment by 2
        cmp    r11,r9
        mi.mov pc,r0,L1

        halt    r0,r0,0x0001
        POP (r13,r14) # for running via monitor
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
        lsr     r3,r1           # Now complete divide by 32 into r3
        lsr     r3,r3
        lsr     r3,r3
        lsr     r3,r3           # r3 point at word number
        lsr     r3,r3           # And one more shift because we never store even flags
        and     r1,r0,0x001F    # bit position = remainder from original number div 32
        ld      r1,r1,bitmask   # Get the bitmask for that bit position
        ld      r4,r3,results   # Load the word into r4
        ror     r2,r2           # rotate LSB of r2 (function type) into carry
        nc.and  r4,r1           # if 'get' then check if bit is set and set Z or NZ (C preserved)
        c.or    r4,r1           # otherwise 'Or' in the bitmask value if carry set (and C preserved)
        c.sto   r4,r3,results   # Write back the word (C and Z preserved)
        RTS     ()

        # ------------------------------------------------------------        
        # printdec32
        #
        # Print unsigned decimal integer from a 32b number to console
        # suppressing leading zeroes
        #
        # Entry:
        #       r1  holds 32 b number to print
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
        mov r9,r0,8            # r9 points to end of 9 entry table
        mov r3,r1              # move number into r3 to sav juggling over oswrch call
pd32_l1:        
        ld r5,r9,pd32_table    # get 32b divisor from table low word first
        mov r8,r0              # set Q = 0
pd32_l1a:
        cmp  r3,r5             # Is number > decimal divisor
        nc.lmov pc,pd32_l2     # If no then skip ahead and decide whether to print the digit
        sub r3,r5              # If yes, then do the subtraction
        add r8,r0,1            # Increment the quotient
        lmov pc, pd32_l1a      # Loop again to try another subtraction
        
pd32_l2:
        mov r1,r8,48           # put ASCII val of quotient in r1
        add r7,r8              # Add digit into leading zero flag        
        nz.ljsr r13,oswrch     # Print only if the leading zero flag is non-zero

pd32_l3:
        sub r9,r0,1            # Point at the next divisor in the table 
        pl.lmov pc,pd32_l1     # If entry number >= 0 then loop again
        mov r1,r3,48           # otherwise convert remainder low word to ASCII
        JSR   (oswrch)         # and print it
        

        POPALL  ()             # Restore all high registers and return
        RTS()        


newline:
        PUSH  (r1)
        PUSH  (r2)
        PUSH  (r13)                
        mov   r1, r0, 10       # LF/CR pair to finish
        JSR   (oswrch)
        mov   r1, r0, 13
        JSR   (oswrch)
        POP   (r13)
        POP   (r2)
        POP   (r1)                
        RTS()
         
        
        # Divisor table for printdec32, 
pd32_table:
        WORD            10 
        WORD           100 
        WORD          1000 
        WORD         10000 
        WORD        100000 
        WORD       1000000 
        WORD      10000000 
        WORD     100000000 
        WORD    1000000000 


        
        # Bit masks for set_bit, get_bit
bitmask:
        WORD 0x00000001,0x00000002,0x00000004,0x00000008
        WORD 0x00000010,0x00000020,0x00000040,0x00000080
        WORD 0x00000100,0x00000200,0x00000400,0x00000800
        WORD 0x00001000,0x00002000,0x00004000,0x00008000
        WORD 0x00010000,0x00020000,0x00040000,0x00080000
        WORD 0x00100000,0x00200000,0x00400000,0x00800000
        WORD 0x01000000,0x02000000,0x04000000,0x08000000
        WORD 0x10000000,0x20000000,0x40000000,0x80000000
results: WORD   0       # results will go here

        ORG 0x00EE
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
        PUSH    (r3)
        lmov    r3,0x08000       
oswrch_loop:
        in      r2, r0, 0xfe08
        and     r2, r3
        nz.sub  pc,r0, PC-oswrch_loop
        out     r1, r0, 0xfe09
        POP     (r3)
        RTS     ()
