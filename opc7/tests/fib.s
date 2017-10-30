
MACRO   PUSH( _data_)
    mov     r14, r14, -1
    sto     _data_, r14, 1
ENDMACRO

MACRO   POP( _data_ )
    ld      _data_, r14, 1
    mov     r14, r14, 1
ENDMACRO

        # Simple Fibonacci number program ported from earlier machines

        ORG 0x0000
        mov  r10,r0,RSLTS      # initialise the results pointer
        mov  r14,r0,RETSTK     # initialise the return address stack
        mov  r5,r0             # Seed fibonacci numbers in r5,r6
        mov  r6,r0,1

        sto   r5,r10            # save r5 and r6 as first resultson results stack
        sto   r6,r10,1
        add   r10,r0,2

        mov   r4,r0,-23         # set up a counter in R4
        mov   r8,r0,FIB
LOOP:   jsr   r13,r8
CONT:   add   r4,r0,1               # inc loop counter
        nz.sub  pc,r0,PC-LOOP      # another iteration if not zero

END:    halt    r0,r0,0x999     # Finish simulation


FIB:    PUSH (r13,r14) # Push return address on stack

        mov  r2,r5          # Fibonacci computation
        add  r2,r6
        sto  r2,r10         # Push result in results stack
        add  r10,r0,1       # incrementing stack pointer

        mov   r5,r6         # Prepare r5,r6 for next iteration
        mov   r6,r2

        POP (pc,r14) # and return

        ORG 0x100

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0
