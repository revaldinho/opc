##ifndef _LIB_PRINTHEX_S

##define _LIB_PRINTHEX_S

# --------------------------------------------------------------
#
# print_hex_word
#
# Prints a word-sized hex value
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_hex_word:

    PUSH    (r13)
    PUSH    (r1)            # preserve working registers
    PUSH    (r2)
    PUSH    (r3)

    mov     r2, r1          # r2 is now the value to be printed

    mov     r3, r0, (WORD_SIZE >> 2) # r3 is a loop counter for digits

print_hex_word_loop:
    add     r2, r2          # shift the upper nibble of r2
    ROL     (r1, r1)        # into the lower nibble of r1
    add     r2, r2          # one bit at a time
    ROL     (r1, r1)
    add     r2, r2          # add   rd, rd is the same as ASL
    ROL     (r1, r1)        # adc   rd, rd is the same as ROL
    add     r2, r2
    ROL     (r1, r1)

    JSR     (print_hex_1)

    sub     r3, r0, 1       # decrement the loop counter and loop back for next digits
    nz.mov  pc, r0, print_hex_word_loop

    POP     (r3)            # restore working registers
    POP     (r2)
    POP     (r1)
    POP     (r13)

    RTS     ()

# --------------------------------------------------------------
#
# print_hex_1
#
# Prints a 1-digit hex value
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_hex_1:
    and     r1, r0, 0x0F    # mask off everything but the bottom nibble
    cmp     r1, r0, 0x0A    # set the carry if r1 >= 0x0A
    c.add   r1, r0, 0x27    # 'a' - '9' + 1
    add     r1, r0, 0x30    # '0'
    mov     pc, r0, OSWRCH  # output R1

# --------------------------------------------------------------
#
# print_hex_word_spc
#
# Prints a 4-digit hex value followed by a space
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_hex_word_spc:
    PUSH    (r13)
    JSR     (print_hex_word)
    JSR     (print_spc)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# print_spc
#
# Prints a space
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_spc:
    PUSH    (r13)
    PUSH    (r1)
    mov     r1, r0, 0x20
    JSR     (OSWRCH)
    POP     (r1)
    POP     (r13)
    RTS     ()

##endif
