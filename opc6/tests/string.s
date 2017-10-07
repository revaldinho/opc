
        



        mov     r10, r0, S1
        mov     r11, r0, results
        mov     r13, r0, p1
        mov     pc,r0,printbstr
p1:     mov     r10, r0, S2
        mov     r13, r0, p2
        mov     pc,r0,printbstr
p2:     mov     r10, r0, S3
DONE:
        halt r0,r0,0x999

printbstr:  ld      r1,r10
        mov     r2,r1
        and     r2,r0,0xFF
        z.mov   pc, r0, ret
        out     r2,r0,0xfe09
        sto     r2, r11
        add     r11,r0,1
        bswp    r2,r1
        and     r2,r0,0xFF
        z.mov   pc, r0, ret
        out     r2,r0,0xfe09
        sto     r2, r11
        add     r11,r0,1
        add     r10,r0,1
        mov     pc,r0,printbstr
ret:
        mov     pc,r13,0

S1:     BSTRING "Hello - this is a byte string"
        WORD 0x0
S2:     BSTRING "...and so is this\n"
        WORD 0x0
        # Check alignment on next few
        BSTRING "1"
        BSTRING "12"
        BSTRING "123"
        BSTRING "1234"

S3:     STRING "This is a word string\r"
        WORD 0x0
S4:     STRING "...and so is \tthis"
        # Check alignment on next few
        WORD 0x0
        STRING "1"
        STRING "12"
        STRING "123"
        STRING "1234"
        STRING "1234 , 5678", "io"
        STRING "1234 , 5678\010\013"
        STRING "1","2","3","4"        
        ORG 0x1234
L0:
        BYTE 0xAA
L1:     
        BYTE 0x11, 0x22
L2:     
        BYTE 0x33, 0x44, 0x55
L3:
        BYTE 0x66, 0x77, 0x88, 0x99
L4:
        BYTE int(3.14 * 10),0x00, L0&0xff,(L0>>8)&0xFF
        PBSTRING "Pascal string prepended"
        PBSTRING "with length"
        PBSTRING "byte"
        PBSTRING "1","2","3"


results:
