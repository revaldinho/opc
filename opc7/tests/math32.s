
MACRO BROR (_rd_, _rs_ )
        bperm _rd_,_rs_,0x0321        
ENDMACRO

MACRO BROL (_rd_, _rs_ )
        bperm _rd_,_rs_,0x2103        
ENDMACRO
        
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

MACRO   JSR( _addr_ )
    ljsr    r13,_addr_
ENDMACRO

MACRO   PUSHALL()
        mov     r14,r14, -13
        sto     r1, r14, 1
        sto     r2, r14, 2
        sto     r3, r14, 3
        sto     r4, r14, 4
        sto     r5, r14, 5
        sto     r6, r14, 6        
        sto     r7, r14, 7
        sto     r8, r14, 8
        sto     r9, r14, 9
        sto     r10, r14, 10
        sto     r11, r14, 11
        sto     r12, r14, 12
        sto     r13, r14, 13
ENDMACRO

MACRO   POPALL()
        ld      r1, r14, 1        
        ld      r2, r14, 2
        ld      r3, r14, 3
        ld      r4, r14, 4
        ld      r5, r14, 5
        ld      r6, r14, 6
        ld      r7, r14, 7
        ld      r8, r14, 8
        ld      r9, r14, 9
        ld      r10, r14, 10
        ld      r11, r14, 11
        ld      r12, r14, 12
        ld      r13, r14, 13
        mov     r14, r14, 13
ENDMACRO

MACRO   SPRINT( _str_addr_, _eol_ )
        lmov r1, _str_addr_
        lmov    r2,_eol_
        movt r2, r0, (_eol_ >> 16)
        JSR (sprint)
ENDMACRO

        mov   r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs
        lmov    r14,0x0FFE           # Set stack to grow down from here for monitor
        lmov    pc,0x1000            # Program start at 0x1000 for use with monitor/copro

        ORG   0x1000
start:
        PUSHALL  ()


        #       Test the Multiplication
        JSR    (newline)
        SPRINT (STR5,0x00000a0d)
        SPRINT (STR6,0x0a0d0a0d)
        lmov    r12,DATA

outer:
        ld r1, r12,0
        z.lmov pc,qmul_test
        JSR (printdec32)
        SPRINT (STR2,0)
        ld r1, r12,1
        JSR (printdec32)
        PUSH (r1)
        SPRINT (STR1,0)
        ld r1,r12,0
        ld r2,r12,1
        mov r5,r0
        JSR (umul32)
        c.lmov  r5,1
        JSR (printdec32)
        ror r5,r5
        nc.lmov pc, L1
        SPRINT (STR12,0)
L1:
        JSR (newline)
        add r12,r0,1
        lmov pc,outer

qmul_test:
        #       Test the Quick Multiplication
        JSR    (newline)
        SPRINT (STR13,0x00000a0d)
        SPRINT (STR14,0x0a0d0a0d)
        lmov    r12,DATA
outer0:
        ld r1, r12,0
        z.lmov pc,div_test
        JSR (printdec32)
        SPRINT (STR2,0)
        ld r1, r12,1
        JSR (printdec32)
        PUSH (r1)
        SPRINT (STR1,0)
        ld r1,r12,0
        ld r2,r12,1
        mov r5,r0
        JSR (qmul32)
        JSR (printdec32)
        JSR (newline)
        add r12,r0,1
        lmov pc,outer0

div_test:
        JSR     (newline)
        #       Test the Division
        SPRINT (STR7,0x00000a0d)
        SPRINT (STR8,0x0a0d0a0d)

        lmov    r12,DATA
outer2:
        ld r1, r12,0
        z.lmov pc,sqrt_test
        JSR (printdec32)
        SPRINT (STR3,0)
        ld r1, r12,1
        JSR (printdec32)
        SPRINT (STR1,0)
        ld r1,r12,0
        ld r2,r12,1
        JSR (udiv32)
        c.lmov  r5,1
        PUSH (r2)
        JSR (printdec32)
        lmov    r1,STR4
        mov r2, r0
        JSR (sprint)
        POP (r1)
        JSR (printdec32)
        ror r5,r5
        nc.lmov pc, L2
        SPRINT (STR15,0)
L2:
        JSR (newline)
        add r12,r0,1
        lmov pc,outer2

sqrt_test:
        JSR    (newline)
        SPRINT (STR9,0x00000a0d)
        SPRINT (STR10,0x0a0d0a0d)

        lmov    r12,DATA
outer3:
        ld r1, r12,0
        z.lmov pc,end
        SPRINT (STR11,0x000000000)
        ld r1, r12,0
        JSR (printdec32)
        SPRINT (STR1,0)
        ld r1,r12,0
        JSR (sqrt32)
        JSR (printdec32)
        JSR (newline)
        add r12,r0,1
        lmov pc,outer3
end:
        halt    r0,r0,0x1234
        POPALL  ()
        RTS     ()


STR1:   BSTRING " = " , "\0"
STR2:   BSTRING " x " , "\0"
STR3:   BSTRING " / " , "\0"
STR4:   BSTRING " REM ", "\0"
STR5:   BSTRING "MULTIPLICATION (UMUL32) TEST", "\0"
STR6:   BSTRING "============================", "\0"
STR7:   BSTRING "DIVISION (UDIV32) TEST", "\0"
STR8:   BSTRING "======================", "\0"
STR9:   BSTRING "SQUARE ROOT (SQRT32) TEST", "\0"
STR10:  BSTRING "=========================", "\0"
STR11:  BSTRING "Square Root of ", "\0"
STR12:  BSTRING " (Numeric overflow) ", "\0"
STR13:  BSTRING "MULTIPLICATION (QMUL32) TEST", "\0"
STR14:  BSTRING "============================", "\0"
STR15:  BSTRING " (Divide by zero) ", "\0"

FUNC:   WORD    umul32
        WORD    udiv32
        WORD    sqrt32

DATA:
        WORD 0x00000001,0x00000002
        WORD 0x00000003,0x00000004
        WORD 0x00000009,0x0000000A
        WORD 0x00000010,0x00000011
        WORD 0x00001111,0x00001000
        WORD 0x00240002,0x00000501
        WORD 0x00390000,0x00000618
        WORD 0x00030013,0x00000008
        WORD 0x01040000,0x00000033
        WORD 0x04000011,0x020031F8
        WORD 0x000400C2,0x000030AB
        WORD 0x00241223,0x00000400
        WORD 0x00000000,0x00000000

        # -----------------------------------------------------------------
        #
        # udiv32 (udiv16)
        #
        # Divide 32(16) bit N by 32(16) bit D and return integer dividend and remainder
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
udiv32:
        lmov    r4,32       # loop counter
        lmov pc, udiv
udiv16:
        lmov    r4,16       # loop counter
        movt r1,r0         
        bperm r1, r1, 0x1044 # Move N into R5 upper half word/zero lower half
udiv:
        mov r3,r0          # Initialise R
        cmp r2,r0          # check D != 0
        z.mov pc, r13      # bail out if zero (and carry will be set also)
udiv_1:
        ASL (r1)           # left shift N
        rol r3,r3          # left shift R and import carry into LSB
        cmp r3, r2         # compare R with D
        pl.sub r3, r2      # if >= 0 then do subtract for real..
        pl.add r1,r0,1     # ..and increment quotient
        sub r4,r0,1        # dec loop counter
        nz.lmov pc,udiv_1  # repeat 'til zero
        c.add r0,r0        # clear carry
        mov r2,r3          # put remainder into r2 for return
        RTS()

        # -----------------------------------------------------------------
        #
        # umul32
        #
        # Multiply 2 32 bit numbers and return a 32 bit number with Carry
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
umul32:
        lsr r3,r1         # shift A into r3
        mov r1,r0         # initialise product (preserve C)
        mov r4,r0         # clear sticky carry (preserve C)
um32_1:
        c.add r1,r2       # add B into acc if carry
        mi.lmov r4,1      # set sticky carry if accumulation overflows
        c.lmov  r4,1      # set sticky carry if accumulation overflows
        ASL (r2)          # multiply B x 2
        mi.lmov r4,1      # set sticky carry if accumulation overflows
        c.lmov  r4,1      # set sticky carry if accumulation overflows
        lsr r3,r3         # shift A to check LSB
        nz.lmov pc,um32_1 # if A is zero then exit else loop again (preserving carry)
        c.add r1,r2       # Add last copy of multiplicand into acc if carry was set
        mi.lmov r4,1      # set sticky carry if accumulation overflows
        c.lmov  r4,1      # set sticky carry if accumulation overflows
        ror r4,r4         # rotate right sticky carry into C to return
        RTS()

        # -----------------------------------------------------------------
        #
        # qmul32
        #
        # Quick multiply 2 32 bit numbers and return a 32 bit number  without
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
qmul32:
        lsr r3,r1         # shift A into r3
        mov r1,r0         # initialise product (preserve C)
qm32_1:
        c.add r1,r2       # add B into acc if carry
        ASL (r2)          # multiply B x 2
        lsr r3,r3         # shift A to check LSB
        nz.lmov pc,qm32_1 # if A is zero then exit else loop again (preserving carry)
        c.add r1,r2       # Add last copy of multiplicand into acc if carry was set
        RTS()


        # -----------------------------------------------------------------
        #
        # sqrt32
        #
        # Find square root of a 32 bit number
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
        #     bit = 1 << 30; ## Set second-to-top bit, ie b30 for 32 bits
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
sqrt32:
        mov r2,r0             # zero result
        mov r3,r0             # set bit to 0x04000000
        movt r3,r0,0x4000
sq32_L1:
        cmp r1, r3            #  compare number with bit
        pl.lmov pc, sq32_L2   # exit loop if number >= bit
        asr r3,r3             # shift bit 2 places right
        asr r3,r3
        lmov pc, sq32_L1

sq32_L2:
        cmp r3,r0             # is R3 zero ?
        z.lmov pc, sq32_L5   # Yes ? then exit
        sub r1,r2             # Trial subtract r1 -= Res + bit
        sub r1,r3
        mi.lmov pc, sq32_L3  # if <0 then need to restore r1
        asr r2,r2             # shift result right
        add r2,r3           # .. and add bit
        lmov pc, sq32_L4
sq32_L3:
        add r1,r2             # restore r1 (add res + bit back)
        add r1,r3
        asr r2,r2             # shift result right
sq32_L4:
        asr r3,r3
        asr r3,r3
        lmov pc, sq32_L2

sq32_L5:
        mov r1, r2            # move result into r1 for return
        RTS()


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
        PUSHALL    ()           # Save all registers above r4 to stack

        mov     r7,r0           # leading zero flag
        lmov    r9,8            # r9 points to end of 9 entry table
        mov     r3,r1           # move number into r3 to sav juggling over oswrch call
pd32_l1:
        ld      r5,r9,pd32_table # get 32b divisor from table low word first
        mov     r8,r0            # set Q = 0
pd32_l1a:
        cmp     r3,r5           # Is number > decimal divisor
        nc.lmov pc,pd32_l2      # If no then skip ahead and decide whether to print the digit
        sub     r3,r5           # If yes, then do the subtraction
        add     r8,r0,1         # Increment the quotient
        lmov    pc, pd32_l1a    # Loop again to try another subtraction

pd32_l2:
        mov     r1,r8,48        # put ASCII val of quotient in r1
        add     r7,r8           # Add digit into leading zero flag
        nz.ljsr r13,oswrch      # Print only if the leading zero flag is non-zero

pd32_l3:
        sub     r9,r0,1         # Point at the next divisor in the table
        pl.lmov pc,pd32_l1      # If entry number >= 0 then loop again
        mov     r1,r3,48        # otherwise convert remainder low word to ASCII
        JSR     (oswrch)        # and print it


        POPALL  ()              # Restore all high registers and return
        RTS()


newline:
        PUSH  (r1)
        PUSH  (r2)
        PUSH  (r13)
        lmov    r1,10       # LF/CR pair to finish
        JSR   (oswrch)
        lmov    r1,13
        JSR   (oswrch)
        POP   (r13)
        POP   (r2)
        POP   (r1)
        RTS()

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
        z.lmov pc, sprint_eol
        add  r6,r0,1
        lmov pc,sprint_loop

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
        bperm r1,r3,0x7770        
        z.lmov pc,spw_retz
        JSR  (oswrch)
        bperm r1,r3,0x7771        
        z.lmov pc,spw_retz
        JSR  (oswrch)
        bperm r1,r3,0x7772
        z.lmov pc,spw_retz
        JSR  (oswrch)
        bperm r1,r3,0x7773        
        z.lmov pc,spw_retz
        JSR  (oswrch)
spw_ret:
        POP (r13)
        lmov    r1,1     # Ensure Z flag not set if exiting here
        RTS()
spw_retz:
        POP (r13)
        mov r1,r0       # Ensure Z flag set if exiting here
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
oswrch_loop:
        in      r2, r0, 0xfe08
        asr     r2, r2
        and     r2, r0, 0x4000
        nz.lmov pc, oswrch_loop
        out     r1, r0, 0xfe09
        RTS     ()
