##ifndef _LIB_DISASSEMBLE_S

##define  _LIB_DISASSEMBLE_S

##include "lib_printbstring.s"
##include "lib_printhex.s"

##include "lib_disassemble_common.s"

# --------------------------------------------------------------
#
# disassemble
#
# Disassemble a single instruction
#
# Entry:
# - r1 is the address of the instruction
#
# Exit:
# - r1 is the address of the next instruction
# - all registers preserved

disassemble:

    PUSH   (r13)
    PUSH   (r3)
    PUSH   (r4)
    PUSH   (r5)
    PUSH   (r6)
    PUSH   (r7)

    mov     r5, r1                      # r5 holds the instruction addess

    JSR     (print_hex_word_spc)        # print address
    JSR     (print_delim)               # print ": " delimiter

    ld      r6, r5                      # r6 holds the opcode
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r6
    JSR     (print_hex_word_spc)        # print opcode

    mov     r1, r6
    and     r1, r0, 0x1000              # test the length bit
    z.mov   pc, r0, dis1

    ld      r7, r5                      # r7 holds the operand
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r7
    JSR     (print_hex_word)            # print operand - two words instructions
    mov     pc, r0, dis2

dis1:

    mov     r1, r0, four_spaces
    JSR     (print_bstring)             # print 4 spaces - one word instructions

dis2:
    JSR     (print_spc)                 # print space
    JSR     (print_delim)               # print ": " delimiter

    mov     r2, r6
    and     r2, r0, 0xE000              # extract predicate
    mov     r1, r0, predicates          # find string for predicate

dis3:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis4
    sub     r2, r0, 0x2000
    INC     (r1,0x0002)                 # move on to next predicate
    mov     pc, r0, dis3

dis4:
    JSR     (print_bstring)

    mov     r2, r6
    and     r2, r0, 0x0F00              # extract opcode

    mov     r1, r0, opcodes             # find string for opcode

dis5:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis6
    sub     r2, r0, 0x0100
    INC     (r1, 0x0003)                # move on to next opcode
    mov     pc, r0, dis5

dis6:
    JSR     (print_bstring)
    JSR     (print_spc)                 # print a space

    mov     r1, r0, ord('r')
    JSR     (OSWRCH)
    mov     r1, r6                      # extract destination register
    JSR     (print_reg_num)

    mov     r1, r0, 0x2c
    JSR     (OSWRCH)

    mov     r1, r0, ord('r')
    JSR     (OSWRCH)

    mov     r1, r6                      # extract source register
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    JSR     (print_reg_num)

    mov     r1, r6                      # extract length
    and     r1, r0, 0x1000

    z.mov   pc, r0, dis7

    mov     r1, r0, 0x2c                # print a ,
    JSR     (OSWRCH)

    mov     r1, r0, ord('0')            # print 0x
    JSR     (OSWRCH)
    mov     r1, r0, ord('x')
    JSR     (OSWRCH)

    mov     r1, r7
    JSR     (print_hex_word)            # print the operand

dis7:

    mov     r1, r5                      # return address of next instruction

    POP     (r7)
    POP     (r6)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

predicates:
    # Each predicate must be 2 words, zero terminated
    WORD 0x0000
    WORD 0x0000

    BSTRING "0."
    WORD 0x0000

    BSTRING "z."
    WORD 0x0000

    BSTRING "nz."

    BSTRING "c."
    WORD 0x0000

    BSTRING "nc."

    BSTRING "mi."

    BSTRING "pl."

# --------------------------------------------------------------

opcodes:
    # Each opcode must be 3 words (including 0x00 terminating byte)
    BSTRING "mov"    #  0000
    WORD    0x0000
    BSTRING "and"    #  0001
    WORD    0x0000
    BSTRING "or"     #  0010
    WORD    0x0000, 0x0000
    BSTRING "xor"    #  0011
    WORD    0x0000
    BSTRING "add"    #  0100
    WORD    0x0000
    BSTRING "adc"    #  0101
    WORD    0x0000
    BSTRING "sto"    #  0110
    WORD    0x0000
    BSTRING "ld"     #  0111
    WORD    0x0000, 0x0000
    BSTRING "ror"    #  1000
    WORD    0x0000
    BSTRING "not"    #  1001
    WORD    0x0000
    BSTRING "sub"    #  1010
    WORD    0x0000
    BSTRING "sbc"    #  1011
    WORD    0x0000
    BSTRING "cmp"    #  1100
    WORD    0x0000
    BSTRING "cmpc"   #  1101
    WORD    0x0000
    BSTRING "bswp"   #  1110
    WORD    0x0000
    BSTRING "psr"    #  1111
    WORD    0x0000

##endif
