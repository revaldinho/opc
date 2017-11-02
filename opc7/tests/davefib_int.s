MACRO PUSH( _r_)
            mov     r14, r14, -1
            sto     _r_, r14, 1
ENDMACRO

MACRO POP( _r_)
            ld      _r_, r14, 1
            mov     r14, r14, 0x0001
ENDMACRO


        ORG 0x0000
        mov pc,r0,codestart

    # Interrupt service routine - assume R14 used as stack pointer
    # Just check whether a hardware or software interrupt and log appropriately

        ORG    0x0002
INT:
        PUSH   (r13)
        PUSH   (r12)
        lmov     r12,SWI_LOG  # default to SI_LOG
        getpsr  r13,psr         # get PSR into r13
        and     r13,r0,0xF0     # mask off SWI bits
        z.lmov  r12,HWI_LOG  # if nonzero then point at HI_LOG instead
        ld      r13,r12         # get count
        add     r13,r0,1        # increment count
        sto     r13,r12         # write back
        POP     (r12)           # restore registers
        POP     (r13)
        rti     pc,pc



codestart:
        lmov   r14,STACK   # Setup global stack pointer
        mov    r13,r0
        mov    r12,r0
        lmov   r1,0x08
        putpsr psr,r1         # Enable interrupts

fib:
        lmov    r4, results
        lmov    r5, fibEnd
        lmov    r6, fibLoop
        lmov    r10, 1

        mov     r1, r0    # r1 = 0
        mov     r2, r10   # r2 = 1
fibLoop:
        add     r1, r2
        c.mov   pc, r5     # r5 = fibEnd
        sto     r1, r4     # r4 = results
        add     r4, r10    # r10 = 1
        add     r2, r1
        c.mov   pc, r5     # r5 = fibEnd
        sto     r2, r4     # r4 = results
        add     r4, r10    # r10 = 1
        mov     pc, r6     # r6 = fibLoop

fibEnd:
        # cause a SWI
        putpsr  psr, r0, 0x18
        putpsr  psr, r0, 0x28
        putpsr  psr, r0, 0x38
        halt    r0, r0, 0x999

        ORG 0x100
results:
        ORG 0x500
SWI_LOG:  WORD 0                 # software interrupt count


        ORG     0xFF00
STACK:  WORD    0,0,0,0         # Reserve some stack space
    WORD    0,0,0,0
    WORD    0,0,0,0
    WORD    0,0,0,0



        ORG 0xFFFF
HWI_LOG:  WORD 0                 # hardware interrupt count
