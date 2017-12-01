        ld   r4, r0, string

        bperm r1,r4, 0x3210
        ljsr  r13,oswrch
        bperm r1,r4, 0x0123
        ljsr  r13,oswrch
        bperm r1,r4, 0x0011
        ljsr  r13,oswrch
        bperm r1,r4, 0x7777
        ljsr  r13,oswrch        
        halt  r0,r0,0x123
        
string: BSTRING "ABCD"
        
        ORG 0x00EE
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

