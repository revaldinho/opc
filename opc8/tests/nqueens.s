        # NQUEENS benchmark
        #
        # Recoded from the BASIC version on
        #
        # http://www.hpmuseum.org/cgi-sys/cgiwrap/hpmuseum/articles.cgi?read=700
        #
        # Result is stored in A[1..8] (ie not starting at 0) for a board numbered
        #
        #    1 2 3 4 5 6 7 8
        #  1   # Q #   #   #    First Solution = 8,4,1,3,6,2,7,5
        #  2 #   #   # Q #
        #  3   #   Q   #   #
        #  4 # Q #   #   #
        #  5   #   #   #   Q
        #  6 #   #   Q   #
        #  7   #   #   # Q #
        #  8 Q   #   #   #
        #

MACRO   PRINT_NL()
        ljsr    r13,r0,print_nl
ENDMACRO

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
        EQU   NQUEENS,8        # set number of queens and n x n board (usu 8)

start:
        PUSH    (r13)           # for running via monitor
        mov     r12,r0,NQUEENS  # r12 == R
        mov     r11,r0          # r11 == S
        mov     r10,r0          # r10 == X
        mov     r9,r0           # r9  == Y
L40:    cmp     r10,r12         # L1: IF X=R THEN L140 (all results)
        nz.mov  pc,pc,L40s-PC   # Skip display if X!=R
        JSR     (display_result)
        mov     pc,pc,L140-PC   # Run another iteration
L40s:
        add     r10,r0,1        # X = X+1
        lsto    r12,r10,results # A(X)=R
L70:    add     r11,r0,1        # S = S+1
        mov     r9,r10          # Y = X
L90:    sub     r9,r0,1         # Y = Y-1
        z.mov   pc,pc,L40-PC    # IF Y=0 THEN L40
        lld     r1,r10,results  # r1 = A(X)
        lld     r2,r9,results   # r2 = A(Y)
        sub     r1,r2           # T= A(X)-A(Y)
        z.mov   pc,pc,L140-PC   # IF T=0 THEN L140
        mi.not  r1,r1,-1        # T = ABS(T)
                                # IF X-Y != ABS(T) GOTO L90
        sub     r1,r10          # [if ABS(T)-X+Y!=0]
        add     r1,r9           #
        nz.mov  pc,pc,L90-PC       
L140:   lld     r1,r10,results  # r1 = A(X)
        sub     r1,r0,1
        lsto    r1,r10,results  # A(X) = A(X)-1
        nz.mov  pc,pc,L70-PC    # IF A(X) GOTO L70
        sub     r10,r0,1        # X = X-1
        nz.mov  pc,pc,L140-PC   # IF X GOTO L140
L180:   mov     r2,r0
        mov     r1,r11
        ljsr    r13,r0,printdec24 # Print S
        mov     r1,r0,10
        jsr     r13,r0,oswrch
        mov     r1,r0,13
        jsr     r13,r0,oswrch
        halt    r0,r0,0x0012
        POP     (r13) # for running via monitor
        RTS     ()

display_result:
        PUSHALL ()
        # Dump contents of the results area (from index 1 upwards)
        PRINT_NL()
        mov     r10,r0
P1:     lld     r1,r10,results+1
        mov     r1,r1,48        # Turn digit to ASCII
        JSR     (oswrch)        # Print digit
        mov     r1,r0,32        # Space
        JSR     (oswrch)
        add     r10,r0,1
        cmp     r10,r0,NQUEENS
        nz.mov  pc,pc,P1-PC
        PRINT_NL()
        PRINT_NL()

        # Now attempt to show the results on a matrix, header first
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        mov     r12,r0,1
P2:     mov     r1,r12,48
        JSR     (oswrch)
        mov     r1,r0,32
        JSR     (oswrch)
        add     r12,r0,1
        cmp     r12,r0,NQUEENS+1
        mi.mov  pc,pc,P2-PC
        PRINT_NL()

        # Now print row by row
        mov     r12,r0,1
P3:     mov     r1,r12,48       # turn row number to ASCII
        JSR     (oswrch)
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        lld     r6,r12,results  # get Q column number
        mov     r5,r0,1
P4:     mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        cmp     r5,r6
        z.mov   pc,pc,P5-PC
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        add     r5,r0,1
        mov     pc,pc,P4-PC
P5:     mov     r1,r0,ord('Q')
        JSR     (oswrch)
        PRINT_NL()
        add     r12,r0,1
        cmp     r12,r0,NQUEENS+1
        nz.mov  pc,pc,P3-PC
        POPALL()
        RTS()



print_nl:
        PUSH    (r13) 
        mov     r1,r0,10
        jsr     r13,r0,oswrch
        mov     r1,r0,13
        jsr     r13,r0,oswrch
        POP     (r13) 
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


