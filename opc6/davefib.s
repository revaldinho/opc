
        ORG 0x0000

fib:
        mov     r4, r0, results
        mov     r5, r0, fibEnd
        mov     r6, r0, fibLoop
        mov     r10, r0, 1

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
        halt    r0, r0, 0x999

        ORG 0x100
results:
