
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
        asr     r6,r1              # get word offset into r6
        asr     r6,r6              #
        add     r6,r2              # add word offset to base pointer
        mov     r7,r1              # get byte offset in r7
        lmov    pc,common_pbyt

__xpbyt:                           # pbyt   a % b := c
        asr     r6,r2              # get word offset into r6
        asr     r6,r6              #
        add     r6,r1              # add word offset to base pointer
        mov     r7,r2              # get byte offset in r7

common_pbyt:
        ld      r5,r6              # read word        
        and     r7,r0,0x03         # get lowest 2 bits of byte offset in r7
        z.lmov  pc, merge_1st_byte # if zero then lowest byte is target
        cmp     r7,r0,0x01         # second byte ?
        z.lmov  pc, merge_2nd_byte                 
        cmp     r7,r0,0x02         # third byte ?
        z.lmov  pc, merge_3rd_byte # else must be top byte                                                          
merge_4th_byte: 
        bperm   r4,r3,0x0444       # Put bottom byte of 'C' into top byte of r4
        bperm   r5,r5,0x4210       # zero top byte of r5, preserve others
        lmov    pc, finish_pbyt
merge_3rd_byte: 
        bperm   r4,r3,0x4044       # Put bottom byte of 'C' into 3rd byte of r4
        bperm   r5,r5,0x3410       # zero 3rd byte of r5, preserve others
        lmov    pc, finish_pbyt
merge_2nd_byte: 
        bperm   r4,r3,0x4404       # Put bottom byte of 'C' into 2nd byte of r4
        bperm   r5,r5,0x3240       # zero 2d byte of r5, preserve others
        lmov    pc, finish_pbyt
merge_1st_byte: 
        bperm   r4,r3,0x4440       # Put bottom byte of 'C' into bottom byte of r4
        bperm   r5,r5,0x3214       # zero bottom byte of r5, preserve others
finish_pbyt:            
        or      r5,r4              # Merge the bytes       
        sto     r5,r6              # write back to memory
        RTS     ()
        
__gbyt:                            # gbyt  a:= b % a
        asr     r6,r1              # get word offset into r6
        asr     r6,r6              #
        add     r6,r2              # add word offset to base pointer
        mov     r7,r1
        lmov    pc, common_gbyt
__xgbyt:                           # gbyt  a:= a % b
        asr     r6,r2              # get word offset into r6
        asr     r6,r6              #
        add     r6,r1              # add word offset to base pointer
        mov     r7,r2
common_gbyt:
        ld      r5,r6              # read word        
        and     r7,r0,0x03
        z.bperm r1,r5,0x4440       # if zero get lowest byte and zero others
        cmp     r7,r0,0x01         # second byte ?
        z.bperm r1,r5,0x4441       # if zero get next byte and zero others
        cmp     r7,r0,0x02         # third byte ?
        z.bperm r1,r5,0x4442       # if zero get next byte and zero others
        cmp     r7,r0,0x03         # last byte ?
        z.bperm r1,r5,0x4443       # if zero get next byte and zero others
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
        # qmul32, __mulu
        #
        # Quick multiply 2 32 bit numbers and return a 32 bit number  without
        # checking for overflow conditions
        #
        # Entry
        # - R1 holds A
        # - R2 holds B
        # - R13 holds return address
        # - R14 holds global stack pointer
        #
        # Exit
        # - R1 holds product of A and B
        # - R4,5 used as workspace and trashed
        # - all other registers preserved
        #
        # Register Usage
        # - R1 = Product Register
        # - R3 = holds first shifted copy of A
        # - R4 = sticky carry set if sign bit or carry out is ever set
        # ------------------------------------------------------------------
__mulu:
        PUSH    (r5)
        lsr     r5,r1         # shift A into r5
        mov     r1,r0         # initialise product (preserve C)
        mov     r4,r2         # move multiplicand (B) into r4, preserve C
qm32_1:
        c.add   r1,r4       # add B into acc if carry
        ASL     (r4)          # multiply B x 2
        lsr     r5,r5         # shift A to check LSB
        nz.lmov pc,qm32_1 # if A is zero then exit else loop again (preserving carry)
        c.add   r1,r4       # Add last copy of multiplicand into acc if carry was set
        POP     (r5)
        RTS()

        # -----------------------------------------------------------------
        #
        # udiv32 
        #
        # Divide 32 bit N by 32 bit D and return integer dividend and remainder
        #
        # Entry
        # - R1 holds N
        # - R2 holds D
        # - R13 holds return address
        # - R14 global stack pointer
        #
        # Exit
        # - R1 holds Quotient
        # - R2 holds remainder         
        # - C = 0 if successful ; C = 1 if divide by zero
        # - R4 used as workspace and trashed
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
__divu: 
udiv32:
        PUSH    (r5)
        lmov    r4,32          # loop counter
        mov     r5,r0          # Initialise Remainder in R5
        cmp     r2,r0          # check D != 0
        z.mov   pc, r13        # bail out if zero (and carry will be set also)
udiv_1:
        ASL     (r1)           # left shift N
        rol     r5,r5          # left shift R and import carry into LSB
        cmp     r5, r2         # compare R with D
        pl.sub  r5, r2         # if >= 0 then do subtract for real..
        pl.add  r1,r0,1        # ..and increment quotient
        sub     r4,r0,1        # dec loop counter
        nz.lmov pc,udiv_1      # repeat 'til zero
        c.add   r0,r0          # clear carry
        mov     r2,r5          # put remainder into r2 for return
        POP     (r5)
        RTS()

	# --------------------------------------------------------------
	# Signed wrappers
	#
	# __mul
	# __div
	# __mod
	#
	# For mul and div, the sign of the result depends on the sign of both arguments
	# - the A for of the wrapper achieves this

MACRO SW32A ( _sub_ )
        PUSH    (r13)
        PUSH    (r5)
        mov     r5, r0         # keep track of signs
        add     r1, r0
        pl.lmov pc,l1_@
        NEG     (r1)
        add     r5,r0, 1
l1_@:
        add     r2, r0
        pl.lmov pc,l2_@
        NEG     (r2)
        sub     r5,r0, 1
l2_@:
        ljsr    r13,_sub_
        cmp     r5, r0
        z.lmov  pc, l3_@
        NEG     (r2)         # NEG2    (r2,r1) for OPC6
        NEG     (r1)
l3_@:
        POP     (r5)
        POP     (r13)
        mov     pc, r13
ENDMACRO

__mul:
      SW32A(__mulu)

__div:
      SW32A(__divu)

        # For mod, the sign of the result depends only on the sign of the first arguments
        # - the B for of the wrapper achieves this

__mod:  ## Find signed modulus of b MOD a
        ## NB division by zero should abort !! ABORT 5: Division by zero
        PUSH    (r13)           # save return address
        PUSH    (r2)            # save r2 (b)
        mov     r4,r2           # swap over r1 and r2
        not     r2,r1,-1        # r2 <- -r1
        mi.mov  r2,r1           # if negative then r2 <- r1
        not     r1,r4,-1        # r1 <- -r4
        mi.mov  r1,r4           # if negative then r1 <- r4
        ljsr    r13,__divu      # do a unsigned divide/mod operation
                                # result is quo in r1, rem in r2
                                # now adjust based on sign of original r2
        not     r1,r2,-1        # put -remainder in r1
        POP     (r4)            # get original 'b'
        cmp     r4,r0           # compare with zero
        pl.mov  r1,r2           # if was +ve then put rem in r1 instead
        mov     r2,r4           # restore r2 = 'b'
        POP     (r13)           # pop return address 
        RTS     ()

__xmod: ## Find signed modulus of a MOD b
        ## NB division by zero should abort !! ABORT 5: Division by zero
        PUSH    (r13)           # save return address
        PUSH    (r2)            # save r2 (b)
        PUSH    (r1)            # save r1 (a) for inspection of sign later
        not     r3,r1,-1        # r1 <- -r1
        mi.mov  r3,r1           # if negative then r1 <- r1 ie A = ABS(A)
        mov     r1, r3
        not     r3,r2,-1        # r2 <- -r2
        mi.mov  r3,r2           # if negative then r2 <- r2 is A = ABS(B)
        mov     r2,r3
        ljsr    r13,__divu      # do a unsigned divide/mod operation
                                # result is quo in r1, rem in r2
                                # now adjust based on sign of original r2
        not     r1,r2,-1        # put -remainder in r1
        POP     (r4)            # get original 'a'
        cmp     r4,r0
        pl.mov  r1,r2           # if was +ve then put rem in r1 instead
        POP     (r2)            # restore original b
        POP     (r13)           # pop return address 
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
__sys:
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


