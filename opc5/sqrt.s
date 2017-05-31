MACRO   PUSH( _data_, _ptr_)
        sto     _data_,_ptr_
        add.i   _ptr_,r0,1
ENDMACRO

MACRO   PUSH4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        sto     _d0_,_ptr_
        sto     _d1_,_ptr_,1
        sto     _d2_,_ptr_,2
        sto     _d3_,_ptr_,3
        add.i   _ptr_,r0,4
ENDMACRO

MACRO   POP( _data_, _ptr_)
        add.i   _ptr_,r0,-1
        ld      _data_, _ptr_
ENDMACRO

MACRO   POP4( _d0_,_d1_,_d2_,_d3_, _ptr_)
        add.i   _ptr_,r0,-4
        ld      _d3_, _ptr_
        ld      _d2_, _ptr_,1
        ld      _d1_, _ptr_,2
        ld      _d0_, _ptr_,3
ENDMACRO

MACRO   CLC()
        add.i r0,r0
ENDMACRO

MACRO   SEC()
        ror.i r0,r0,1
ENDMACRO

MACRO   ROL( _reg_ )
        adc.i   _reg_, _reg_
ENDMACRO

MACRO   NOT( _a_, _b_ )
        ld.i    _a_, _b_
        xor.i   _a_, r0, 0xFFFF
ENDMACRO

MACRO   FNOT( _a_, _b_, _reg_all1s_ )
        ld.i    _a_, _b_
        xor.i   _a_, _reg_all1s_
ENDMACRO



        ld.i    r14,r0,STACK   # Setup global stack pointer
        ld.i    r11,r0
        ld.i    r10,r0, DATA0-2 # R10 points to divider data (will be preincremented)
        ld.i    r12,r0, RESULTS # R12 points to area for results

outer:  add.i   r10,r0,2        # increment data pointer by 2
        ld      r2,r10          # check if we reached the (0,0) word
        add     r2,r10,1
        z.ld.i  pc,r0,end       # .. if yes, bail out
        ld.i    r1, r10         # get number to be routed
        ld.i    r2, r12         # get result area pointer
        ld.i    r13,r0, next    # save return address
        ld.i    pc, r0, sqrt    # JSR sqrt
next:   add.i   r12,r0,4        # increment result pointer by 4
        ld.i    pc,r0,outer     #  next  loop

end:
        halt    r0,r0,0x99

        # --------------------------------------------------------------
        #       
        # sqrt32
        #
        # Find integer square root of a number < 2^30
        #
        # Entry:
        # - r1 points to block of two words holding 32 bit number (A)
        # - r2 points to area of memory large enough to take the 2 word root + 2 word remainder
        # - r13 holds return address
        #   (r14 is global stack pointer)
        # Exit
        # - r10-13 preserved, r1-9 trashed
        # - Result written to memory (see above)
        # 
        # ----------------------------------------------------------------
        # Python algorithm
        # ----------------------------------------------------------------                
        #   def isqrt( num) :
        #     res = 0
        #     bit = 1 << 30; # "bit" starts at the highest power of four <= the argument.
        #     while (bit > num):
        #         bit >>= 2
        #     while (bit != 0):
        #         if (num >= res + bit) :
        #             num -= res + bit
        #             res = (res >> 1) + bit
        #         else :
        #             res >>= 1
        #         bit >>= 2
        #     return (res, num)
        # --------------------------------------------------------------

sqrt:
        PUSH    (r13, r14)      # save return address on stack
        PUSH4   (r12,r11,r10,r2, r14)   # save global registers and results pointer on stack

        ld      r2, r1,1        # get 32b number in r1,r2 (will be remainder at end)
        ld      r1, r1

        ld.i      r4, r0        # r3,r4 are the root, init to 0
        ld.i      r3, r0

        ld.i    r6, r0, 0x4000  # r5,r6 are the 'bit' var starting at 0x40000000
        ld.i    r5, r0, 0x0000

        ld.i    r12,r0, 0xFFFF  # Use r12 as all 1s reg for F(ast)NOT macro
        ld.i    r13,r0, sqrt_next # stash most often used label in r13
        #while (bit > num):
        #    bit >>= 2

        # Use r10,r11 as temp registers to hold inverted version of r1,r2
        FNOT     (r10,r1,r12)
        FNOT     (r11,r2,r12)        
sqrt_bitloop:        
        # Subtract num from bit using r7,r8 temporary registers
        ld.i    r7,r10
        ld.i    r8,r11
        add.i   r7,r5,1
        adc.i   r8,r6
        nc.ld.i  pc,r13         # r13=sqrt_next - done if carry out is set
        z.ld.i  pc,r13          # r13=sqrt_next - or if zero is set (and carry clear)
        CLC     ()
        ror.i   r6,r6           # rotate bit right (carry clear)
        ror.i   r5,r5
        CLC     ()
        ror.i   r6,r6           # rotate bit right (carry clear)
        ror.i   r5,r5
        ld.i    pc,r0,sqrt_bitloop
sqrt_next:
        # while (bit != 0):
        ld.i    r8, r5
        or.i    r8, r6
        z.ld.i  pc,r0, sqrt_next2
        #    if (num >= res + bit) :
        #        num -= res + bit
        #        res = (res >> 1) + bit
        #    else :
        #        res >>= 1
        # Add res + bit
        ld.i    r7,r5
        ld.i    r8,r6
        add.i   r7,r3
        adc.i   r8,r4
        # Subtract r7,r8 (res+bit) from r1,r2 (num) without storing back in num...yet ..so use temp var r9,r10
        FNOT     (r9,r7,r12)
        FNOT     (r10,r8,r12)
        add.i   r9,r1,1
        adc.i   r10,r2
        # Greater or equal than means c=1 from subtraction
        c.ld.i  pc,r0,sqrt_mmask   # If < just shift root and next iteration
        CLC     ()                 # Clear carry and shift root right
        ror.i   r4,r4
        ror.i   r3,r3
        ld.i    pc,r0,sqrt_next3

sqrt_mmask:
        # If >= then copy result into num r1r2, rotate and merge mask into bit
        ld.i    r2,r10          # Copy subtraction result into num r1,r2
        ld.i    r1,r9
        CLC     ()              # Clear carry and shift root right
        ror.i   r4,r4
        ror.i   r3,r3
        or.i    r4,r6          # Now OR in the mask
        or.i    r3,r5

sqrt_next3:     
        #    bit >>= 2
        CLC     ()
        ror.i   r6,r6
        ror.i   r5,r5
        CLC     ()
        ror.i   r6,r6
        ror.i   r5,r5
        ld.i    pc,r13          # r13=sqrt_next

sqrt_next2:
        # root in r3,r4, num/remainder in r1,r2
        POP     (r6,r14)        # Pop results pointer off the stack
        sto     r3,r6,0         # save results, root first ..
        sto     r4,r6,1
        sto     r1,r6,2         # .. then remainder
        sto     r2,r6,3
        POP4    (r10,r11,r12,r13, r14)         # restore all other registers
        ld.i    pc,r13          # and return

        ORG     0x100
STACK:  WORD    0,0,0,0         # Reserve some stack space
        WORD    0,0,0,0
        WORD    0,0,0,0
        WORD    0,0,0,0  
DATA0:
        WORD 0x0001,0x0000,0x0002,0x0000
        WORD 0x0003,0x0000,0x0004,0x0000
        WORD 0x0009,0x0000,0x000A,0x0000
        WORD 0x0010,0x0000,0x0011,0x0000                        
        WORD 0x1111,0x0000,0x0000,0xff00                
        WORD 0x0002,0x0204,0x0501,0x0f00
        WORD 0x0000,0x2309,0x0618,0x2300
        WORD 0x0013,0x6003,0x0408,0x0a00
        WORD 0x0000,0x5044,0x0033,0x0799
        WORD 0x0011,0x4000,0x01F8,0x2003
        WORD 0x00C2,0x0004,0x00AB,0x8003
        WORD 0x1223,0x1234,0x3400,0x4300
        WORD 0x00,0x00,0x00,0x00        # all zero words to finish

        ORG     0x180
RESULTS:
