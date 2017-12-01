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
    PUSH   (r2)
    PUSH   (r3)
    PUSH   (r4)
    PUSH   (r5)
    PUSH   (r6)

    mov     r5, r1                      # r5 holds the instruction addess

    JSR     (print_hex_word_spc)        # print address
    JSR     (print_delim)               # print ": " delimiter

    ld      r6, r5                      # r6 holds the instruction
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r6
    JSR     (print_hex_word_spc)        # print opcode
    JSR     (print_delim)               # print ": " delimiter

    mov     r2, r6
    rol     r2, r2                      # shift the predicate into bits 2..0
    rol     r2, r2
    rol     r2, r2
    rol     r2, r2
    and     r2, r0, 0x07                # extract predicate
    mov     r1, r2, predicates          # find string for predicate
    JSR     (print_bstring)

    bperm   r2, r6, 0x2103
    and     r2, r0, 0x1F                # extract opcode        
    add     r2, r2                      # two words per opcode
    mov     r1, r2, opcodes             # find string for opcode
    JSR     (print_bstring)
    JSR     (print_spc)                 # print a space

    mov     r1, r0, ord('r')
    JSR     (OSWRCH)

    bperm   r1, r6, 0x1032              # extract destination register
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    JSR     (print_reg_num)

    bperm   r1, r6, 0x1032              # test for long instructions
    and     r1, r0, 0x1C00
    cmp     r1, r0, 0x1C00
    z.mov   pc, r0, dis_imm20

dis_imm16:
    mov     r1, r0, 0x2c                # print ,r
    JSR     (OSWRCH)
    mov     r1, r0, ord('r')
    JSR     (OSWRCH)

    bperm   r1, r6, 0x1032            # extract source register
    JSR     (print_reg_num)

    mov     r1, r0, 0xffffffff          # r1 = constant mask for imm16
    movt    r1, r0
    mov     r2, r0, 0xffff8000          # r2 = sign bit for imm16
    movt    r2, r0
    mov     r3, r6                      # extract the constant
    and     r3, r1
    z.mov   pc, r0, dis7                # supress printing of zero constants for imm16

    mov     pc, r0, dis_imm_se

dis_imm20:
    mov     r1, r0, 0xffffffff          # r1 = constant mask for imm20
    movt    r1, r0, 0x000f
    mov     r2, r0                      # r2 = sign bit for imm20
    movt    r2, r0, 0x0008
    mov     r3, r6                      # extract the constant
    and     r3, r1

dis_imm_se:
    xor     r1, r0, 0xffffffff          # invert to give signed extension mask
    and     r2, r3                      # test the sign bit
    nz.or   r3, r1                      # if negative, then sign extend

    mov     r1, r0, 0x2c                # print ,0x
    JSR     (OSWRCH)
    mov     r1, r0, ord('0')
    JSR     (OSWRCH)
    mov     r1, r0, ord('x')
    JSR     (OSWRCH)

    mov     r1, r3
    JSR     (print_hex_word)            # print the immediate value

dis7:

    mov     r1, r5                      # return address of next instruction

    POP     (r6)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    POP     (r2)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

predicates:
    # Each predicate must be 1 word, zero terminated
    WORD 0x0000
    WORD 0x0000
    BSTRING "z."
    BSTRING "nz."
    BSTRING "c."
    BSTRING "nc."
    BSTRING "mi."
    BSTRING "pl."

# --------------------------------------------------------------

opcodes:
    # Each opcode must be 2 words (including 0x00 terminating byte)
    BSTRING "mov"    #  00000
    WORD    0x0000
    BSTRING "movt"   #  00001
    WORD    0x0000
    BSTRING "xor"    #  00010
    WORD    0x0000
    BSTRING "and"    #  00011
    WORD    0x0000
    BSTRING "or"     #  00100
    WORD    0x0000
    BSTRING "not"    #  00101
    WORD    0x0000
    BSTRING "cmp"    #  00110
    WORD    0x0000
    BSTRING "sub"    #  00111
    WORD    0x0000
    BSTRING "add"    #  01000
    WORD    0x0000
    BSTRING "bperm"   #  01001
    # WORD    0x0000
    BSTRING "ror"    #  01010
    WORD    0x0000
    BSTRING "lsr"    #  01011
    WORD    0x0000
    BSTRING "jsr"    #  01100
    WORD    0x0000
    BSTRING "asr"    #  01101
    WORD    0x0000
    BSTRING "rol"    #  01110
    WORD    0x0000
    BSTRING "---"    #  01111
    WORD    0x0000
    BSTRING "halt"   #  10000
    WORD    0x0000
    BSTRING "rti"    #  10001
    WORD    0x0000
    BSTRING "putp"   #  10010
    WORD    0x0000
    BSTRING "getp"   #  10011
    WORD    0x0000
    BSTRING "---"    #  10100
    WORD    0x0000
    BSTRING "---"    #  10101
    WORD    0x0000
    BSTRING "---"    #  10110
    WORD    0x0000
    BSTRING "---"    #  10111
    WORD    0x0000
    BSTRING "out"    #  11000
    WORD    0x0000
    BSTRING "in"     #  11001
    WORD    0x0000
    BSTRING "sto"    #  11010
    WORD    0x0000
    BSTRING "ld"     #  11011
    WORD    0x0000
    BSTRING "ljsr"   #  11100
    WORD    0x0000
    BSTRING "lmov"   #  11101
    WORD    0x0000
    BSTRING "lsto"   #  11110
    WORD    0x0000
    BSTRING "lld"    #  11111
    WORD    0x0000

##endif
