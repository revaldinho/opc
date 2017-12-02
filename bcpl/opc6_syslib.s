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
        #       r5,6  used as workspace registers and trashed
        #       r1    SIAL reg A holds 16 bit result for reads
        #       r2    SIAL reg B preserved
        #       r3    SIAL reg C trashed
        #       all other registers preserved (inc. r2)
        # --------------------------------------------------------------
        
__pbyt:                            # pbyt   b % a := c
        asr     r6,r1              # get word offset into r6
        add     r6,r2              # add word offset to base pointer
        ld      r5,r6              # read word
        asr     r0,r1              # shift odd/even bit into carry
        inc     pc, __merge_bytes-PC # (jump to merge_bytes but preserve carry)
__xpbyt:                           # xpbyt  a % b := c
        asr     r6,r2              # get word offset into r6
        add     r6,r1              # add word offset to base pointer
        ld      r5,r6              # read word
        asr     r0,r2              # shift odd/even byte into carry
__merge_bytes:                
        nc.inc   pc,__merge_bytes_1-PC #bswp not predicatable
        bswp    r3,r3              # move byte in reg C into upper half if carry set
        and     r3,r0,0xFF00       # clear lower bytes in new data if setting upper byte
        and     r5,r0,0x00FF       # clear upper bytes in old data if setting upper byte
__merge_bytes_1:        
        nc.and  r3,r0,0x00FF       # clear upper bytes in new data if setting lower byte
        nc.and  r5,r0,0xFF00       # clear lower bytes in old data if setting lower byte
        or      r5,r3              # merge old and new data
        sto     r5,r6              # write back to memory
        RTS     ()                 
                                   
__xgbyt:                           # xgbyt  a:= a % b
        asr     r6,r2              # get word offset into r6
        add     r6,r1              # add word offset to base pointer
        ld      r5,r6              # read word
        asr     r0,r2              # shift odd/even byte into carry
        inc     pc, __get_byte-PC  # jump to get_byte but preserve carry
__gbyt:                            # gbyt  a:= b % a
        asr     r6,r1              # get word offset into r6
        add     r6,r2              # add word offset to base pointer
        ld      r5,r6              # read word
        asr     r0,r1              # shift odd/even byte into carry
__get_byte:
        nc.inc   pc,__get_byte_1-PC # Skip bswp instruction if even
        bswp    r5,r5              # swap words if odd byte
__get_byte_1:   
        and     r5,r0,0x00FF       # clear upper bits
        mov     r1,r5              # put in r1 for return
        RTS     ()

        # --------------------------------------------------------------
        #
        # mul16s
        #
        # Multiply 2 16 bit numbers to yield only a 16b result
        #
        # Entry:
        #       r1    16 bit multiplier (A)
        #       r2    16 bit multiplicand (B)
        #       r13   holds return address
        #       r14   is global stack pointer
        # Exit
        #       r4    uses as workspace registers and trashed
        #       r1    16 bit result
        #       all other registers preserved (inc. r2)
        # --------------------------------------------------------------
__mulu:
        PUSH    (r2)
        lsr     r4,r1                  # shift right multiplier into r4
        mov     r1,r0
mul16s_loop0:
        c.add   r1,r2                  # add copy of multiplicand into accumulator if carry
        ASL     (r2)                   # shift left multiplicand
        lsr     r4, r4                 # shift right multiplier
        nz.dec  pc,PC-mul16s_loop0     # no need for loop counter - just stop when r1 is empty
        c.add   r1,r2                  # add last copy of multiplicand into accumulator if carry
        POP     (r2)
        RTS     ()
        
# --------------------------------------------------------------
#
# __div
#
# Divide a 16 bit number by a 16 bit number to yield a 16 b quotient and
# remainder
#
# Entry:
# - r1 16 bit dividend (A)
# - r2 16 bit divisor (B)
# - r13 holds return address
# - r14 is global stack pointer
# Exit
# - r5  upwards preserved
# - r1 = quotient
# - r2 = remainder
# --------------------------------------------------------------

__divu:

divmod:
        PUSH    (r5)
        mov     r4, r2              # Get divisor into r3
        mov     r2, r0              # Get dividend/quotient into double word r1,2
        mov     r5, r0, -16         # Setup a loop counter
udiv16_loop:
        ASL     (r1)                # shift left the quotient/dividend
        ROL     (r2,r2)             #
        cmp     r2, r4              # check if quotient is larger than divisor
        c.sub   r2, r4              # if yes then do the subtraction for real
        c.adc   r1, r0              # ... set LSB of quotient using (new) carry
        inc     r5, 1               # increment loop counter zeroing carry
        nz.inc  pc,udiv16_loop-PC   # loop again if not finished 
        POP     (r5)
        mov     pc,r13              # and return with quotient/remainder in r1/r2

# --------------------------------------------------------------
# Signed wrappers
#
# __mul
# __div
# __mod
#
# For mul and div, the sign of the result depends on the sign of both arguments
# - the A for of the wrapper achieves this

MACRO SW16A ( _sub_ )
      PUSH2   (r13, r5)
      mov     r5, r0         # keep track of signs
      add     r1, r0
      pl.inc  pc, l1_@ - PC
      NEG     (r1)
      inc     r5, 1
l1_@:
      add     r2, r0
      pl.inc  pc, l2_@ - PC
      NEG     (r2)
      dec     r5, 1
l2_@:
      JSR     (_sub_)
      cmp     r5, r0
      z.inc   pc, l3_@ - PC
      NEG2    (r2, r1)
l3_@:
      POP2    (r13, r5)
      mov     pc, r13
ENDMACRO

__mul:
      SW16A(__mulu)

__div:
      SW16A(__divu)

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
        JSR     (__divu)        # do a unsigned divide/mod operation        
                                # result is quo in r1, rem in r2
                                # now adjust based on sign of original r2
        not     r1,r2,-1        # put -remainder in r1
        POP     (r4)            # get original 'b'
        pl.mov  r1,r2           # if was +ve then put rem in r1 instead
        mov     r2,r4           # restore r2 = 'b'
        POP     (r13)
        RTS     ()              # pop return address into pc to return
        
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
        JSR     (__divu)        # do a unsigned divide/mod operation        
                                # result is quo in r1, rem in r2
                                # now adjust based on sign of original r2
        not     r1,r2,-1        # put -remainder in r1
        POP     (r4)            # get original 'a'
        cmp     r4,r0
        pl.mov  r1,r2           # if was +ve then put rem in r1 instead
        POP     (r2)            # restore original b
        POP     (r13)
        RTS     ()              # pop return address into pc to return

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
        
__sys:
                                        # BCPL routine entry boilerplate:
        sto     r11,r3                  # Save old stack pointer into new frame
        mov     r11,r3                  # Update  stack pointer
        sto     r13,r11,1               # Save return address
        sto     r4,r11,2                # Save entry address
        sto     r1,r11,3                # Save first parameter = system call
        ld      r4,r11,4                # Get second parameter in r4        
        mov     r13,r0,__sys_return     # provide return address for all syscalls

        cmp     r1,r0,K_Sys_EXT         # look for Sys_EXT first - like time critical code
        z.mov   pc,r0,__Sys_EXT        
        cmp     r1,r0,K_Sys_getvec
        z.mov   pc,r0,__Sys_getvec
        cmp     r1,r0,K_Sys_freevec
        z.mov   pc,r0,__Sys_freevec
        cmp     r1,r0,K_Sys_sawrch
        z.mov   pc,r0,__Sys_sawrch
        cmp     r1,r0,K_Sys_sardch
        z.mov   pc,r0,__Sys_sardch
        ## Any undecoded calls result in system exit
        mov     pc,r0,__Sys_quit
__sys_return:     
                                         # BCPL routine exit boilerplate:
        ld r4,r11,1                      # move return address to r4
        ld r11,r11                       # restore old stack pointer
        mov pc,r4                        # return to calling routine


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
        jsr     r13, r4           # call user routine
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
        mov     pc,r0,__sys_exit        # jump to exit of start proc
        

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

