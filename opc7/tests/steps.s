        # steps.s - test of mulstep and divstep (added 13/11/2026), the one-bit steps of a
        # software multiply and divide:
        #   mulstep rd, rs, imm   rd := rd<<1 + (C ? rs+imm : 0); C (and V) kept
        #   divstep rd, rs, imm   t := rd<<1 | C (33 bits); if t >= rs+imm (unsigned)
        #                         then rd := t - (rs+imm), C := 1 else rd := t, C := 0
        # Both set Z and S from rd.
        #
        # For every pair (a, b) of the values in the table it prints one character:
        #   - the product a*b (low 32 bits) by 32 x (add m,m; mulstep p,b), the multiplier
        #     bits shifted out of m into C, top first, is compared with a reference shift and
        #     add (lsr, c.add, add: no step instructions): 'M' if they differ
        #   - for b != 0, the unsigned quotient q and remainder r of a/b by 32 x (rol n,n;
        #     divstep r,b), the dividend bits shifted out of n into C and the quotient bits
        #     in, must have r < b and q*b + r = a (q*b by the reference multiply): 'D' if not
        #   - '.' if both are right
        # one row per a. Last it checks the flags in a few cases and prints 'K' ('F' if not).
        # Expected output:
        #
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   ..........
        #   K

        EQU     NVALS, 10

        mov     r10, r0, 0              # i: index of a
rowloop:
        mov     r11, r0, 0              # j: index of b
colloop:
        ld      r7, r10, values         # a
        ld      r8, r11, values         # b
        mov     r12, r0, 46             # '.'

        # product by mulstep: m = a in r3, p in r1
        mov     r3, r7
        mov     r1, r0
        mov     r4, r0, 32
mloop:  add     r3, r3                  # next multiplier bit, top first, to C
        mulstep r1, r8                  # p := 2p + (C ? b : 0)
        sub     r4, r0, 1
        nz.mov  pc, r0, mloop
        # reference product of a and b in r5 (r2, r6 used)
        mov     r2, r7
        mov     r6, r8
        ljsr    r13, refmul
        cmp     r1, r5
        nz.mov  r12, r0, 77             # 'M'

        # quotient and remainder by divstep: n = a in r1 (becomes q), r in r3
        cmp     r8, r0
        z.mov   pc, r0, nodiv
        mov     r1, r7
        mov     r3, r0
        add     r0, r0                  # C := 0 for the first rol
        mov     r4, r0, 32
dloop:  rol     r1, r1                  # quotient bit in from C, next dividend bit out to C
        divstep r3, r8                  # r := 2r + C, less b if that is >= b; C := the quotient bit
        mov     r4, r4, -1              # mov keeps C
        nz.mov  pc, r0, dloop
        rol     r1, r1                  # the last quotient bit
        cmp     r3, r8                  # r < b (unsigned): C clear
        c.mov   r12, r0, 68             # 'D'
        mov     r2, r1                  # q*b + r = a
        mov     r6, r8
        ljsr    r13, refmul
        add     r5, r3
        cmp     r5, r7
        nz.mov  r12, r0, 68
nodiv:
        mov     r1, r12
        ljsr    r13, oswrch
        add     r11, r0, 1
        cmp     r11, r0, NVALS
        nz.mov  pc, r0, colloop
        mov     r1, r0, 10              # newline
        ljsr    r13, oswrch
        add     r10, r0, 1
        cmp     r10, r0, NVALS
        nz.mov  pc, r0, rowloop

        # flags: r12 := 'K', 'F' if any check fails
        mov     r12, r0, 75
        mov     r1, r0, 0
        cmp     r0, r0                  # C := 1 (and Z := 1)
        mulstep r1, r0                  # 0: Z set, C kept
        nz.mov  r12, r0, 70
        nc.mov  r12, r0, 70
        mov     r1, r0, 1
        movt    r1, r0, 0x4000          # 0x40000001
        add     r0, r0                  # C := 0
        mulstep r1, r0, 5               # 0x80000002: S set, Z clear, C kept clear (op not added)
        pl.mov  r12, r0, 70
        z.mov   r12, r0, 70
        c.mov   r12, r0, 70
        mov     r2, r0, 2
        movt    r2, r0, 0x8000
        cmp     r1, r2
        nz.mov  r12, r0, 70
        mov     r1, r0, 3
        cmp     r0, r0                  # C := 1: t = 7
        divstep r1, r0, 7               # 7 >= 7: r1 := 0, C := 1, Z set
        nc.mov  r12, r0, 70
        nz.mov  r12, r0, 70
        mov     r1, r0, 3
        add     r0, r0                  # C := 0: t = 6
        divstep r1, r0, 7               # 6 < 7: r1 := 6, C := 0, Z clear
        c.mov   r12, r0, 70
        z.mov   r12, r0, 70
        cmp     r1, r0, 6
        nz.mov  r12, r0, 70
        mov     r1, r0, -1              # 0xFFFFFFFF: t = 0x1FFFFFFFE (33 bits) >= 0xFFFFFFFF
        add     r0, r0
        mov     r2, r0, -1
        divstep r1, r2                  # r1 := 0xFFFFFFFF, C := 1, S set
        nc.mov  r12, r0, 70
        pl.mov  r12, r0, 70
        cmp     r1, r2
        nz.mov  r12, r0, 70
        mov     r1, r12
        ljsr    r13, oswrch
        mov     r1, r0, 10
        ljsr    r13, oswrch
        halt    r0, r0, 0x999

        # refmul: r5 := r2 * r6 (low 32 bits), shift and add with no step instructions;
        # r2, r6 used
refmul: mov     r5, r0
rmloop: lsr     r2, r2                  # next multiplier bit, bottom first, to C
        c.add   r5, r6
        add     r6, r6
        cmp     r2, r0
        nz.mov  pc, r0, rmloop
        mov     pc, r13

values: WORD    0
        WORD    1
        WORD    3
        WORD    10
        WORD    100
        WORD    0x7FFF
        WORD    0x12345678
        WORD    0x7FFFFFFF              # maxint
        WORD    0x80000000              # minint
        WORD    0xFFFFFFFF              # -1

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
