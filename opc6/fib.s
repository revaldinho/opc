# Simple Fibonacci number program ported from earlier machines

        ORG 0x0000
        mov  r10,r0,RSLTS      # initialise the results pointer
        mov  r13,r0,RETSTK     # initialise the return address stack
        mov  r5,r0             # Seed fibonacci numbers in r5,r6
        mov  r6,r0,1
        mov  r1,r0,1           # Use R1 as a constant 1 register
        mov  r11,r0,-1         # use R11 as a constant -1 register

        sto   r5,r10            # save r5 and r6 as first resultson results stack
        add r10,r1
        sto   r6,r10
        add r10,r1

        mov  r4,r0,-23         # set up a counter in R4
        mov  r14,r0,CONT       # return address in r14
        mov  r8,r0,FIB         # Store labels in registers to minimize loop instructions
LOOP:   mov  pc,r8             # JSR FIB
CONT:   add r4,r1             # inc loop counter
        nz.mov pc,r8           # another iteration if not zero

END:    halt    r0,r0,0x999     # Finish simulation


FIB:    sto    r14,r13        # Push return address on stack
        add  r13,r1         # incrementing stack pointer

        mov   r2,r5          # Fibonacci computation
        add  r2,r6
        sto    r2,r10         # Push result in results stack
        add  r10,r1         # incrementing stack pointer

        mov   r5,r6          # Prepare r5,r6 for next iteration
        mov   r6,r2

        add   r13,r11        # Pop return address of stack
        ld      pc,r13        # and return

        ORG 0x100

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0
