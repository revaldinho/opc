# Simple test Program ported directly from OPC3
TOP:    ORG     0x0000
        ld.i    r1,r0,0x00
        sto     r1,r0,RESULT                 # Comments ignored but preserved in listing
        and.i  r1,r1,0x00                   # invert r1
        sto     r1,r0,RESULT+1
        ld.i    r1,r0, (10*2+9) << 7 & 0xFF  # Demo of Python expression parsing
        ld.i    r1,r0,-10
LOOP:   add.i   r1,r0,0x01
        nz.ld.i r15,r0,LOOP                  # r15 is PC
NEXT:   or.i  r1,r0,0x33
        xor.i  r1,r1,0
        ld.i    r1, r0,0x1234
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00
        ror.i   r1,r1,0x00


        ld.i    r15,r0,END


END:    ld.i    r14,pc,2   # get return address in r14
        ld.i    pc,r0,SUB1
        halt    r0,r0,0x999

SUB1:   ld.i  r2,r0,0xFFFF
SUBLP:  add.i r2,r0,0x01
        c.ld.i r15,r0,SUBEXT
        ld.i  r15,r0,SUBLP
SUBEXT: ld.i  pc,r14,0     # retrieve return address and return!

DATA:   ORG 0x40


MEM1:   WORD 0x00
MEM2:   WORD 0x00

RESULT: WORD  0x00
        WORD 1,2,3
        WORD 5,6,7,8
        WORD 555
        WORD 0x0123
        WORD 0o4567

DATAEND:
