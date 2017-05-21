# Simple Fibonacci number program ported from earlier machines

        ORG 0x0000

        ld.i  r10,r0,RSLTS      # initialise the results pointer
        ld.i  r13,r0,RETSTK     # initialise the return address stack
        ld.i  r5,r0,0           # Seed fibonacci numbers in r5,r6
        ld.i  r6,r0,1

        sto   r5,r10,0          # save r5 and r6 as first resultson results stack
        add.i r10,r0,1
        sto   r6,r10,0
        add.i r10,r0,1

        ld.i  r4,r0,-23         # set up a counter in R4
        ld.i  r14,pc,2          # return address in r14
LOOP:   ld.i  pc,r0,FIB         # JSR FIB
        add.i r4,r0,1           # inc loop counter
        nz.ld.i pc,r0,LOOP      # another iteration if not zero

END:    halt    r0,r0,0x999     # Finish simulation


FIB:    sto    r14,r13,0        # Push return address on stack
        add.i  r13,r0,1         # incrementing stack pointer

        ld.i   r1,r5,0          # Fibonacci computation
        add.i  r1,r6,0
        sto    r1,r10,0         # Push result in results stack
        add.i  r10,r0,1         # incrementing stack pointer

        ld.i   r5,r6,0          # Prepare r5,r6 for next iteration
        ld.i   r6,r1,0

        add.i   r13,r0,-1       # Pop return address of stack
        ld      pc,r13,0        # and return

        ORG 0x100

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0
