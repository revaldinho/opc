##ifndef _LIB_PRINTDEC_S

##define _LIB_PRINTDEC_S

# --------------------------------------------------------------
#
# print_dec_word
#
# Prints a word sized value as decimal
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved


print_dec_word:
    PUSH    (r13)
    PUSH    (r1)
    PUSH    (r2)
    PUSH    (r3)
    PUSH    (r4)
    PUSH    (r5)

    mov     r5, r0                     # flag to manage supressing of leading zeros
    mov     r2, r1
    mov     r3, r0, DecTable - 1

print_dec_word_1:
    add     r3, r0, 1
    ld      r4, r3
    z.mov   pc, r0, print_dec_word_5

    mov     r1, r0
print_dec_word_2:
    cmp     r2, r4
    nc.mov  pc, r0, print_dec_word_3
    add     r1, r0, 1
    sub     r2, r4
    mov     pc, r0, print_dec_word_2

print_dec_word_3:
    cmp     r4, r0, 1                  # force printing of the last digit
    z.mov   pc, r0, print_dec_word_4
    add     r5, r1                     # supress leading zeros
    z.mov   pc, r0, print_dec_word_1

print_dec_word_4:
    add     r1, r0, 0x30
    JSR     (OSWRCH)
    mov     pc, r0, print_dec_word_1

print_dec_word_5:
    POP     (r5)
    POP     (r4)
    POP     (r3)
    POP     (r2)
    POP     (r1)
    POP     (r13)
    RTS     ()

DecTable:
##ifdef CPU_OPC7
    WORD    1000000000
    WORD     100000000
    WORD      10000000
    WORD       1000000
    WORD        100000
##endif
    WORD         10000
    WORD          1000
    WORD           100
    WORD            10
    WORD             1
    WORD             0

##endif
