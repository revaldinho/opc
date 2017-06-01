# Simple test Program ported directly from OPC3
TOP:    ORG     0x0000

        ld.i    r10, r0, RESULT             # Write all results here for comparing memdump later
        ld.i    r9, r0, DATA-1
        ld.i    r13, r0, CONT1
CONT1:  add.i   r9, r0, 1
        ld      r8, r9
        nz.ld.i   pc,r0,RORTEST

        ld.i    r9, r0, DATA-1
        ld.i    r13, r0, CONT2
CONT2:  add.i   r9, r0, 1
        ld      r8, r9
        nz.ld.i   pc,r0,XORTEST

        0.ld.i    r5,r0           # 3 cycle nop
        0.ld.i    r5,r1,0x0000    # 4 cycle nop
        0.ld      r5,r1,0x0000    # 5 cycle nop

        ld.i    r9, r0, DATA-1
        ld.i    r13, r0, CONT3
CONT3:  add.i   r9, r0, 1
        ld      r8, r9
        nz.ld.i   pc,r0,ADDTEST
        halt    r0,r0,0x999


RORTEST: ror.i r8, r8, 0
        ror.i r8, r8, 0
        ror.i r8, r8, 0
        ror.i r8, r8, 0
        ror.i r8, r8, 0
        ror.i r8, r8, 0
        ror.i r8, r8, 0
        sto r8, r10, 0
        add.i r10, r0, 1
        ld.i  pc, r13

XORTEST: xor.i r8, r8, 1
        xor.i r8, r8, 2
        xor.i r8, r8, 3
        xor.i r8, r8, 4
        xor.i r8, r8, 5
        xor.i r8, r8, 6
        xor.i r8, r8, 7
        sto r8, r10, 0
        add.i r10, r0, 1
        ld.i  pc, r13

ADDTEST: ld  r1, r9
         ld  r2, r9, 1
         add.i r1, r2
         ld  r2, r9, 2
         adc.i r1, r2
         ld  r2, r9, 3
         adc.i r1, r2

         sto r1, r10, 0
         add.i r10, r0, 1
         ld.i  pc, r13


SUB1:   ld.i  r2,r0,0xFFFF
SUBLP:  add.i r2,r0,0x01
        c.ld.i r15,r0,SUBEXT
        ld.i  r15,r0,SUBLP
SUBEXT: ld.i  pc,r14,0     # retrieve return address and return!
        ORG 0x100
DATA:
        WORD 0x3333
        WORD 0x5555
        WORD 0x1111
        WORD 0xABCD
        WORD 0x9999
        WORD 0x0000
        WORD 0x1234 #additional words for ADC
        WORD 0x4567
        WORD 0x0F0F

RESULT:

DATAEND:
