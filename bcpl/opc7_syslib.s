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
        # the following functions (numbering to match libhdr.h)
        #
        # Sys_EXT       =  68
        # Sys_getvec    =  21
        # Sys_freevec   =  22
        # Sys_(sa)wrch  =  11
        # Sys_(sa)rdch  =  10
        # Sys_callnative=  53
        # Sys_quit      =   0
        # Sys_setcount  =  -1
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
        cmp     r1,r0,K_Sys_getvec
        z.lmov  pc,__Sys_getvec
        cmp     r1,r0,K_Sys_freevec
        z.lmov  pc,__Sys_freevec
        cmp     r1,r0,K_Sys_sawrch
        z.lmov  pc,__Sys_sawrch
        cmp     r1,r0,K_Sys_sardch
        z.lmov  pc,__Sys_sardch
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
        jsr     pc, r4            # call user routine
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

