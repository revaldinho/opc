MACRO   PUSHALL()
        push    r12, r13, -2
        push    r11, r13, -3
        push    r10, r13, -4
        push     r9, r13, -5
        push     r8, r13, -6
        push     r7, r13, -7
        push     r6, r13, -8
        push     r5, r13, -9
ENDMACRO

MACRO   POPALL()
        pop      r5, r13,9
        pop      r6, r13,8
        pop      r7, r13,7
        pop      r8, r13,6
        pop      r9, r13,5
        pop     r10, r13,4
        pop     r11, r13,3
        pop     r12, r13,2
ENDMACRO


        EQU     STKTOP,0x400
        mov     r13, r0, STKTOP

        
        mov     r1,r0,1
        mov     r2,r0,2
        mov     r3,r0,3
        mov     r4,r0,4
        mov     r5,r0,5
        mov     r6,r0,6
        mov     r7,r0,7
        mov     r8,r0,8
        mov     r9,r0,9
        mov     r10,r0,10
        mov     r11,r0,11
        mov     r12,r0,12

        push    r1,r13,-1
        push    r2,r13
        push    r3,r13
        push    r4,r13,-1
        pop     r5,r13
        pop     r6,r13
        pop     r7,r13,1
        pop     r8,r13,1        
        push    r8,r13,-2
        push    r8,r13,-2
        push    r8,r13,-2

        pop     r7,r13,2
        pop     r7,r13,2
        pop     r7,r13,2                



        PUSHALL ()
        mov     r1,r0,0xFF
        mov     r2,r0,0xFF
        mov     r3,r0,0xFF
        mov     r4,r0,0xFF
        mov     r5,r0,0xFF
        mov     r6,r0,0xFF
        mov     r7,r0,0xFF
        mov     r8,r0,0xFF
        mov     r9,r0,0xFF
        mov     r10,r0,0xFF
        mov     r11,r0,0xFF
        POPALL  ()

        
        halt    r0,r0,0x999
