#
# Program to generate Pi using the Spigot Algorithm from
#
# http://web.archive.org/web/20110716080608/http://www.mathpropress.com/stan/bibliography/spigot.pdf
#
# Full 32b version, with collect-9s algorithm for correcting pre-digit overflow
#

MACRO   ASL( _reg_ )
        add     _reg_, _reg_
ENDMACRO

MACRO   BCC( _cond_, _target_ )
        _cond_.add  pc,r0,_target_-PC
ENDMACRO

MACRO   BRA( _target_ )
        add  pc,r0,_target_-PC
ENDMACRO

MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   DEC( _reg_, _num_ )
        sub  _reg_,r0,_num_
ENDMACRO

MACRO   INC( _reg_, _num_ )
        add _reg_,r0,_num_
ENDMACRO

MACRO   POP( _data_ )
        ld      _data_, r14, 1
        mov     r14, r14, 1
ENDMACRO

MACRO   PUSH( _data_)
        mov     r14, r14, -1
        sto     _data_, r14, 1
ENDMACRO

MACRO   ROL( _reg_ )
        rol     _reg_, _reg_
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

MACRO   SEC()
        nc.ror     r0,r0,1
ENDMACRO

MACRO PRINTNINES ( _ninesreg_, _value_ )
        cmp     _ninesreg_,r0,0
        z.mov   pc,r0,@cont
@l1:    mov     r1,r0,48+_value_
        ljsr    r13,oswrch
        sub     _ninesreg_,r0,1
        nz.mov  pc,r0,@l1
@cont:
ENDMACRO

MACRO   WRCH( _reg_, _data_ )
        mov     r1, _reg_, _data_
        ljsr    r13,oswrch
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

        EQU     digits,   8          # 16
        EQU     cols,     1+(digits*10//3)            # 1 + (digits * 10/3)

        mov   r13,r0                  # Initialise r13 to stop PUSH/POP ever loading X's to stack for regression runs
        mov   r14,r0,0x0FFE           # Set stack to grow down from here for monitor
        mov   pc,r0,0x1000            # Program start at 0x1000 for use with monitor/copro
        mov   r5,r0,0                 # zero C

        ORG   0x1000
start:
        PUSH  (r13)

        mov     r8,r0,0
        mov     r4,r0,0
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
        BCC     (nz,L1)

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
        mov     r1,r11,r0               # Compute Q % denom, Q // denom
        mov     r2,r10,r0
        ljsr    r13,udiv32
        mov     r11,r1                  # Q<- Quotient
        sto     r2, r7                  # rem[i] <- r2
        DEC     (r7,1)                  # dec remptr
        DEC     (r12,1)                 # decr loop counter
        BCC     (z,L10)                 # break out if zero

        mov     r2, r12                 # Q <- Q * i
        mov     r1, r11,0
        ljsr    r13,qmul32
        mov     r11,r1,0

        mov     pc,r0,L4                # loop again

L10:    mov     r1,r11,0                # result (Q) = C + Q//10
        mov     r2,r0,10
        ljsr    r13,udiv32
        mov     r11,r1,0                # result (Q) = quotient + C
        add     r11,r5,0                # add C
        mov     r5,r2,0                 # (new) C = remainder from division

        cmp     r11,r0,9                # Is result a 9 ?
        nz.mov  pc,r0,L4b               # No, move on
        INC     (r6,1)                  # Yes, increment 9s counter
        BRA     (SDCL6)                 # and continue with loop

L4b:    cmp     r11,r0,10               # Is result 10 and needing correction?
        BCC     (nz,SDCL5)              # if no correction needed then continue else start corrections
        INC     (r8,1)                  # increment predigit
        mov     r11,r0,0                # Zero result
        WRCH    (r8,48)                 # write predigit as ASCII

        PRINTNINES (r6,0)               # Now write out any nines as 0s
        BRA     (SDCL6b)

SDCL5:  cmp     r9,r0,digits
        BCC     (z, SDCL6a)             # if first digit nothing to print yet
SDCL8:  WRCH    (r8,48)                 # write predigit as ASCII
        PRINTNINES (r6, 9)              # Now write out any nines

SDCL6a: cmp     r9,r0,digits-1          # Print the decimal point if this is the first digit printed
        BCC     (nz,SDCL6b)
        WRCH    (r0, 46 )

SDCL6b: mov     r8,r11,0                # set predigit = Q
SDCL6:  DEC     (r9,1)                  # dec loop counter
        BCC     (nz,L3)

SDCL7:  WRCH    (r8,48)                 # Print last predigit (ASCII) and any nines we're holding

        PRINTNINES (r6,9)

L7b:
        WRCH    (r0,10)                 # Print Newline to finish off
        WRCH    (r0,13)
        halt    r0,r0,0x1234
        POP     (r13)
        RTS     ()
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
        # - R3 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R3 = holds first shifted copy of A
        # ------------------------------------------------------------------
qmul32:
        lsr     r3,r1           # shift A into r3
        mov     r1,r0           # initialise product (preserve C)
qm32_1:
        c.add   r1,r2           # add B into acc if carry
        ASL     (r2)            # multiply B x 2
        lsr     r3,r3           # shift A to check LSB
        BCC     (nz,qm32_1)     # if A is zero then exit else loop again (preserving carry)
        c.add   r1,r2           # Add last copy of multiplicand into acc if carry was set
        RTS()

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
        lmov    r4,32           # loop counter
        BRA     (udiv)
udiv16:
        lmov    r4,16           # loop counter
        movt    r1,r0
        bperm   r1, r1, 0x1044  # Move N into R5 upper half word/zero lower half
udiv:
        mov     r3,r0           # Initialise R
        cmp     r2,r0           # check D != 0
        z.mov   pc, r13         # bail out if zero (and carry will be set also)
udiv_1:
        ASL     (r1)            # left shift N
        rol     r3,r3           # left shift R and import carry into LSB
        cmp     r3, r2          # compare R with D
        pl.sub  r3, r2          # if >= 0 then do subtract for real..
        pl.add  r1,r0,1         # ..and increment quotient
        sub     r4,r0,1         # dec loop counter
        BCC     (nz,udiv_1)     # repeat 'til zero
        c.add   r0,r0           # clear carry
        mov     r2,r3           # put remainder into r2 for return
        RTS()

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
        BCC     (nz, oswrch_loop)
        out     r1, r0, 0xfe09
        RTS     ()


remain:  WORD 0                          # Array space for remainder data
