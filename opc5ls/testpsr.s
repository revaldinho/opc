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
INT:
    PUSH   (r13)
    PUSH   (r12)
    mov     r12,r0,SWI_LOG  # default to SI_LOG
    psr     r13,psr         # get PSR into r13
    and     r13,r0,0x10     # mask off SWI bit
    z.mov   r12,r0,HWI_LOG  # if nonzero then point at HI_LOG instead
    ld      r13,r12         # get count
    add     r13,r0,1        # increment count
    sto     r13,r12         # write back
    POP     (r12)           # restore registers
    POP     (r13)
    rti     pc,pc


codestart:
    mov r11,r0,results



    add r0, r0
    mov r1, r0     # Z=1 C=0
    psr r3, psr
    mov r1, r0, 1  # Z=0 C=0
    psr r4, psr
    mov r1, r0, 0x8000
    add r1, r1     # Z=1 C=1
    psr r5, psr
    mov r1, r0, 0x8000
    add r1, r0, 0x8001 #Z=0 C=1
    psr r6, psr

    sto r6, r11
    sto r5, r11,1
    sto r4, r11,2
    sto r3, r11,3

    psr psr,r0  #Clear flags
    psr psr,r6
    psr r7, psr
    psr psr,r5
    psr r8, psr
    psr psr,r4
    psr r9, psr
    psr psr,r3
    psr r10, psr

    sto r7, r11,4
    sto r8, r11,5
    sto r9, r11,6
    sto r0, r11,7


    # Cause a SWI
    psr psr, r0, 0xA0

    halt r0,r0,0x999


results:


ORG 0xFFFE

SWI_LOG:  WORD 0                 # software interrupt count
HWI_LOG:  WORD 0                 # hardware interrupt count
