

        mov   r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs
        lmov    r14,r0,0x0FFE           # Set stack to grow down from here for monitor
        lmov    pc,r0,0x1000            # Program start at 0x1000 for use with monitor/copro


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
start:
        PUSHALL  ()


        #       Test the Multiplication
        JSR    (newline)
        SPRINT (STR5,0x00000a0d)
        SPRINT (STR6,0x0a0d0a0d)
        lmov    r12,r0,DATA
  
outer:
        ld      r1, r12,0
        z.lmov  pc,r0,qmul_test
        JSR     (printdec24)
        SPRINT  (STR2,0)
        ld      r1, r12,1
        JSR     (printdec24)
        PUSH    (r1)
        SPRINT  (STR1,0)
        ld      r1,r12,0
        ld      r2,r12,1
        mov     r5,r0
        JSR     (umul24)
        c.mov   r5,r0,1
        JSR     (printdec24)
        ror     r5,r5
        nc.mov  pc,pc,L1-PC
        SPRINT  (STR12,0)
L1:
        JSR     (newline)
        add     r12,r0,1
        mov     pc,pc,outer-PC

        
qmul_test:
        #       Test the Quick Multiplication
        JSR    (newline)
        SPRINT (STR13,0x000a0d)
        SPRINT (STR14,0x000a0d)
        lmov    r12,r0,DATA
outer0:
        ld      r1, r12,0
        z.lmov  pc,r0,div_test
        JSR     (printdec24)
        SPRINT  (STR2,0)
        ld      r1,r12,1
        JSR     (printdec24)
        PUSH    (r1)
        SPRINT (STR1,0)
        ld      r1,r12,0
        ld      r2,r12,1
        mov     r5,r0
        JSR     (qmul24)
        JSR     (printdec24)
        JSR     (newline)
        add     r12,r0,1
        mov     pc,pc,outer0-PC

        
div_test:
        JSR     (newline)
        #       Test the Division
        SPRINT (STR7,0x000a0d)
        SPRINT (STR8,0x000a0d)

        lmov    r12,r0,DATA
outer2:
        ld      r1, r12,0
        z.lmov  pc,r0,sqrt_test
        JSR     (printdec24)
        SPRINT  (STR3,0)
        ld      r1, r12,1
        JSR     (printdec24)
        SPRINT  (STR1,0)
        ld      r1,r12,0
        ld      r2,r12,1
        JSR     (udiv24)
        c.mov   r5,r0,1
        PUSH    (r2)
        JSR     (printdec24)
        lmov    r1,r0,STR4
        mov     r2, r0
        JSR     (sprint)
        POP     (r1)
        JSR     (printdec24)
        ror     r5,r5
        nc.mov  pc,pc,L2-PC
        SPRINT  (STR15,0)
L2:
        JSR     (newline)
        add     r12,r0,1
        mov     pc,pc,outer2-PC

sqrt_test:
        JSR    (newline)
        SPRINT (STR9, 0x000a0d)
        SPRINT (STR10,0x000a0d)

        lmov    r12,r0,DATA
outer3:
        ld r1, r12,0
        z.mov pc,pc,end-PC
        SPRINT (STR11,0x000000)
        ld r1, r12,0
        JSR (printdec24)
        SPRINT (STR1,0)
        ld r1,r12,0
        JSR (sqrt24)
        JSR (printdec24)
        JSR (newline)
        add r12,r0,1
        mov pc,pc,outer3-PC
end:
        halt    r0,r0,0x012
        POPALL  ()
        RTS     ()


STR1:   BSTRING " = " , "\0"
STR2:   BSTRING " x " , "\0"
STR3:   BSTRING " / " , "\0"
STR4:   BSTRING " REM ", "\0"
STR5:   BSTRING "MULTIPLICATION (UMUL24) TEST", "\0"
STR6:   BSTRING "============================", "\0"
STR7:   BSTRING "DIVISION (UDIV24) TEST", "\0"
STR8:   BSTRING "======================", "\0"
STR9:   BSTRING "SQUARE ROOT (SQRT24) TEST", "\0"
STR10:  BSTRING "=========================", "\0"
STR11:  BSTRING "Square Root of ", "\0"
STR12:  BSTRING " (Numeric overflow) ", "\0"
STR13:  BSTRING "MULTIPLICATION (QMUL24) TEST", "\0"
STR14:  BSTRING "============================", "\0"
STR15:  BSTRING " (Divide by zero) ", "\0"


DATA:
        WORD 0x000001,0x000002
        WORD 0x000003,0x000004
        WORD 0x000009,0x00000A
        WORD 0x000010,0x000011
        WORD 0x001111,0x001000
        WORD 0x240002,0x000501
        WORD 0x390000,0x000618
        WORD 0x030013,0x000008
        WORD 0x040000,0x000033
        WORD 0x000011,0x0031F8
        WORD 0x0400C2,0x0030AB
        WORD 0x241223,0x000400
        WORD 0x000000,0x000000

        # -----------------------------------------------------------------
        #
        # udiv24 (udiv16)
        #
        # Divide 24(16) bit N by 24(16) bit D and return integer dividend and remainder
        #
        # Entry
        # - R1 holds N (in lower 16b for udiv 16)
        # - R2 holds D
        # - R13 holds return address
        #
        # Exit
        # - R1 holds Quotient
        # - R2 holds remainder
        # - C = 0 if successful ; C = 1 if divide by zero
        # - R3,R4 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = N:Quotient (N shifts out of LHS/Q in from RHS)
        # - R2 = Divisor
        # - R3 = Remainder
        # - R4 = loop counter
        # -----------------------------------------------------------------
        #
        # For 16b operation, N must be moved to the upper 16 bits of R1 to
        # start so that left shifts immediately move valid bits into the carry.
        #
        # Routine returns on divide by zero with carry flag set.
        #
        # ------------------------------------------------------------------
udiv24:
        mov     r4,r0,24        # loop counter
        mov     pc, pc,udiv-PC
udiv16:
        mov    r4,r0,16         # loop counter
        bror   r1,r1            # Move N into R5 upper half word/zero lower byte
        and    r1,r0,0xFF
udiv:
        mov r3,r0          	# Initialise R
        cmp r2,r0          	# check D != 0
        z.mov pc, r13      	# bail out if zero (and carry will be set also)
udiv_1:                    	
        ASL (r1)           	# left shift N
        rol r3,r3          	# left shift R and import carry into LSB
        cmp r3, r2         	# compare R with D
        pl.sub r3, r2      	# if >= 0 then do subtract for real..
        pl.add r1,r0,1     	# ..and increment quotient
        sub r4,r0,1        	# dec loop counter
        nz.mov pc,pc,udiv_1-PC  # repeat 'til zero
        c.add r0,r0             # clear carry
        mov r2,r3               # put remainder into r2 for return
        RTS()

        # -----------------------------------------------------------------
        #
        # umul24
        #
        # Multiply 2 24 bit numbers and return a 24 bit number with Carry
        # set if overflow occurs
        #
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R13 holds return address
        #
        # Exit
        # - R1 holds product of A and B
        # - C set if overflow occurred
        # - R3 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R3 = holds first shifted copy of A
        # - R4 = sticky carry set if sign bit or carry out is ever set
        # ------------------------------------------------------------------
        #  def mul (A, B ) :
        #      SUM = 0
        #      while A != 0 :
        #          ( A,C) = ( A>>1, A &1)
        #          if C:
        #              SUM += B
        #          B <<= 1
        #      return ( SUM )
        # ------------------------------------------------------------------
umul24:
        lsr r3,r1                 # shift A into r3
        mov r1,r0                 # initialise product (preserve C)
        mov r4,r0                 # clear sticky carry (preserve C)
um24_1:                           
        c.add r1,r2               # add B into acc if carry
        mi.mov r4,r0,1            # set sticky carry if accumulation overflows
        c.mov  r4,r0,1            # set sticky carry if accumulation overflows
        ASL (r2)                  # multiply B x 2
        mi.mov r4,r0,1            # set sticky carry if accumulation overflows
        c.mov r4,r0,1             # set sticky carry if accumulation overflows
        lsr r3,r3                 # shift A to check LSB
        nz.mov pc,pc,um24_1-PC    # if A is zero then exit else loop again (preserving carry)
        c.add r1,r2               # Add last copy of multiplicand into acc if carry was set
        mi.mov r4,r0,1            # set sticky carry if accumulation overflows
        c.mov r4,r0,1             # set sticky carry if accumulation overflows
        ror r4,r4                 # rotate right sticky carry into C to return
        RTS()

        # -----------------------------------------------------------------
        #
        # qmul24
        #
        # Quick multiply 2 24 bit numbers and return a 24 bit number  without
        # checking for overflow conditions
        #
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R13 holds return address
        #
        # Exit
        # - R1 holds product of A and B
        # - C set if overflow occurred
        # - R3 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R3 = holds first shifted copy of A
        # - R4 = sticky carry set if sign bit or carry out is ever set
        # ------------------------------------------------------------------
qmul24:
        lsr r3,r1         	# shift A into r3
        mov r1,r0         	# initialise product (preserve C)
qm24_1:                   	
        c.add r1,r2       	# add B into acc if carry
        ASL (r2)          	# multiply B x 2
        lsr r3,r3         	# shift A to check LSB
        nz.mov pc,pc,qm24_1-PC  # if A is zero then exit else loop again (preserving carry)
        c.add r1,r2             # Add last copy of multiplicand into acc if carry was set
        RTS()


        # -----------------------------------------------------------------
        #
        # sqrt24
        #
        # Find square root of a 24 bit number
        #
        # Entry
        # - R1 holds number to root
        # - R13 holds return address
        #
        # Exit
        # - R1 holds square root
        # - R2,3 used as workspace and trashed
        # - all other registers preserved
        #
        # ------------------------------------------------------------------
        #
        # def isqrt( num) :
        #     res = 0
        #     bit = 1 << 22; ## Set second-to-top bit, ie b22 for 24 bits
        #     ## "bit" starts at the highest power of four <= the argument.
        #     while (bit > num):
        #         bit >>= 2
        #     while (bit != 0) :
        #         num -= res + bit
        #         if ( num >= 0 ):
        #             res = (res >> 1) + bit
        #         else:
        #             num += res + bit
        #             res >>= 1
        #         bit >>= 2
        #     return res
        #
        # ------------------------------------------------------------------
sqrt24:
        mov r2,r0                # zero result
        lmov r3,r0,0x400000       # set bit to 0x040000
sq24_L1:
        cmp r1, r3               #  compare number with bit
        pl.mov pc,pc,sq24_L2-PC  # exit loop if number >= bit
        asr r3,r3                # shift bit 2 places right
        asr r3,r3
        mov pc,pc,sq24_L1-PC

sq24_L2:
        cmp r3,r0                # is R3 zero ?
        z.mov pc,pc,sq24_L5-PC   # Yes ? then exit
        sub r1,r2                # Trial subtract r1 -= Res + bit
        sub r1,r3
        mi.mov pc,pc,sq24_L3-PC  # if <0 then need to restore r1
        asr r2,r2                # shift result right
        add r2,r3                # .. and add bit
        mov pc,pc,sq24_L4-PC
sq24_L3:
        add r1,r2             # restore r1 (add res + bit back)
        add r1,r3
        asr r2,r2             # shift result right
sq24_L4:
        asr r3,r3
        asr r3,r3
        mov pc,pc,sq24_L2-PC

sq24_L5:
        mov r1, r2            # move result into r1 for return
        RTS()


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


        # ------------------------------------------------------------
        # sprint
        #
        # Print packed byte string to console.
        #
        # Entry:
        #       r1  holds pointer to byte string terminated with zero
        #       r2  holds second byte string for end of print characters
        # Exit:
        #       r5-r13 preserved
        #       r1-r4 used for workspace
        # ------------------------------------------------------------
        #
        # If R2 == 0 then no additional characters are printed, otherwise
        # R2 might hold, say, 0x00001013 to print a CRLF pair at the end
        # of the string.
        # ------------------------------------------------------------
sprint:
        PUSH (r13)
        PUSH (r6)
        PUSH (r5)
        PUSH (r2)
        mov  r6,r1
sprint_loop:
        ld   r3,r6
        JSR  (sprint_word)
        z.mov pc, pc,sprint_eol-PC
        add  r6,r0,1
        mov pc,pc,sprint_loop-PC

sprint_eol:
        POP (r3)
        JSR (sprint_word)
sprint_exit:
        POP (r5)
        POP (r6)
        POP (r13)
        RTS ()

sprint_word:
        # Print all characters held in r3 to console
        # Exit with Zero flag set if reached a zero character
        PUSH (r13)
        mov   r1,r3
        and   r1,r0,0xFF
        z.mov pc,pc,spw_retz-PC
        JSR  (oswrch)
        bror  r3,r3,0
        mov   r1,r3
        and   r1,r0,0xFF
        z.mov pc,pc,spw_retz-PC
        JSR  (oswrch)
        bror  r3,r3,0
        mov   r1,r3
        and   r1,r0,0xFF        
        z.mov pc,pc,spw_retz-PC
        JSR  (oswrch)
spw_ret:
        POP (r13)
        mov    r1,r0,1     # Ensure Z flag not set if exiting here
        RTS()
spw_retz:
        POP (r13)
        mov r1,r0          # Ensure Z flag set if exiting here
        RTS()




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
