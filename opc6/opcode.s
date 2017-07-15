
        rti     pc,pc
        bswp    r1,r2
        getpsr  r1,psr
        putpsr  psr,r2
        in      r1,r2,0
        out     r3,r4,22
        jsr     r13,r0,0x44
        mov     r1,r2,66
