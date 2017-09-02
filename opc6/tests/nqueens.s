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
MACRO   RTS ()
        mov     pc,r13
ENDMACRO
MACRO   JSR (_addr_)
        jsr     r13,r0,_addr_
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
MACRO   PRINT_NL()
        jsr     r13,r0,print_nl
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
        EQU   NQUEENS,8        # set number of queens and n x n board (usu 8)

start:
        push  r13,r14           # for running via monitor
        mov     r12,r0,NQUEENS  # r12 == R
        mov     r11,r0          # r11 == S
        mov     r10,r0          # r10 == X
        mov     r9,r0           # r9  == Y
L40:    cmp     r10,r12         # L1: IF X=R THEN L140 (all results)
        nz.inc  pc,L40s-PC      # Skip display if X!=R
        JSR     (display_result)
        mov     pc,r0,L140      # Run another iteration
L40s:   
        inc     r10,1           # X = X+1
        sto     r12,r10,results # A(X)=R
L70:    inc     r11,1           # S = S+1
        mov     r9,r10          # Y = X
L90:    dec     r9,1            # Y = Y-1
        z.inc   pc,L40-PC       # IF Y=0 THEN L40
        ld      r1,r10,results  # r1 = A(X)
        ld      r2,r9,results   # r2 = A(Y)
        sub     r1,r2           # T= A(X)-A(Y)
        z.inc   pc,L140-PC      # IF T=0 THEN L140
        pl.inc  pc,L90a-PC      #(not isnt predicated so skip if positive)
        not     r1,r1,-1        # T = ABS(T)
L90a:                           # IF X-Y != ABS(T) GOTO L90
        sub     r1,r10          # [if ABS(T)-X+Y!=0]
        add     r1,r9           # 
        nz.inc  pc,L90-PC       
L140:   ld      r1,r10,results  # r1 = A(X)
        dec     r1,1
        sto     r1,r10,results  # A(X) = A(X)-1
        nz.mov  pc,r0,L70       # IF A(X) GOTO L70
        dec     r10,1           # X = X-1
        nz.inc  pc,L140-PC      # IF X GOTO L140
L180:   mov     r2,r0
        mov     r1,r11
        jsr     r13,r0,printdec32 # Print S
        mov      r1,r0,10
        jsr     r13,r0,oswrch
        mov      r1,r0,13
        jsr     r13,r0,oswrch
        halt    r0,r0,0xBEEB
        pop     r13,r14         # for running via monitor
        RTS     ()
        
display_result:
        PUSHALL ()
        # Dump contents of the results area (from index 1 upwards)
        PRINT_NL()        
        mov     r10,r0
P1:     ld      r1,r10,results+1
        mov     r1,r1,48        # Turn digit to ASCII
        JSR     (oswrch)        # Print digit
        mov     r1,r0,32        # Space
        JSR     (oswrch)
        inc     r10,1
        cmp     r10,r0,NQUEENS
        nz.mov  pc,r0,P1
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
        inc     r12,1
        cmp     r12,r0,NQUEENS+1
        mi.mov  pc,r0,P2        
        PRINT_NL()

        # Now print row by row
        mov     r12,r0,1
P3:     mov     r1,r12,48       # turn row number to ASCII
        JSR     (oswrch)
        mov     r1,r0,32        # SPACE
        JSR     (oswrch)        
        ld      r6,r12,results  # get Q column number
        mov     r5,r0,1
P4:     mov     r1,r0,32        # SPACE
        JSR     (oswrch)
        cmp     r5,r6
        z.mov   pc,r0,P5
        mov     r1,r0,32        # SPACE        
        JSR     (oswrch)
        inc     r5,1
        mov     pc,r0,P4
P5:     mov     r1,r0,ord('Q')
        JSR     (oswrch)
        PRINT_NL()
        inc     r12,1
        cmp     r12,r0,NQUEENS+1
        nz.mov  pc,r0,P3
        POPALL()
        RTS()



print_nl:
        push    r13,r14
        mov     r1,r0,10
        jsr     r13,r0,oswrch        
        mov     r1,r0,13
        jsr     r13,r0,oswrch
        pop     r13,r14
        RTS     ()
        
        # ------------------------------------------------------------        
        # printdec32
        #
        # Print unsigned decimal integer from a 32b number to console
        # suppressing leading zeroes 
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
