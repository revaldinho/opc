
        # BBC Tube Environment
__osword_pblk:
        WORD    0x00, 0x00           # Reserve 8 bytes for OSWORD calls
        #
        # Standard global variables (see libhdr.h) offset from the global pointer
        #
        EQU     rootnode,            9  
        EQU	result2,            10
        EQU	returncode,         11
        EQU	cis,                12
        EQU	cos,                13
        # --------------------------------------------------------------
        #
        # __pbyt,__xpbyt,__gbyt, __xgbyt
        #
        # Routines for getting and putting bytes to support string operations.
        # Each splits the byte address into word and byte number, then jumps
        # through a table on the byte number (no compare chain).
        # Uses r5,r6 temporary variables as workspace but preserves all other
        # registers, setting r1 to new data with get byte instructions. Maybe
        # no need strictly to preserve SIAL accumulator C (r3) but this is
        # preserved now anyway.
        #
        # Entry:
        #       r1    SIAL reg A
        #       r2    SIAL reg B
        #       r3    SIAL reg C - for put operations only
        #       r13   holds return address
        #       r14   is global stack pointer
        # Exit
        #       r4,5,6,7  used as workspace registers and trashed
        #       r1    SIAL reg A holds 16 bit result for reads else preserved
        #       r2    SIAL reg B preserved
        #       r3    SIAL reg C trashed
        #       all other registers preserved (inc. r2)
        # --------------------------------------------------------------
__pbyt:                            # pbyt   b % a := c
        asr     r6,r1              # word offset into r6
        mov     r7,r1              # byte offset into r7
        asr     r6,r6
        and     r7,r0,0x03         # byte number 0-3
        add     r6,r2              # add word offset to base pointer
        add     r7,r7
        add     r7,r7              # x4: the table entries are 4 words
        add     r7,pc,pbyt_tab - PC
        ld      r5,r6              # read word
        mov     pc,r7              # jump to the entry for the byte

__xpbyt:                           # xpbyt  a % b := c
        asr     r6,r2              # word offset into r6
        mov     r7,r2              # byte offset into r7
        asr     r6,r6
        and     r7,r0,0x03
        add     r6,r1              # add word offset to base pointer
        add     r7,r7
        add     r7,r7
        add     r7,pc,pbyt_tab - PC
        ld      r5,r6
        mov     pc,r7

        # Jump table on the byte number, 4 words an entry: put the bottom byte of
        # C into the byte's place in r4, clear that byte of the word, merge
pbyt_tab:
        bperm   r4,r3,0x4440       # byte 0
        bperm   r5,r5,0x3214
        or      r5,r4
        mov     pc,pc,finish_pbyt - PC
        bperm   r4,r3,0x4404       # byte 1
        bperm   r5,r5,0x3240
        or      r5,r4
        mov     pc,pc,finish_pbyt - PC
        bperm   r4,r3,0x4044       # byte 2
        bperm   r5,r5,0x3410
        or      r5,r4
        mov     pc,pc,finish_pbyt - PC
        bperm   r4,r3,0x0444       # byte 3
        bperm   r5,r5,0x4210
        or      r5,r4
finish_pbyt:
        sto     r5,r6              # write back to memory
        RTS     ()

__gbyt:                            # gbyt  a:= b % a
        asr     r6,r1              # word offset into r6
        mov     r7,r1              # byte offset into r7
        asr     r6,r6
        and     r7,r0,0x03         # byte number 0-3
        add     r6,r2              # add word offset to base pointer
        add     r7,r7              # x2: the table entries are 2 words
        add     r7,pc,gbyt_tab - PC
        ld      r5,r6              # read word
        mov     pc,r7              # jump to the entry for the byte

__xgbyt:                           # xgbyt a:= a % b
        asr     r6,r2
        mov     r7,r2
        asr     r6,r6
        and     r7,r0,0x03
        add     r6,r1
        add     r7,r7
        add     r7,pc,gbyt_tab - PC
        ld      r5,r6
        mov     pc,r7

        # Jump table on the byte number, 2 words an entry: the byte, others zero
gbyt_tab:
        bperm   r1,r5,0x4440       # byte 0
        RTS     ()
        bperm   r1,r5,0x4441       # byte 1
        RTS     ()
        bperm   r1,r5,0x4442       # byte 2
        RTS     ()
        bperm   r1,r5,0x4443       # byte 3
        RTS     ()

        # -----------------------------------------------------------------
        # __muldiv
        #
        # Multiply 2 32 bit numbers to get a 64 bit number and then
        # divide that by another 32 bit number to return 32b quotient
        # and remainder.
        #
        # (Q,R) = (A * B) / C
        #
        # This is a wrapper for the unsigned umuldiv routine
        #
        # Handling signs for muldiv:
        # 
        # A B C    Q R
        # + + +    + +
        # + + -    - +
        # + - +    - -      ie R = + if Sa = Sb      else -
        # + - -    + -         Q = - if Sa ^ Sb ^ Sc else +
        # - + +    - -
        # - + -    + -
        # - - +    + +
        # - - -    - +
        # -----------------------------------------------------------------        
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R3 holds C 
        # - R3 holds D
        #   If C != 0 then (Q,R) = (A * B ) /C otherwise
        #      IF D = 0  (Q,R) = (A * B)/2^16  ie 16.16 fixed point
        #      IF D = 1  (Q,R) = (A * B)/2^20  ie 12.20 fixed point
        #      IF D = 2+ (Q,R) = (A * B)/2^24  ie  8.24 fixed point        
        # - R13 holds return address
        # - R14 holds global stack pointer
        #
        # Exit
        # - R1 Quotient
        # - R2 Remainder
        # - R3 preserved
        # - R4 used as workspace and trashed
        # - R5 used as workspace and preserved
        # - all other registers preserved
        # -----------------------------------------------------------------
__muldiv:
        PUSH    (r13)
        PUSH 	(r5)
        PUSH 	(r3)        
        PUSH 	(r2)
        PUSH 	(r1)
        cmp     r1,r0         # ABS(A)
        mi.not  r1,r1,-1
        cmp     r2,r0         # ABS(B)
        mi.not  r2,r2,-1
        cmp     r3,r0         # ABS(C)
        mi.not  r3,r3,-1        
        JSR  	(__umuldiv)   # quotient in R1, rem in R2 on exit
        mov  	r5,r0         # Zero R5 to start accumulating sign bits
        POP  	(r4)          # Get A
        rol 	r0,r4         # Get sign of A in Carry
        rol  	r5,r0         # and into LSB of r5
        POP  	(r4)          # Get B
        rol  	r0,r4         # Get sign of B in carry
        c.xor   r5,r0,1       # XOR with sign of A if carry set
        cmp     r5,r0        
        nz.not  r2,r2,-1      # if nonzero (Sa!=Sb) then negate Remainder
        POP     (r4)          # Get C
        rol     r0,r4         # Get sign of C in carry        
        c.xor   r5,r0,1       # XOR with (Sa XOR Sb) if carry set
        cmp     r5,r0
        nz.not  r1,r1,-1      # if nonzero (Sa ^ Sb ^ Sc) then negate Quotient
        mov     r3,r4         # restore r3
        POP     (r5)          # restore r5
        POP     (r13)         # restore return address
        RTS     ()
        # -----------------------------------------------------------------
        # __umuldiv
        #
        # Multiply 2 32 bit numbers to get a 64 bit number and then
        # divide that by another 32 bit number to return quotient and remainder.
        #
        # (Q,R) = (A * B) / C
        # 
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R3 holds C
        # - R4=1 divide by 2^20 ; R4=0 divide by C
        # - R13 holds return address
        # - R14 holds global stack pointer
        #
        # Exit
        # - R1 Quotient
        # - R2 Remainder
        # - R3 preserved
        # - R4 used as workspace and trashed
        # - R5,6  used as workspace and preserved
        # - all other registers preserved
        #
        # ------------------------------------------------------------------
        # Multipler Register Usage
        #                _____________ _____________
        #               |____ r0 _____|_____ r5 ____|  Multiplicand A
        # Working Set   |____ r2 _____|_____ r1 ____|  Product
        #               |____ r4 _____|_____ r3 ____|  Multiplicand B
        #               
        #      (B starts in r3 but left shifts during operation into r4)
        # ------------------------------------------------------------------
__umuldiv:
        PUSH    (r6)
        PUSH    (r5)
        PUSH    (r4)
        mov     r6,r3         # Put divider for second part of operation in r6
        lsr     r5,r1         # Shift right multiplicant A into r5, LSB into C
        mov     r3,r2         # Move B into r3 (preserve C)
        mov     r4,r0         # Zero MSW of multiplicand B (preserve C)        
        mov     r1,r0         # initialise product LSW  (preserve C)
        mov     r2,r0         # initialise product MSW  (preserve C)
umd_l0: nc.lmov pc,umd_l2     # no carry - nothing to add
        add     r1,r3         # else add B into acc if carry from shift
        nc.add  r2,r4         # and then add the upper word of B if no carry
        c.add   r2,r4,1       # or add upper word with carry (assume that a no carry add above never results in a carry)
umd_l2: ASL     (r3)          # multiply B x 2
        rol     r4,r4
        lsr     r5,r5         # shift A to check LSB
        nz.lmov pc,umd_l0     # if A is zero then exit else loop again (preserving carry)
        nc.lmov pc,umd_l3     # no carry - go direct to division routine
        add     r1,r3         # add B into acc if carry from final shift
        nc.add  r2,r4         # and then add the upper word of B if no carry
        c.add   r2,r4,1       # or add upper word with carry (assume that a no carry add above never results in a carry)
        # ------------------------------------------------------------------
        # Division
        #                ____________ ____________
        # Working Set   |____ r2 ____|____ r1 ____| Remainder Quotient (Q shifting in from RHS)
        #               |____ r3 ____|____ r0 ____| Divisor in MSW
        # ------------------------------------------------------------------                
umd_l3: POP     (r4)          # get divide by 2^20 or C param
        mov     r3,r6         # restore r3
        cmp     r3,r0         # Check if it's zero
        nz.lmov  pc, umd_dec  # if nonzero proceed with decimal division
        PUSH    (r1)          # save low word before calculating quotient
        cmp    r4,r0,2        # Is d < 2 ?
        mi.lmov pc, umd_d2p1620  # Yes, then choose 16 or 20 bit division
umd_d2p24:              
        bperm  r1,r1,0x4443   # No, then 24 bit shift clearing upper bits in r1
        bperm  r2,r2,0x2104   # prepare upper bits from r2 and in r2
        or     r1,r2          # Merge together to complete the shift in r1
        POP    (r2)           # restore original remainder into2
        not    r4,r0          # Build 24 bit mask in r4
        movt   r4,r0,0x00FF   #
        and    r2,r4          # Compute remainder mod 2^24
        lmov   pc, umd_l4     # exit via common point     
umd_d2p1620:    
        bperm  r1,r1,0x4432   # 16 bit right shift LSW
        movt   r1,r2          # put lower 16b of MSW into LSW
        cmp    r4,r0          # is 'd'==0 ?
        z.lmov pc,umd_rem16    # Yes, then quotient is done so compute 16b remainder
        bperm  r2,r2,0x4432   # No, then finish 20b shift with shift of MSW
        lsr    r2,r2          # and then in-line the remaining 4 bit shifts from MSW->LSW
        ror    r1,r1
        lsr    r2,r2
        ror    r1,r1
        lsr    r2,r2
        ror    r1,r1
        lsr    r2,r2
        ror    r1,r1
umd_rem20:
        not    r4,r0          # Compute remainder mod 2^20 ; get 0xF_FFFF mask in r4
        movt   r4,r0,0x000F
        POP    (r2)           # Get original remainder
        and    r2,r4          # Computer remainder mod 2^20
        lmov   pc,umd_l4      # exit via common point
umd_rem16:
        POP    (r2)           # Compute remainder mod 2^16
        bperm  r2,r2,0x4410   # Mask off lower 16 bits
        lmov   pc,umd_l4      # exit via common point
        
umd_dec:
        cmp     r3,r0         # Bail out on divide by zero
        z.lmov  pc,umd_div0                
        mov     r4,r0,32      # loop counter
umd_l1: ASL     (r1)          # Shift RNQ 1 place left
        rol     r2,r2
        cmp     r2,r3         # RNQ >= divisor ?
        pl.sub  r2,r3         # Yes, then do subtract for real RNQ = RNQ - D .. and 'plus' flag will be regenerated..
        pl.add  r1,r0,1       # ..and used to selectively increment quotient (no need to propagate a carry to MSW)
        sub     r4,r0,1       # decrement loop counter
        nz.lmov pc,umd_l1
umd_l4: 
        POP     (r5)
        POP     (r6)        
        RTS     ()            # Exit r1 = quotient    ; r2 = remainder
umd_div0:
        # Should do a system abort here with divide by zero message
        POP     (r5)
        POP     (r6)        
        RTS     ()
        # -----------------------------------------------------------------
        #
        # udiv32 
        #
        # Unsigned divide of N by D, the core of __div, __xdiv, __mod and
        # __xmod below (rewritten 25/10/2026)
        #
        # Entry
        # - R1 holds N
        # - R8 holds D, at most 2**31 (the wrappers pass absolute values)
        # - R7 holds return address
        #
        # Exit
        # - R1 holds Quotient
        # - R5 holds Remainder
        # - R4 used as workspace and trashed
        # - all other registers preserved
        #
        # D = 0 gives quotient 0 and remainder N (natively it is an error).
        #
        # Leading zero bytes of N are skipped (most dividends in BCPL programs
        # fit in 16 bits), so the bits left are a multiple of 8 and the loop
        # does a byte per pass. Each bit takes 4 instructions: rol of N brings
        # the previous quotient bit in from C and sends N's next bit out to C,
        # where rol of R picks it up; cmp leaves C = 1 if R >= D, and then
        # c.sub subtracts D leaving C = 1. The counter is decremented with mov,
        # which keeps C. R < D <= 2**31 before each rol of R, so R never
        # overflows.
        # ------------------------------------------------------------------
udiv32:
        cmp     r8,r0
        z.lmov  pc,udiv_z      # divide by zero
        mov     r1,r1
        z.lmov  pc,udiv_q      # N = 0 gives quotient and remainder 0
        lmov    r4,4           # bytes of N to do
udiv_0:
        bperm   r5,r1,0x4443   # top byte of N into R5, Z set if it is zero
        nz.lmov pc,udiv_s      # top byte not zero: do the bit loop
        bperm   r1,r1,0x2104   # N := N << 8
        mov     r4,r4,-1       # one byte fewer (N != 0, so the counter stays > 0)
        lmov    pc,udiv_0
udiv_s:
        mov     r5,r0          # R := 0
        add     r0,r0          # C := 0, which the first rol of N takes in
udiv_1:
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r5,r5          # ..and into R
        cmp     r5,r8          # C = 1 if R >= D (unsigned)
        c.sub   r5,r8          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        rol     r1,r1
        rol     r5,r5
        cmp     r5,r8
        c.sub   r5,r8
        mov     r4,r4,-1       # next byte (mov keeps C)
        nz.lmov pc,udiv_1
        rol     r1,r1          # the last quotient bit
        mov     pc,r7
udiv_q:
        mov     r5,r0
        mov     pc,r7
udiv_z:
        mov     r5,r1
        mov     r1,r0
        mov     pc,r7

        # -----------------------------------------------------------------
        #
        # __div, __xdiv, __mod, __xmod
        #
        # Signed divide and remainder for the SIAL operations of the same
        # names (rewritten 25/10/2026; on OPC7 sial2opc.py no longer swaps A
        # and B for div):
        #   __div    a := b / a       __mod    a := b MOD a
        #   __xdiv   a := a / b       __xmod   a := a MOD b
        # / truncates towards zero and MOD takes the sign of the dividend.
        #
        # Entry
        # - R1, R2 hold SIAL A and B
        # - R13 holds return address
        #
        # Exit
        # - R1 holds the result
        # - R4, R5, R6, R7, R8 used as workspace and trashed
        # - all other registers preserved, including B (R2) and C (R3)
        # -----------------------------------------------------------------
__div:  ## a := b / a
        mov     r6,r1
        xor     r6,r2          # sign of the quotient in R6
        mov     r8,r1
        mi.not  r8,r8,-1       # D := ABS a
        mov     r1,r2
        mi.not  r1,r1,-1       # N := ABS b
        ljsr    r7,udiv32
        mov     r6,r6
        mi.not  r1,r1,-1       # negate the quotient if the signs differ
        RTS     ()

__xdiv: ## a := a / b
        mov     r6,r1
        xor     r6,r2          # sign of the quotient in R6
        mov     r8,r2
        mi.not  r8,r8,-1       # D := ABS b
        mov     r1,r1
        mi.not  r1,r1,-1       # N := ABS a
        ljsr    r7,udiv32
        mov     r6,r6
        mi.not  r1,r1,-1       # negate the quotient if the signs differ
        RTS     ()

__mod:  ## a := b MOD a
        mov     r8,r1
        mi.not  r8,r8,-1       # D := ABS a
        mov     r1,r2
        mi.not  r1,r1,-1       # N := ABS b
        ljsr    r7,udiv32
        mov     r1,r5
        mov     r2,r2          # (R2 is still b)
        mi.not  r1,r1,-1       # the remainder takes the sign of b
        RTS     ()

__xmod: ## a := a MOD b
        mov     r6,r1          # sign of a in R6
        mi.not  r1,r1,-1       # N := ABS a
        mov     r8,r2
        mi.not  r8,r8,-1       # D := ABS b
        ljsr    r7,udiv32
        mov     r1,r5
        mov     r6,r6
        mi.not  r1,r1,-1       # the remainder takes the sign of a
        RTS     ()

        # -----------------------------------------------------------------
        #
        # __mul
        #
        # a := b * a, the low 32 bits of the product (rewritten 27/10/2026)
        #
        # Entry
        # - R1 holds a, R2 holds b
        # - R13 holds return address
        #
        # Exit
        # - R1 holds b * a
        # - R4, R5, R6 used as workspace and trashed
        # - all other registers preserved, including B (R2) and C (R3)
        # - no stack use
        #
        # The low 32 bits of a product are the same whether the operands are
        # taken as signed or unsigned, so only the multiplier needs its sign
        # handling: a*b = -(ABS a * b) when a < 0. Using ABS a keeps the loop
        # short for small negative multipliers. Each pass adds b << k for a
        # set bit k of ABS a, which arrives in C from lsr; it stops when the
        # bits left are all 0, so a small multiplier (often a constant in A)
        # takes few passes. mov, add and lsr leave C for the following
        # instruction as noted.
__mul:
        mov     r6,r1          # sign of a in R6
        mi.not  r1,r1,-1       # ABS a
        lsr     r5,r1          # the multiplier bits left, bit 0 in C
        mov     r1,r0          # product := 0 (mov keeps C)
        mov     r4,r2          # b, shifted left each pass (mov keeps C)
mul_loop:
        c.add   r1,r4          # add b << k if bit k is set
        add     r4,r4
        lsr     r5,r5          # next bit to C; Z set when none are left
        nz.lmov pc,mul_loop
        c.add   r1,r4          # the last bit
        mov     r6,r6
        mi.not  r1,r1,-1       # negate the product if a < 0
        RTS     ()

        # -----------------------------------------------------------------
        # __mul4, __div4, __mod4, __gbyt4, __pbyt4
        #
        # For code from bcplcgopc7.b, which keeps register variables in r5-r8:
        # these change only r1-r4 (and use r14 within the call).
        #   __mul4   r1 := r2 * r1          uses r2, r3
        #   __div4   r1 := r2 / r1          uses r2-r4
        #   __mod4   r1 := r2 MOD r1        uses r2-r4
        #   __gbyt4  r1 := r2 % r1          uses r3, r4
        #   __pbyt4  r2 % r1 := r3          uses r1-r4
        # -----------------------------------------------------------------
__mul4:
        mov     r3,r1          # S from a
        mi.not  r2,r2,-1       # a < 0: negate both (the product is the same)
        mov     r3,r3
        mi.not  r1,r1,-1
        lsr     r3,r1          # the multiplier bits left, bit 0 in C
        mov     r1,r0          # product := 0 (mov keeps C)
mul4_loop:
        c.add   r1,r2          # add b << k if bit k is set
        add     r2,r2
        lsr     r3,r3          # next bit to C; Z set when none are left
        nz.lmov pc,mul4_loop
        c.add   r1,r2          # the last bit
        RTS     ()

        # __div4 and __mod4: the unsigned divide of udiv32 done in r1-r4, with
        # N (then the quotient) in r1, D in r2, the remainder in r3 and the byte
        # count in r4; the link is pushed so that r13 can hold the sign.
__div4:                        # r1 := r2 / r1
        PUSH    (r13)
        mov     r13,r1
        xor     r13,r2         # sign of the quotient in r13
        mov     r3,r1
        mov     r1,r2
        mi.not  r1,r1,-1       # N := ABS b
        mov     r2,r3
        mi.not  r2,r2,-1       # D := ABS a
        cmp     r2,r0
        z.lmov  pc,div4_z       # divide by zero
        mov     r1,r1
        z.lmov  pc,div4_q       # N = 0 gives quotient and remainder 0
        lmov    r4,4           # bytes of N to do
div4_0:
        bperm   r3,r1,0x4443   # top byte of N, Z set if it is zero
        nz.lmov pc,div4_s       # not zero: do the bit loop
        bperm   r1,r1,0x2104   # N := N << 8
        mov     r4,r4,-1       # one byte fewer (N != 0, so it stays > 0)
        lmov    pc,div4_0
div4_s:
        mov     r3,r0          # R := 0
        add     r0,r0          # C := 0, which the first rol of N takes in
div4_1:
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        mov     r4,r4,-1       # next byte (mov keeps C)
        nz.lmov pc,div4_1
        rol     r1,r1          # the last quotient bit
        lmov    pc,div4_e
div4_z:
        mov     r3,r1          # remainder N, quotient 0
        mov     r1,r0
        lmov    pc,div4_e
div4_q:
        mov     r3,r0
div4_e:
        mov     r13,r13
        mi.not  r1,r1,-1       # negate the quotient if the signs differ
        POP     (r13)
        RTS     ()

__mod4:                        # r1 := r2 MOD r1
        PUSH    (r13)
        mov     r13,r2         # sign of b in r13
        mov     r3,r1
        mov     r1,r2
        mi.not  r1,r1,-1       # N := ABS b
        mov     r2,r3
        mi.not  r2,r2,-1       # D := ABS a
        cmp     r2,r0
        z.lmov  pc,mod4_z       # divide by zero
        mov     r1,r1
        z.lmov  pc,mod4_q       # N = 0 gives quotient and remainder 0
        lmov    r4,4           # bytes of N to do
mod4_0:
        bperm   r3,r1,0x4443   # top byte of N, Z set if it is zero
        nz.lmov pc,mod4_s       # not zero: do the bit loop
        bperm   r1,r1,0x2104   # N := N << 8
        mov     r4,r4,-1       # one byte fewer (N != 0, so it stays > 0)
        lmov    pc,mod4_0
mod4_s:
        mov     r3,r0          # R := 0
        add     r0,r0          # C := 0, which the first rol of N takes in
mod4_1:
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        rol     r1,r1          # quotient bit in from C, next bit of N out to C
        rol     r3,r3          # ..and into R
        cmp     r3,r2          # C = 1 if R >= D (unsigned)
        c.sub   r3,r2          # if so subtract, leaving C = 1 as the quotient bit
        mov     r4,r4,-1       # next byte (mov keeps C)
        nz.lmov pc,mod4_1
        rol     r1,r1          # the last quotient bit
        lmov    pc,mod4_e
mod4_z:
        mov     r3,r1          # remainder N, quotient 0
        mov     r1,r0
        lmov    pc,mod4_e
mod4_q:
        mov     r3,r0
mod4_e:
        mov     r1,r3
        mov     r13,r13
        mi.not  r1,r1,-1       # the remainder takes the sign of b
        POP     (r13)
        RTS     ()

__gbyt4:
        asr     r3,r1          # word offset
        asr     r3,r3
        add     r3,r2
        ld      r4,r3          # the word
        and     r1,r0,0x03     # byte number 0-3
        add     r1,r1          # x2: the table entries are 2 words
        add     r1,pc,gbyt4_tab - PC
        mov     pc,r1
gbyt4_tab:
        bperm   r1,r4,0x4440   # byte 0
        RTS     ()
        bperm   r1,r4,0x4441   # byte 1
        RTS     ()
        bperm   r1,r4,0x4442   # byte 2
        RTS     ()
        bperm   r1,r4,0x4443   # byte 3
        RTS     ()

__pbyt4:
        asr     r4,r1          # word offset
        asr     r4,r4
        add     r2,r4          # the word's address
        and     r1,r0,0x03     # byte number 0-3
        add     r1,r1
        add     r1,r1          # x4: the table entries are 4 words
        add     r1,pc,pbyt4_tab - PC
        ld      r4,r2          # the word
        mov     pc,r1
pbyt4_tab:
        bperm   r3,r3,0x4440   # byte 0
        bperm   r4,r4,0x3214
        or      r4,r3
        mov     pc,pc,pbyt4_fin - PC
        bperm   r3,r3,0x4404   # byte 1
        bperm   r4,r4,0x3240
        or      r4,r3
        mov     pc,pc,pbyt4_fin - PC
        bperm   r3,r3,0x4044   # byte 2
        bperm   r4,r4,0x3410
        or      r4,r3
        mov     pc,pc,pbyt4_fin - PC
        bperm   r3,r3,0x0444   # byte 3
        bperm   r4,r4,0x4210
        or      r4,r3
pbyt4_fin:
        sto     r4,r2
        RTS     ()

        # -----------------------------------------------------------------
        # __lsh_bytes, __rsh_bytes
        #
        # Called by the code sial2opc.py generates for lsh and rsh (added
        # 25/10/2026) when the shift distance is 8 or more, unsigned: shift by
        # whole bytes with bperm, leaving the last 0-7 places to the caller.
        # As natively, a distance of 32 or more gives 0, and a negative
        # distance shifts the other way, done here completely (minint gives 0,
        # where natively the value is unchanged).
        #
        # Entry
        # - R1 holds the value to shift (logical shift for rsh)
        # - R4 holds the distance, 8 or more unsigned
        # - R13 holds return address
        #
        # Exit
        # - R1 shifted
        # - R4 holds the places still to shift, 0-7
        # - all other registers preserved
        # -----------------------------------------------------------------
__lsh_bytes:
        cmp     r4,r0
        mi.lmov pc,__lsh_neg   # negative distance: shift right instead
        cmp     r4,r0,32
        c.mov   r1,r0          # 32 or more places gives 0
        c.mov   r4,r0
        c.mov   pc,r13
__lsh_b1:
        bperm   r1,r1,0x2104   # R1 := R1 << 8
        sub     r4,r0,8
        cmp     r4,r0,8
        c.lmov  pc,__lsh_b1
        RTS     ()

__rsh_bytes:
        cmp     r4,r0
        mi.lmov pc,__rsh_neg   # negative distance: shift left instead
        cmp     r4,r0,32
        c.mov   r1,r0          # 32 or more places gives 0
        c.mov   r4,r0
        c.mov   pc,r13
__rsh_b1:
        bperm   r1,r1,0x4321   # R1 := R1 >> 8 (logical)
        sub     r4,r0,8
        cmp     r4,r0,8
        c.lmov  pc,__rsh_b1
        RTS     ()

__lsh_neg:                     # R1 << R4 for R4 < 0 is R1 >> -R4
        not     r4,r4,-1       # R4 := -R4
        cmp     r4,r0,32
        c.mov   r1,r0          # 32 or more places (or minint) gives 0
        c.mov   r4,r0
        c.mov   pc,r13
__lsh_n1:
        LSR     (r1,r1)
        sub     r4,r0,1
        nz.lmov pc,__lsh_n1    # R4 ends at 0: no places left for the caller
        RTS     ()

__rsh_neg:                     # R1 >> R4 for R4 < 0 is R1 << -R4
        not     r4,r4,-1       # R4 := -R4
        cmp     r4,r0,32
        c.mov   r1,r0          # 32 or more places (or minint) gives 0
        c.mov   r4,r0
        c.mov   pc,r13
__rsh_n1:
        ASL     (r1)
        sub     r4,r0,1
        nz.lmov pc,__rsh_n1    # R4 ends at 0: no places left for the caller
        RTS     ()

        # ------------------------------------------------------------
        # sys()
        #
        # Provide a sys() call at global_vector 3 for BCPL to handle
        # the following functions in EQU directives (numbering to match libhdr.h)
        #
        # Entry -
        #     Routine will be called with BCPL stack frame
        #     r3      = new stack pointer
        #     r11     = old stack pointer
        #     [r11+0] = reserved to store old stack pointer
        #     [r11+1] = reserved to store return address (also in r13)
        #     [r11+2] = reserved to store entry address (also in r4)
        #     [r11+3] = first argument (also in r1=A) - System call ID
        #     [r11+4] = second argument ...
        #     r10     = next free memory address
        #
        # Exit -
        #     r11 restored to original value
        #     Other registers dependent on system call
        # ------------------------------------------------------------
        EQU     K_Sys_EXT,       68
        EQU     K_Sys_delay,     57
        EQU     K_Sys_platform,  54
        EQU     K_Sys_getsysval, 48
        EQU     K_Sys_putsysval, 49
        EQU     K_Sys_cputime,   30
        EQU     K_Sys_muldiv,    26 
        EQU     K_Sys_getvec,    21
        EQU     K_Sys_freevec,   22
        EQU     K_Sys_sawrch,    11
        EQU     K_Sys_wrch,      11
        EQU     K_Sys_sardch,    10
        EQU     K_Sys_rdch,      10
        EQU     K_Sys_quit,       0
        EQU     K_Sys_setcount,  -1
        # sys() for code from bcplcgopc7.b. Its calls arrive with r11 already the new P (the
        # old P at P!0), arguments 1-3 in r1-r3 and 4 onwards in the frame, and expect r5-r8
        # (register variables) to be kept. wrch and rdch go straight to the ROM (as
        # __Sys_sawrch and __Sys_sardch do); the others go through __sys, with arguments 2
        # and 3 put in the frame, r11 back as __sys expects, and r5-r8 saved.
__sys_regargs:
        cmp     r1,r0,K_Sys_sawrch
        z.lmov  pc,__sysr_wrch
        cmp     r1,r0,K_Sys_sardch
        z.lmov  pc,__sysr_rdch
        sto     r2,r11,4
        sto     r3,r11,5
        mov     r3,r11                  # __sys makes its frame from r3
        ld      r11,r11
        PUSH    (r13)
        PUSH    (r5)
        PUSH    (r6)
        PUSH    (r7)
        PUSH    (r8)
        ljsr    r13,__sys               # returns with r11 the old P
        POP     (r8)
        POP     (r7)
        POP     (r6)
        POP     (r5)
        POP     (r13)
        RTS     ()
__sysr_wrch:
        PUSH    (r13)
        mov     r1,r2
        JSR     (oswrch)
        POP     (r13)
        ld      r11,r11
        RTS     ()
__sysr_rdch:
        PUSH    (r13)
        PUSH    (r12)                   # tuberom osrdch implementation uses r12 as a temp
        JSR     (osrdch)
        POP     (r12)
        POP     (r13)
        ld      r11,r11
        RTS     ()
__sys:
        cmp     r1,r0,K_Sys_sawrch      # wrch and rdch first, without making a frame
        z.lmov  pc,__sys_wrch           # (added 13/11/2026)
        cmp     r1,r0,K_Sys_sardch
        z.lmov  pc,__sys_rdch
                                        # BCPL routine entry boilerplate:
        sto     r11,r3                  # Save old stack pointer into new frame
        mov     r11,r3                  # Update  stack pointer
        sto     r13,r11,1               # Save return address
        sto     r4,r11,2                # Save entry address
        sto     r1,r11,3                # Save first parameter = system call
        ld      r4,r11,4                # Get second parameter in r4
        lmov    r13,__sys_return        # provide return address for all syscalls

        cmp     r1,r0,K_Sys_EXT         # look for Sys_EXT first - like time critical code
        z.lmov  pc,__Sys_EXT
        cmp     r1,r0,K_Sys_delay
        z.lmov  pc,__Sys_delay        
        cmp     r1,r0,K_Sys_getvec
        z.lmov  pc,__Sys_getvec
        cmp     r1,r0,K_Sys_freevec
        z.lmov  pc,__Sys_freevec
        cmp     r1,r0,K_Sys_sawrch
        z.lmov  pc,__Sys_sawrch
        cmp     r1,r0,K_Sys_sardch
        z.lmov  pc,__Sys_sardch
        cmp     r1,r0,K_Sys_muldiv
        z.lmov  pc,__Sys_muldiv
        cmp     r1,r0,K_Sys_cputime    
        z.lmov  pc,__Sys_cputime
        cmp     r1,r0,K_Sys_platform
        z.lmov  pc,__Sys_platform
        cmp     r1,r0,K_Sys_getsysval
        z.lmov  pc,__Sys_getsysval
        cmp     r1,r0,K_Sys_putsysval
        z.lmov  pc,__Sys_putsysval
        
                                        # Small subset of codes for unimplemented calls which use a dummy function
                                        # rather than causing a system quite
        cmp     r1,r0,K_Sys_setcount    
        z.lmov  pc,__Sys_dummy
        ## Any other undecoded calls result in system exit
        lmov    pc,__Sys_quit
__sys_return:
                                         # BCPL routine exit boilerplate:
        ld r4,r11,1                      # move return address to r4
        ld r11,r11                       # restore old stack pointer
        mov pc,r4                        # return to calling routine

        # ------------------------------------------------------------
        # __sys_wrch, __sys_rdch
        #
        # sys(Sys_sawrch, ch) and sys(Sys_sardch) straight from __sys, with
        # no frame and no search for the call: as __Sys_sawrch and
        # __Sys_sardch, with the character in the new frame (r3) at P!4
        # (added 13/11/2026)
        # ------------------------------------------------------------
__sys_wrch:
        PUSH    (r13)
        PUSH    (r2)
        ld      r4,r3,4                 # the character
        mov     r1,r4
        JSR     (oswrch)
        mov     r1,r4
        POP     (r2)
        POP     (r13)
        RTS     ()

__sys_rdch:
        PUSH    (r13)
        PUSH    (r12)   # tuberom osrdch implementatio uses r12 as a temp
        PUSH    (r2)
        JSR     (osrdch)
        POP     (r2)
        POP     (r12)
        POP     (r13)
        RTS     ()

        # ------------------------------------------------------------
        # Sys_dummy()
        #
        # Provide a dummy call and return for some as-yet-unimplemented
        # functions to use.
        #
        # Entry:
        # Exit:
        #       r1  - holds data returned from function
        # ------------------------------------------------------------

__Sys_dummy:      
        RTS     ()                # return via sys function

        # ------------------------------------------------------------
        # Sys_muldiv()
        #
        # Call library muldiv function
        #
        # sys( Sys_muldiv, A, B, C, div2pow20 )
        #
        # Entry:
        #       r4 - holds first parameter
        #       r13- hold return address (to clean up stack in main sys fn)
        #       Mem[r11+5] points to parameter2 ...
        #
        # Exit:
        #       r1  - quotient
        #       r2  - remainder
        # ------------------------------------------------------------
__Sys_muldiv:
        PUSH    (r13)
        PUSH    (r4)        
        PUSH    (r3)
        PUSH    (r2)
        mov     r1,r4             # put parameter A in r1
        ld      r2,r11,5          # put parameter B in r2
        ld      r3,r11,6          # put parameter C in r3
        ld      r4,r11,7          # put div2pow20 parameter in  r4
        JSR     (__muldiv)        # On return quotient in R1 and Remainder in R2
        sto     r2,r12,result2    # Need to put second result into global vector variable 'result2'
        POP     (r2)              # restore original r2 = Accumulator B
        POP     (r3)              # restore original r3 = Accumulator C
        POP     (r4)        
        POP     (r13)
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_getsysval
        #
        # Return a word from an absolute system memory address
        #
        # sys( Sys_getsysval, <addr> )
        #
        # Entry:
        #       r4  - holds address 
        #       r13 - hold return address (to clean up stack in main sys fn)
        #
        # Exit:
        #       r1  - return value
        #       all other registers preserved
        # ------------------------------------------------------------
__Sys_getsysval:
        ld      r1, r4            # Read address directly
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_putsysval
        #
        # write a data word to an absolute system memory address
        #
        # sys( Sys_putsysval, <addr>, <data> )
        #
        # Entry:
        #       r4  - holds address 
        #       r13 - hold return address (to clean up stack in main sys fn)
        #       Mem[r11+5] points to data parameter
        # Exit:
        #       r1  - return value
        #       all other registers preserved
        # ------------------------------------------------------------
__Sys_putsysval:
        ld      r1,r11,5          # Get data parameter
        sto     r1, r4            # Write to address directly
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_platform()
        #
        # Return ID number of platform after query to OSBYTE
        #
        # sys( Sys_platform )
        #
        # Entry:
        #       r13 - hold return address (to clean up stack in main sys fn)
        #
        # Exit:
        #       r1  - platformid
        #       all other registers preserved
        #
        # On return from OSBYTE on a BBC system,  R2=host/OS type:
        #    0 Electron                   8 UNIX or UNIX-type system
        #    1 BBC                        9 6809/6309 system with "dir/file.ext"
        #    2 BBC B+                    17 6809/6309 system with "dir.file/ext"
        #    3 Master 128
        #    4 Master ET                 28 Commodore 64/128
        #    5 Master Compact            29 Texas Instruments calculator
        #    6 Arthur or RISC OS         30 Amstrad CPC
        #    7 Springboard               31 Sinclair ZX Spectrum
        #    32+ IBM PC-type system (DOS, Windows, etc.)
        #
        # ... but on a non-BBC system the returned value in R2 is unchanged
        #
        # Need to add 32 to each of these to avoid already allocated BCPL
        # platform IDs
        # ------------------------------------------------------------
__Sys_platform:
        PUSH    (r13)
        PUSH    (r12)             # OSBYTE trashes r12
        PUSH    (r3)
        PUSH    (r2)
        mov     r1, r0            # OSBYTE call 0
        mov     r2, r0, 0x00FF    # Dummy value in R2
        JSR     (OSBYTE)          # 
        mov     r1, r2            # transfer return value into r1
        cmp     r1, r0, 0x00FF    # is it the dummy value taken in ?
        nz.add  r1, r0, 0x0020    # if not then add 32 to get the BCPL ID
        POP     (r2)              # restore original r2 = Accumulator B
        POP     (r3)              # restore original r3 = Accumulator C
        POP     (r12)             # restore r12
        POP     (r13)             # restore return address        
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_cputime()
        #
        # Return number of ms since system ON time
        #
        # sys( Sys_cputime )
        #
        # Entry:
        #       r13 - hold return address (to clean up stack in main sys fn)
        #
        # Exit:
        #       r1  - cpu time in ms
        #       all other registers preserved
        # ------------------------------------------------------------
__Sys_cputime:
        PUSH    (r13)
        PUSH    (r12)             # OSWORD trashes r12
        PUSH    (r3)
        PUSH    (r2)
        mov     r1, r0, 1         # OSWORD call 1 = GETTIME
        lmov    r2, __osword_pblk # r2 points at memory for return data
        JSR     (OSWORD)          # get time in first word of __osword_pblk in 100ths of s
        lld     r1, __osword_pblk # get value in r1
        CLC     ()
        rol     r1,r1             # multiply by 10 to get 1000ths
        rol     r2,r1
        rol     r2,r2        
        add     r1,r2 
        pl.add  r1,r0,1           # Round up R1 if remainder >=5
        POP     (r2)              # restore original r2 = Accumulator B
        POP     (r3)              # restore original r3 = Accumulator C
        POP     (r12)             # restore r12
        POP     (r13)             # restore return address        
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_delay()
        #
        # Wait given number of ms
        #
        # sys( Sys_delay, delay_ms )
        #
        # Entry:
        #       r4  - holds delay in ms
        #       r13 - hold return address (to clean up stack in main sys fn)
        #
        # Exit:
        #       r6 used as workspace and trashed, all registers preserved
        # ------------------------------------------------------------
__Sys_delay:
        PUSH    (r13)
        PUSH    (r1)
        JSR     (__Sys_cputime)   # get time now
        mov     r6,r1             # move time into r6
__Sys_delay_l0: 
        JSR     (__Sys_cputime)   # get time now
        sub     r1,r6             # get difference from first call
        cmp     r1,r4             # > required time?
        mi.lmov pc, __Sys_delay_l0 # no, try again
        POP     (r1)
        POP     (r13)             # restore return address        
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_EXT()
        #
        # Call a user function written in assembler
        #
        # sys( Sys_ext, <addr>, <parameter1>, <parameter2> ... )
        #
        # Entry:
        #       r4 - holds address of subroutine to call
        #       r13- hold return address (to clean up stack in main sys fn)
        #       Mem[r11+5] points to parameter2 ...
        #
        # Exit:
        #       r1  - holds data returned from function
        # ------------------------------------------------------------
__Sys_EXT:
        PUSH    (r13)
        PUSH    (r2)
        ld      r1, r11,5         # get parameter1 in r1
        mov     r2, r11,6         # use r2 to point to vector of other parameters
        jsr     r13, r4            # call user routine
        POP     (r2)
        POP     (r13)
        RTS     ()                # return via sys function
        # ------------------------------------------------------------
        # Sys_getvec()
        #
        # Allocate a block of memory on request.
        #
        # Entry:
        #       r4 - holds number of words requested
        # Exit:
        #       r1  - holds pointer to memory area
        #       r10 - memory pointer decremented by size of vector requested
        # ------------------------------------------------------------
__Sys_getvec:
        PUSH    (r13)
        sub     r10,r4,1          # update free pointer
        mov     r1,r10            # return free pointer in r1
        POP     (r13)
        RTS()
        # ------------------------------------------------------------
        # Sys_freevec()
        #
        # Free a block of memory on request.
        #
        # ** Just returns with no change - memory management not implemented **
        #
        # Entry:
        #       r1 - holds number of words requested
        # Exit:
        #       no change
        # ------------------------------------------------------------
__Sys_freevec:
        RTS()
        # ------------------------------------------------------------
        # Sys_quit()
        #
        # immediate return to system
        # ------------------------------------------------------------
__Sys_quit:
        mov     r14,r9                  # restore stack ready to exit
        lmov    pc,__sys_exit        # jump to exit of start proc


        # ------------------------------------------------------------
        # Sys_sawrch()
        #
        # Print character in A
        #
        # Entry:
        #       r4 char to be printed
        # Exit:
        #       all registers preserved
        # ------------------------------------------------------------
__Sys_wrch:
__Sys_sawrch:
        PUSH    (r13)
        PUSH    (r2)
        mov     r1,r4
        JSR     (oswrch)
        mov     r1,r4
        POP     (r2)
        POP     (r13)
        RTS     ()

        # ------------------------------------------------------------
        # Sys_sardch()
        #
        # Read character in A
        #
        # Entry:
        #
        # Exit:
        #       r1 = fetched character
        #       all registers preserved
        # ------------------------------------------------------------
__Sys_rdch:
__Sys_sardch:
        PUSH    (r13)
        PUSH    (r12)   # tuberom osrdch implementatio uses r12 as a temp
        PUSH    (r2)
        JSR     (osrdch)
        POP     (r2)
        POP     (r12)
        POP     (r13)
        RTS     ()


