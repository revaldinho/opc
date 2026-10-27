        # scmp.s - test of scmp, the signed compare: it subtracts like cmp, discards
        # the result and sets S to N xor V, so mi. means 'less than' (signed).
        #
        # For every pair (a, b) of the values in the table it prints '<' if scmp
        # says a < b and '.' if not, one row per a. As a check it also compares a
        # and b with their sign bits flipped, unsigned (cmp; nc. means less), and
        # prints 'X' instead if the two disagree. Last it prints 'K' if scmp left
        # its two registers unchanged ('X' if not). Expected output:
        #
        #   .<.<.<..<<<.
        #   ...<.<..<<<.
        #   <<.<.<..<<<.
        #   .....<..<<<.
        #   <<<<.<..<<<.
        #   ............
        #   <<<<<<.<<<<<
        #   <<<<<<..<<<<
        #   .....<...<<.
        #   .....<....<.
        #   .....<......
        #   <<<<<<..<<<.
        #   K

        EQU     NVALS, 12

        mov     r9, r0, 0               # r9 = 0x80000000, to flip sign bits
        movt    r9, r0, -32768
        mov     r10, r0, 0              # i: index of a
rowloop:
        ld      r7, r10, values         # a
        mov     r11, r0, 0              # j: index of b
colloop:
        ld      r8, r11, values         # b
        mov     r1, r0, 46              # '.'
        scmp    r7, r8
        mi.mov  r1, r0, 60              # '<' if a < b
        mov     r3, r7                  # reference: (a ^ minint) < (b ^ minint) unsigned
        xor     r3, r9
        mov     r4, r8
        xor     r4, r9
        mov     r5, r0, 46
        cmp     r3, r4
        nc.mov  r5, r0, 60
        cmp     r1, r5
        nz.mov  r1, r0, 88              # 'X' if they disagree
        ljsr    r13, oswrch
        add     r11, r0, 1
        cmp     r11, r0, NVALS
        nz.mov  pc, r0, colloop
        mov     r1, r0, 10              # newline
        ljsr    r13, oswrch
        add     r10, r0, 1
        cmp     r10, r0, NVALS
        nz.mov  pc, r0, rowloop

        ld      r3, r0, values+NVALS-1  # the last pair compared was (last, last)
        mov     r1, r0, 75              # 'K'
        cmp     r7, r3
        nz.mov  r1, r0, 88
        cmp     r8, r3
        nz.mov  r1, r0, 88
        ljsr    r13, oswrch
        mov     r1, r0, 10
        ljsr    r13, oswrch
        halt    r0, r0, 0x999

values: WORD    0
        WORD    1
        WORD    -1
        WORD    2
        WORD    -2
        WORD    0x7FFFFFFF              # maxint
        WORD    0x80000000              # minint
        WORD    0x80000001
        WORD    3
        WORD    5
        WORD    0x40000000
        WORD    0xBFFFFFFF

        # --------------------------------------------------------------
        #
        # oswrch
        #
        # Output a single ascii character to the uart
        #
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporary
        # ---------------------------------------------------------------
oswrch:
oswrch_loop:
        in      r2, r0, 0xfe08
        asr     r2, r2
        and     r2, r0, 0x4000
        nz.sub  pc,r0, PC-oswrch_loop
        and     r1,r0,0x00FF
        out     r1, r0, 0xfe09
        mov     pc,r13
