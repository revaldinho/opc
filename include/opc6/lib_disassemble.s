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

    mov     r1, r6
    and     r1, r0, 0xE000
    cmp     r1, r0, 0x2000
    z.add   r2, r0, 0x1000
    PUSH    (r2)                        # save the opcode so we can later test for inc/dec

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

    POP     (r2)                        # restore the opcode (bits 12..8)
    and     r2, r0, 0x1D00              # inc = 0x0C00, dec = 0x0E00
    cmp     r2, r0, 0x0C00              # both now map to 0x0C00
    nz.jsr  r13, r0, OSWRCH             # if not inc/dec, src is a register

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

    WORD 0x0000
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
    BSTRING "mov"    #  00000
    WORD    0x0000
    BSTRING "and"    #  00001
    WORD    0x0000
    BSTRING "or"     #  00010
    WORD    0x0000, 0x0000
    BSTRING "xor"    #  00011
    WORD    0x0000
    BSTRING "add"    #  00100
    WORD    0x0000
    BSTRING "adc"    #  00101
    WORD    0x0000
    BSTRING "sto"    #  00110
    WORD    0x0000
    BSTRING "ld"     #  00111
    WORD    0x0000, 0x0000
    BSTRING "ror"    #  01000
    WORD    0x0000
    BSTRING "jsr"    #  01001
    WORD    0x0000
    BSTRING "sub"    #  01010
    WORD    0x0000
    BSTRING "sbc"    #  01011
    WORD    0x0000
    BSTRING "inc"    #  01100
    WORD    0x0000
    BSTRING "lsr"    #  01101
    WORD    0x0000
    BSTRING "dec"    #  01110
    WORD    0x0000
    BSTRING "asr"    #  01111
    WORD    0x0000
    BSTRING "halt"   #  10000
    WORD    0x0000
    BSTRING "bswp"   #  10001
    WORD    0x0000
    BSTRING "putp"   #  10010
    WORD    0x0000
    BSTRING "getp"   #  10011
    WORD    0x0000
    BSTRING "rti"    #  10100
    WORD    0x0000
    BSTRING "not"    #  10101
    WORD    0x0000
    BSTRING "out"    #  10110
    WORD    0x0000
    BSTRING "in"     #  10111
    WORD    0x0000, 0x0000
    BSTRING "push"   #  11000
    WORD    0x0000
    BSTRING "pop"    #  11001
    WORD    0x0000
    BSTRING "cmp"    #  11010
    WORD    0x0000
    BSTRING "cmpc"   #  11011
    WORD    0x0000
    BSTRING "----"   #  11100
    WORD    0x0000
    BSTRING "----"   #  11101
    WORD    0x0000
    BSTRING "----"   #  11110
    WORD    0x0000
    BSTRING "----"   #  11111
    WORD    0x0000

##endif
