        mov     r10, r0, S1
        mov     r11, r0, results
        mov     r13, r0, p1
        mov     pc,r0,printbstr
p1:     mov     r10, r0, S2
        mov     r13, r0, p2
        mov     pc,r0,printbstr
p2:     mov     r10, r0, S3
        mov     r11, r0, results
        mov     r13, r0, p3
        mov     pc,r0,printwstr
p3:     mov     r10, r0, S4
        mov     r13, r0, DONE
        mov     pc,r0,printwstr

DONE:
        halt r0,r0,0x999

printbstr:  ld      r1,r10
        mov     r2,r1
        and     r2,r0,0xFF
        z.mov   pc, r0, ret
        sto     r2,r0,0xfe09
        sto     r2, r11
        add     r11,r0,1
        bswp    r2,r1
        and     r2,r0,0xFF
        z.mov   pc, r0, ret
        sto     r2,r0,0xfe09
        sto     r2, r11
        add     r11,r0,1
        add     r10,r0,1
        mov     pc,r0,printbstr
ret:
        mov     pc,r13,0

printwstr:  ld      r1,r10
        mov     r2,r1
        and     r2,r0,0xFF
        z.mov   pc, r0, wret
        sto     r2,r0,0xfe09
        sto     r2, r11
        add     r11,r0,1
        add     r10,r0,1
        mov     pc,r0,printwstr
wret:
        mov     pc,r13,0


S1:     BSTRING "Hello - this is a byte string"
        WORD 0x0
S2:     BSTRING "...and so is this"
        WORD 0x0
        # Check alignment on next few
        BSTRING "1"
        BSTRING "12"
        BSTRING "123"
        BSTRING "1234"

S3:     STRING "This is a word string"
        WORD 0x0
S4:     STRING "...and so is this"
        # Check alignment on next few
        WORD 0x0
        STRING "1"
        STRING "12"
        STRING "123"
        STRING "1234"



results:
