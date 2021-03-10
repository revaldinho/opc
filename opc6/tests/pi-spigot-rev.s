#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
# 16b version, with collect-9s algorithm for correcting pre-digit overflow
#

MACRO   ASL( _reg_ )
        add     _reg_, _reg_
ENDMACRO

MACRO   BCC( _cond_, _target_ )
        _cond_.add  pc,r0,_target_-PC
ENDMACRO

MACRO   SBBCC( _cond_, _target_ )
        _cond_.dec pc,PC-_target_
ENDMACRO

MACRO   SFBCC( _cond_, _target_ )
        _cond_.inc  pc,_target_-PC
ENDMACRO

MACRO   BRA( _target_ )
        add  pc,r0,_target_-PC
ENDMACRO

MACRO   SBBRA( _target_ )
        dec  pc,PC-_target_
ENDMACRO

MACRO   SFBRA( _target_ )
        inc  pc,_target_-PC
ENDMACRO

MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   DEC( _reg_, _num_ )
        dec _reg_,_num_
ENDMACRO

MACRO   INC( _reg_, _num_ )
        inc _reg_,_num_
ENDMACRO

MACRO   PUSH( _data_)
    sto     _data_, r14
    mov     r14, r14, -1
ENDMACRO

MACRO   POP( _data_ )
    mov    r14, r14, 1
    ld      _data_, r14
ENDMACRO
        
## MACRO   PUSH( _data_)
##         push    _data_, r14
## ENDMACRO
## 
## MACRO   POP( _data_ )
##         pop     _data_, r14
## ENDMACRO

MACRO   ROL( _reg_ )
        adc     _reg_, _reg_
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

MACRO   SEC()
        nc.ror     r0,r0,1
ENDMACRO

MACRO   WRCH( _reg_, _data_ )
        mov     r1, _reg_, _data_
        jsr    r13,r0,oswrch
ENDMACRO


        # Register Map
        # (r15  = PC)
        # r14   = stack pointer
        # r13   = link register
        # r12   = inner loop counter
        # r11   = Q (Result)
        # r10   = denominator
        # r9    = outer loop counter
        # r8    = predigit
        # r7    = remainder pointer
        # r6    = nines counter
        # r5    = c
        # r3,r4 = local registers
        # r1,r2 = temporary registers, parameters and return registers
        # (r0   =0)

        EQU     digits,   16          # 16
        EQU     cols,     1+(digits*10//3)            # 1 + (digits * 10/3)

        mov     r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs
        mov     r14,r0,0x0FFE           # Set stack to grow down from here for monitor
        mov     pc,r0,0x1000            # Program start at 0x1000 for use with monitor/copro

        ORG     0x1000
start:
        PUSH  (r13)

        mov     r8,r0
        mov     r4,r0
        mov     r5,r0                   # zero C

        ;; trivial banner
        WRCH    (r0, 0x4f)
        WRCH    (r0, 0x6b)
        WRCH    (r0, 0x20)

        mov     r6,r0                   # zero nines counter
                                        # Initialise remainder/denominator array using temp vars
        mov     r2,r0,2                 # r2=const 2 for initialisation, used as data for rem[] and increment val
        mov     r3,r0,cols              # loop counter i starts at index = 1
L1:     sto     r2,r3,remain-1          # store remainder value to pointer
        DEC     (r3,1)                  # next loop counter
        SBBCC    (nz,L1)

        mov     r9,r0,digits            # set up outer loop counter (digits)
L3:     mov     r11,r0                  # r11 = Q
        #
        # All loop counters count down from
        # RHS of the arrays in this loop
        #
        mov     r12,r0,cols-1           # r4 inner loop counter
        mov     r7,r0,remain+cols-1
        mov     r10,r0,(cols-1)*2 + 1   # initial denominator at furthest column + 2 (pre decrement before use)

L4:     ld      r2,r7                   # r2 <- *remptr = r[i]
        ASL     (r2)                    # Compute 16b result for r[i] * 10
        mov     r1,r2
        ASL     (r2)
        ASL     (r2)
        add     r1,r2
        add     r11,r1                  # Q <- Q + (r[i]*10)
        DEC     (r10,2)                 # next denominator
        mov     r1,r11                  # Compute Q % denom, Q // denom
        mov     r2,r10
        jsr     r13,r0,udiv16
        mov     r11,r1                  # Q<- Quotient
        sto     r2, r7                  # rem[i] <- r2
        DEC     (r7,1)                  # dec remptr
        DEC     (r12,1)                 # decr loop counter
        SFBCC   (z,L10)

        mov     r2, r12                 # Q <- Q * i
        mov     r1, r11
#        mul     r1, r2
        jsr     r13,r0,qmul16
        mov     r11,r1

        mov     pc,r0,L4                # loop again

L10:    mov     r1,r11                  # result (Q) = C + Q//10
        mov     r2,r0,10
        jsr     r13,r0,udiv16
        mov     r11,r1                  # result (Q) = quotient + C
        add     r11,r5                  # add C
        mov     r5,r2                   # (new) C = remainder from division

        cmp     r11,r0,9                # Is result a 9 ?
        SFBCC   (nz,L4b)                # No, move on
        INC     (r6,1)                  # Yes, increment 9s counter
        BRA     (SDCL6)                 # and continue with loop

L4b:    cmp     r11,r0,10               # Is result 10 and needing correction?
        BCC     (nz,SDCL5)              # if no correction needed then continue else start corrections
        INC     (r8,1)                  # increment predigit
        mov     r11,r0                  # Zero result
        WRCH    (r8,48)                 # write predigit as ASCII
        cmp     r6,r0,0
        nz.jsr     r13,r0,PRINTZEROES   # Now write out any nines as 0s
        BRA     (SDCL6b)

SDCL5:  cmp     r9,r0,digits
        SFBCC   (z, SDCL6a)             # if first digit nothing to print yet
SDCL8:  WRCH    (r8,48)                 # write predigit as ASCII
        cmp     r6,r0,0
        nz.jsr     r13,r0,PRINTNINES    # Now write out any nines

SDCL6a: cmp     r9,r0,digits-1          # Print the decimal point if this is the first digit printed
        SFBCC   (nz,SDCL6b)
        WRCH    (r0, 46 )

SDCL6b: mov     r8,r11                  # set predigit = Q
SDCL6:  DEC     (r9,1)                  # dec loop counter
        BCC     (nz,L3)

SDCL7:  WRCH    (r8,48)                 # Print last predigit (ASCII) and any nines we're holding
        cmp     r6,r0,0
        nz.jsr     r13,r0,PRINTNINES    # Now write out any nines

L7b:
        WRCH    (r0,10)                 # Print Newline to finish off
        WRCH    (r0,13)
        halt    r0,r0,0x1234
        POP     (r13)
        RTS     ()

        ; -----------------------------------------------------------------
        ;
        ; PRINTZEROES/PRINTNINES
        ;
        ; Print a string of nines or zeroes depending on the entry point.
        ; The number of digits is given by the value in r6 on entry.
        ;
        ; Entry
        ; - R6 holds a **non-zero** number of digits to print
        ; - R13 holds return address
        ;
        ; Exit
        ; - R6 holds zero
        ; - R3, R2, R1, R0 used as workspace and trashed (inc by oswrch)
        ; - all other registers preserved
        ; ------------------------------------------------------------------

PRINTZEROES:
        mov     r3, r0, 48
        BRA     (pn0)
PRINTNINES:
        mov     r3, r0, 48+9
pn0:
        PUSH    (r13)
pn1:    mov     r1, r3
        jsr     r13,r0,oswrch
        dec     r6,1
        nz.mov  pc,r0,pn1
        POP     (r13)
        RTS     ()

        # -----------------------------------------------------------------
        #
        # qmul16
        #
        # Quick multiply 2 16 bit numbers and return a 16 bit number  without
        # checking for overflow conditions
        #
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R13 holds return address
        #
        # Exit
        # - R1 holds product of A and B
        # - R3 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R3 = holds first shifted copy of A
        # ------------------------------------------------------------------
qmul16:
        lsr     r3,r1           # shift A into r3
        mov     r1,r0           # initialise product (preserve C)
qm16_1:
        c.add   r1,r2           # add B into acc if carry
        ASL     (r2)            # multiply B x 2
        lsr     r3,r3           # shift A to check LSB
        SBBCC   (nz,qm16_1)     # if A is zero then exit else loop again (preserving carry)
        c.add   r1,r2           # Add last copy of multiplicand into acc if carry was set
        RTS()
        # -----------------------------------------------------------------
        #
        # udiv16 (udiv16)
        #
        # Divide 16 bit N by 16 bit D and return integer dividend and remainder
        #
        # Entry
        # - R1 holds N
        # - R2 holds D
        # - R13 holds return address
        #
        # Exit
        # - R1 holds Quotient
        # - R2 holds remainder
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
udiv16:
        mov     r3,r2                   # Save D in r3
        mov     r2,r0                   # Get dividend/quotient into double word r1,2
        mov     r4,r0,-16               # Setup a loop counter
udiv16_loop:

MACRO DIVSTEP ()        
        ASL     (r1)                    # shift left the quotient/dividend
        ROL     (r2)                    #
        cmp     r2,r3                   # check if quotient is larger than divisor
        c.sub   r2,r3                   # if yes then do the subtraction for real
        c.adc   r1,r0                   # ... set LSB of quotient using (new) carry
ENDMACRO

        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()
        DIVSTEP ()        
        inc     r4, 4                   # increment loop counter zeroing carry
#        SBBCC   (nz,udiv16_loop)        # loop again if not finished
        BCC   (nz,udiv16_loop)          # loop again if not finished        
        RTS     ()                      # and return with quotient/remainder in r1/r2

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
        SBBCC   (nz, oswrch_loop)
        out     r1, r0, 0xfe09
        RTS     ()


remain:  WORD 0                          # Array space for remainder data
