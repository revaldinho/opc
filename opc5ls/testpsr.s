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

    halt r0,r0,0x999


results:
