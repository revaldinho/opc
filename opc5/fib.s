# Simple Fibonacci number program ported from earlier machines

        ORG 0x0000
        ld.i  r10,r0,RSLTS      # initialise the results pointer
        ld.i  r13,r0,RETSTK     # initialise the return address stack
        ld.i  r5,r0             # Seed fibonacci numbers in r5,r6
        ld.i  r6,r0,1
        ld.i  r1,r0,1           # Use R1 as a constant 1 register
        ld.i  r11,r0,-1         # use R11 as a constant -1 register

        sto   r5,r10            # save r5 and r6 as first resultson results stack
        add.i r10,r1
        sto   r6,r10
        add.i r10,r1

        ld.i  r4,r0,-23         # set up a counter in R4
        ld.i  r14,r0,CONT       # return address in r14
        ld.i  r8,r0,FIB         # Store labels in registers to minimize loop instructions
LOOP:   ld.i  pc,r8             # JSR FIB
CONT:   add.i r4,r1             # inc loop counter
        nz.ld.i pc,r8           # another iteration if not zero

END:    halt    r0,r0,0x999     # Finish simulation


FIB:    sto    r14,r13        # Push return address on stack
        add.i  r13,r1         # incrementing stack pointer

        ld.i   r2,r5          # Fibonacci computation
        add.i  r2,r6
        sto    r2,r10         # Push result in results stack
        add.i  r10,r1         # incrementing stack pointer

        ld.i   r5,r6          # Prepare r5,r6 for next iteration
        ld.i   r6,r2

        add.i   r13,r11        # Pop return address of stack
        ld      pc,r13        # and return

        ORG 0x100

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0
