##ifndef _LIB_PRINTDEC_S

##define _LIB_PRONTDEC_S

# --------------------------------------------------------------
#
# print_dec_16
#
# Prints a 16-bit value as decimal
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved


# digit = 0
#          if (a >= 40000) a = a - 40000; digit = digit + 4
# a = a*2; if (a >= 40000) a = a - 40000; digit = digit + 2
# a = a*2; if (a >= 40000) a = a - 40000; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 32000) a = a - 32000; digit = digit + 8
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 4
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 2
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 25600) a = a - 25600; digit = digit + 8
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 4
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 2
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 20480) a = a - 20480; digit = digit + 8
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 4
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 2
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 16384) a = a - 16384; digit = digit + 8
# a = a*2; if (a >= 16384) a = a - 16384; digit = digit + 4
# a = a*2; if (a >= 16484) a = a - 16384; digit = digit + 2
# a = a*2; if (a >= 16384) a = a - 16384; digit = digit + 1
# output character (digit ^ $30)

# Based on
# http://6502org.wikidot.com/software-output-decimal

print_dec_16:
    PUSH    (r13)
    PUSH    (r1)
    PUSH    (r2)
    PUSH    (r3)
    PUSH    (r4)

    mov     r2, r1
    mov     r3, r0, 4
    mov     r1, r0, 0x2006

print_dec_16_1:
    ld      r4, r3, print_dec_table
    CLC     ()
    ror     r2, r2

print_dec_16_2:
    ROL     (r2, r2)
    c.mov   pc, r0, print_dec_16_3
    cmp     r2, r4
    nc.mov  pc, r0, print_dec_16_4

print_dec_16_3:
    sub     r2, r4
    SEC     ()

print_dec_16_4:
    ROL     (r1, r1)
    nc.mov  pc, r0, print_dec_16_2

    JSR     (OSWRCH)

    mov     r1, r0, 0x1003
    sub     r3, r0, 1
    pl.mov  pc, r0, print_dec_16_1

    POP     (r4)
    POP     (r3)
    POP     (r2)
    POP     (r1)
    POP     (r13)
    RTS     ()

print_dec_table:
    WORD        8 * (2**11)
    WORD       80 * (2** 8)
    WORD      800 * (2** 5)
    WORD     8000 * (2** 2)
    WORD    40000 * (2** 0)

# print_dec_16_:
#     PUSH    (r13)
#     PUSH    (r1)
#     PUSH    (r2)
#     PUSH    (r3)
#     PUSH    (r4)
#
#     mov     r2, r1
#     mov     r3, r0, DecTable - 1
#
# print_dec_16_1:
#     add     r3, r0, 1
#     ld      r4, r3
#     z.mov   pc, r0, print_dec_16_4
#
#     mov     r1, r0, 0x30
# print_dec_16_2:
#     cmp     r2, r4
#     nc.mov  pc, r0, print_dec_16_3
#     add     r1, r0, 1
#     sub     r2, r4
#     mov     pc, r0, print_dec_16_2
#
# print_dec_16_3:
#     JSR     (OSWRCH)
#     mov     pc, r0, print_dec_16_1
#
# print_dec_16_4:
#     POP     (r4)
#     POP     (r3)
#     POP     (r2)
#     POP     (r1)
#     POP     (r13)
#     RTS     ()
#
# DecTable:
#     WORD    10000, 1000, 100, 10, 1, 0

##endif
