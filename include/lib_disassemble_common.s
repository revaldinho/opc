##ifndef _LIB_DISASSEMBLE_COMMON_S

##define  _LIB_DISASSEMBLE_COMMON_S

# --------------------------------------------------------------
#
# print_reg_num
#
# Prints a register number 0..15
#
# Entry:
# - r1 is the register number
#
# Exit:
# - r1 is corrupted, all other registers preserved

print_reg_num:
    PUSH    (r13)
    and     r1, r0, 0x0F

    cmp     r1, r0, 0x0A
    nc.mov  pc, r0, print_reg_num_1

    PUSH    (r1)
    mov     r1, r0, 0x31
    JSR     (OSWRCH)
    POP     (r1)

    DEC     (r1,0x0A)

print_reg_num_1:
    add     r1, r0, 0x30
    JSR     (OSWRCH)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# print_delim
#
# Prints a <space>:<space> delimeter
#
# Entry:
#
# Exit:
# - all registers preserved

print_delim:
     PUSH   (r13)
     PUSH   (r1)
     mov    r1, r0, 0x3a
     JSR    (OSWRCH)
     mov    r1, r0, 0x20
     JSR    (OSWRCH)
     POP    (r1)
     POP    (r13)
     RTS    ()

# --------------------------------------------------------------

four_spaces:
    BSTRING "    "
    WORD    0x0000

##endif
