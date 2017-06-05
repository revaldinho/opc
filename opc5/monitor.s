# A loose port of C'mon, the Compact monitor, by Bruce Clark, from
# the 65org16 to the opc5.
#
# see: http://biged.github.io/6502-website-archives/lowkey.comuf.com/cmon.htm
#
# (c) 2017 David Banks

MACRO JSR( _address_)
   ld.i     r13, pc, 0x0005
   sto      r13, r14
   ld.i     r14, r14, 0xffff
   ld.i     pc,  r0, _address_
ENDMACRO

MACRO RTS()
    ld.i    r14, r14, 0x0001
    ld      pc, r14
ENDMACRO

MACRO   PUSH( _data_)
    sto     _data_, r14
    ld.i    r14, r14, 0xffff
ENDMACRO

MACRO   POP( _data_ )
    ld.i    r14, r14, 0x0001
    ld      _data_, r14
ENDMACRO

ORG 0x0000

monitor:
    ld.i    pc, r0, m0

welcome:
    WORD    0x0a,0x0d,0x4f,0x50,0x43,0x35,0x20,0x4d
    WORD    0x6f,0x6e,0x69,0x74,0x6f,0x72,0x0a,0x0d
    WORD    0x00

m0:
    ld.i    r14, r0, 0x07ff

    ld.i    r1, r0, welcome
    JSR     (print_string)

m1:
    JSR     (osnewl)
    ld.i    r1, r0, 0x2D
    JSR     (oswrch)

m2:
    ld.i    r5, r0          # r5 == NUMBER
    ld.i    r1, r0

m3:
    and.i   r1, r0, 0x0F

m4:
    add.i   r5, r5          # accumulate digit
    add.i   r5, r5
    add.i   r5, r5
    add.i   r5, r5
    or.i    r5, r1

m6:
    JSR     (osrdch)

    ld.i    r2, r1
    add.i   r2, r0, -0x0D
    z.ld.i  pc, r0, m1

#
# Insert additional commands for characters (e.g. control characters)
# outside the range $20 (space) to $7E (tilde) here
#

    ld.i    r2, r1          # don't output if < 0x20
    add.i   r2, r0, -0x20
    nc.ld.i pc, r0, m6

    ld.i    r2, r1          # don't output if >= 07F
    add.i   r2, r0, -0x7F
    c.ld.i  pc, r0, m6

    JSR     (oswrch)

    ld.i    r2, r1
    add.i   r2, r0, -0x2c
    z.ld.i  pc, r0, comma

    ld.i    r2, r1
    add.i   r2, r0, -0x40
    z.ld.i  pc, r0, at

#
# Insert additional commands for non-letter characters (or case-sensitive
# letters) here
#
    xor.i   r1, r0, 0x30


    ld.i    r2, r1
    add.i   r2, r0, -0x0A
    nc.ld.i pc, r0, m4
    or.i    r1, r0, 0x20
    add.i   r1, r0, -0x77
#
# mapping:
#   A-F -> $FFFA-$FFFF
#   G-O -> $0000-$0008
#   P-Z -> $FFE9-$FFF3
#

    z.ld.i  pc, r0, go

    ld.i    r2, r1
    add.i   r2, r0, -0xfffa
    c.ld.i  pc, r0, m3

#
# Insert additional commands for (case-insensitive) letters here
#

    ld.i    r2, r1
    add.i   r2, r0, -0xfff3
    z.ld.i  pc, r0, dis

    ld.i    r2, r1
    add.i   r2, r0, -0xfff1
    nz.ld.i pc, r0, m6


dump:
    ld.i    r3, r0

d0:
    JSR     (osnewl)

    ld.i    r1, r5
    add.i   r1, r3
    JSR     (print_hex4_sp)

d1:
    ld.i    r1, r5
    add.i   r1, r3
    ld      r1, r1
    JSR     (print_hex4_sp)

    add.i   r3, r0, 1

    ld.i    r2, r3
    and.i   r2, r0, 0x07
    nz.ld.i pc, r0, d1

    add.i   r3, r0, -0x08

d2:
    ld.i    r1, r5
    add.i   r1, r3
    ld      r1, r1
    and.i   r1, r0, 0x7F

    ld.i    r2, r1
    add.i   r2, r0, -0x20
    nc.ld.i pc, r0, d3
    ld.i    r2, r1
    add.i   r2, r0, -0x7F
    nc.ld.i pc, r0, d4

d3:
    ld.i     r1, r0, 0x2E

d4:
    JSR     (oswrch)
    add.i   r3, r0, 1
    ld.i    r2, r3
    and.i   r2, r0, 0x07
    nz.ld.i pc, r0, d2

    ld.i    r2, r3
    add.i   r2, r0, -0x80
    nc.ld.i pc, r0, d0

    add.i   r5, r3

    ld.i    pc, r0, m6

comma:
    sto     r5, r4
    add.i   r4, r0, 1
    ld.i    pc, r0, m2

at:
    ld.i    r4, r5
    ld.i    pc, r0, m2

go:
    JSR     (g1)
    ld.i    pc, r0, m2

g1:
    ld.i    pc, r5


dis:

    ld.i    r3, r0, 16

dis_loop:
    JSR     (osnewl)

    ld.i    r1, r5
    JSR     (disassemble)
    ld.i    r5, r1

    add.i   r3, r0, -1
    nz.ld.i pc, r0, dis_loop

    ld.i    pc, r0, m6

# --------------------------------------------------------------
#
# osnewl
#
# Outputs <cr> then <lf>
#
# Entry:
#
# Exit:
# - r1 trashed

osnewl:
    ld.i    r1, r0, 0x0a
    JSR     (oswrch)

    ld.i    r1, r0, 0x0d
    # fall through to oswrch

# --------------------------------------------------------------
#
# oswrch
#
# Output a single ASCII character to the UART
#
# Entry:
# - r1 is the character to output
#
# Exit:
# - all registers preserved

oswrch:
    PUSH    (r1)
oswrch_loop:
    ld      r1, r0, 0xfe08
    and.i   r1, r0, 0x8000
    nz.ld.i pc, r0, oswrch_loop
    POP     (r1)
    sto     r1, r0, 0xfe09
    RTS     ()

# --------------------------------------------------------------
#
# osrdch
#
# Read a single ASCII character from the UART
#
# Entry:
#
# Exit:
# - r1 is the character read

osrdch:
    ld      r1, r0, 0xfe08
    and.i   r1, r0, 0x4000
    z.ld.i  pc, r0, osrdch
    ld      r1, r0, 0xfe09
    RTS     ()

# --------------------------------------------------------------
#
# print_string
#
# Prints the zero terminated ASCII string
#
# Entry:
# - r1 points to the zero terminated string
#
# Exit:
# - all other registers preserved

print_string:
    PUSH    (r2)
    ld.i    r2, r1

ps_loop:
    ld      r1, r2
    z.ld.i  pc, r0, ps_exit
    JSR     (oswrch)
    ld.i    r2, r2, 0x0001
    ld.i    pc, r0, ps_loop

ps_exit:
    POP     (r1)
    RTS     ()


# --------------------------------------------------------------
#
# print_hex4
#
# Prints a 4-digit hex value
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_hex4:

    PUSH    (r1)            # preserve working registers
    PUSH    (r2)
    PUSH    (r3)

    ld.i    r2, r1          # r2 is now the value to be printed

    ld.i    r3, r0, 0x04    # r3 is a loop counter for 4 digits

ph_loop:
    add.i   r2, r2          # shift the upper nibble of r2
    adc.i   r1, r1          # into the lower nibble of r1
    add.i   r2, r2          # one bit at a time
    adc.i   r1, r1
    add.i   r2, r2          # add.i rd, rd is the same as ASL
    adc.i   r1, r1          # adc.i rd, rd is the same as ROL
    add.i   r2, r2
    adc.i   r1, r1

    and.i   r1, r0, 0x0F    # mask off everything but the bottom nibble
    add.i   r1, r0, -0x0A   # set the carry if r1 >= 0x0A
    c.add.i  r1, r0, 0x07   # 'A' - '9' + 1
    add.i r1, r0, 0x3A      # '0' (plus the 0x0A from the earlier add)

    JSR     (oswrch)        # output R1

    add.i   r3, r0, -1      # decrement the loop counter
    nz.ld.i pc, r0, ph_loop # loop back for four digits

    POP     (r3)            # restore working registers
    POP     (r2)
    POP     (r1)

    RTS     ()

# --------------------------------------------------------------
#
# print_hex4_sp
#
# Prints a 4-digit hex value followed by a space
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

print_hex4_sp:
     JSR    (print_hex4)
     # fall through to...

# --------------------------------------------------------------
#
# print_sp
#
# Prints a space
#
# Entry:
#
# Exit:
# - all registers preserved

print_sp:
     PUSH   (r1)
     ld.i   r1, r0, 0x20
     JSR    (oswrch)
     POP    (r1)
     RTS    ()

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

    PUSH   (r3)
    PUSH   (r4)
    PUSH   (r5)
    PUSH   (r6)
    PUSH   (r7)

    ld.i    r5, r1                      # r5 holds the instruction addess

    JSR     (print_hex4_sp)             # print address

    ld      r6, r5                      # r6 holds the opcode
    add.i   r5, r0, 1                   # increment the address pointer

    ld.i    r1, r6
    JSR     (print_hex4_sp)             # print opcode

    ld.i    r1, r6
    and.i   r1, r0, 0x1000              # test the length bit
    z.ld.i  pc, r0, dis1

    ld      r7, r5                      # r7 holds the operand
    add.i   r5, r0, 1                   # increment the address pointer

    ld.i    r1, r7
    JSR     (print_hex4)                # print operand - two words instructions
    ld.i    pc, r0, dis2

dis1:

    ld.i    r1, r0, four_spaces
    JSR     (print_string)              # print 4 spaces - one word instructions

dis2:
    JSR     (print_sp)                  # print a space

    ld.i    r2, r6
    and.i   r2, r0, 0xE000              # extract predicate
    ld.i    r1, r0, predicates          # find string for predicate

dis3:
    add.i   r2, r0                      # is r2 zero?
    z.ld.i  pc, r0, dis4
    add.i   r2, r0, -0x2000
    add.i   r1, r0, 0x0005              # move on to next predicate
    ld.i    pc, r0, dis3

dis4:
    JSR     (print_string)

    ld.i    r2, r6
    and.i   r2, r0, 0x0F00              # extract opcode

    ld.i    r1, r0, opcodes             # find string for opcode

dis5:
    add.i   r2, r0                      # is r2 zero?
    z.ld.i  pc, r0, dis6
    add.i   r2, r0, -0x0100
    add.i   r1, r0, 0x0006              # move on to next opcode
    ld.i    pc, r0, dis5

dis6:
    JSR     (print_string)
    JSR     (print_sp)                  # print a space

    ld.i    r1, r6                      # extract destination register
    JSR     (print_reg)

    ld.i    r1, r0, 0x2c
    JSR     (oswrch)
    JSR     (print_sp)                  # print a space

    ld.i    r1, r6                      # extract source register
    ror.i   r1, r1
    ror.i   r1, r1
    ror.i   r1, r1
    ror.i   r1, r1
    JSR     (print_reg)

    ld.i    r1, r6                      # extract length
    and.i   r1, r0, 0x1000

    z.ld.i  pc, r0, dis7

    ld.i    r1, r0, 0x2c                # print a ,
    JSR     (oswrch)

    JSR     (print_sp)                  # print a space

    ld.i    r1, r0, 0x30                # print 0x
    JSR     (oswrch)
    ld.i    r1, r0, 0x78
    JSR     (oswrch)

    ld.i    r1, r7
    JSR     (print_hex4)                # print the operand

dis7:

    ld.i    r1, r5                      # return address of next instruction

    POP     (r7)
    POP     (r6)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    RTS     ()

print_reg:

    and.i   r1, r0, 0x0F
    add.i   r1, r0, -0x0A

    PUSH    (r1)

    c.ld.i pc, r0, pr1

    JSR    (print_sp)

pr1:

    ld.i    r1, r0, 0x72
    JSR     (oswrch)
    POP     (r1)

    nc.ld.i pc, r0, pr2

    PUSH    (r1)
    ld.i    r1, r0, 0x31
    JSR     (oswrch)
    POP     (r1)

    add.i   r1, r0, -0x0A

pr2:
    add.i   r1, r0, 0x3A
    ld.i    pc, r0, oswrch

predicates:
    WORD 0x20,0x7a,0x63,0x2e,0x00    # 000 " zc."
    WORD 0x6e,0x7a,0x63,0x2e,0x00    # 001 "nzc."
    WORD 0x20,0x20,0x63,0x2e,0x00    # 010 "  c."
    WORD 0x20,0x6e,0x63,0x2e,0x00    # 011 " nc."
    WORD 0x20,0x20,0x7a,0x2e,0x00    # 100 "  z."
    WORD 0x20,0x6e,0x7a,0x2e,0x00    # 101 " nz."

four_spaces:
    WORD 0x20,0x20,0x20,0x20,0x00    # 110 "    "
    WORD 0x6e,0x6f,0x70,0x2e,0x00    # 111 "nop."

opcodes:
    WORD 0x6c,0x64,0x2e,0x69,0x20,0x00    # 0000 "ld.i "
    WORD 0x61,0x64,0x64,0x2e,0x69,0x00    # 0001 "add.i"
    WORD 0x61,0x6e,0x64,0x2e,0x69,0x00    # 0010 "and.i"
    WORD 0x6f,0x72,0x2e,0x69,0x20,0x00    # 0011 "or.i "
    WORD 0x78,0x6f,0x72,0x2e,0x69,0x00    # 0100 "xor.i"
    WORD 0x72,0x6f,0x72,0x2e,0x69,0x00    # 0101 "ror.i"
    WORD 0x61,0x64,0x63,0x2e,0x69,0x00    # 0110 "adc.i"
    WORD 0x73,0x74,0x6f,0x20,0x20,0x00    # 0111 "sto  "
    WORD 0x6c,0x64,0x20,0x20,0x20,0x00    # 1000 "ld   "
    WORD 0x61,0x64,0x64,0x20,0x20,0x00    # 1001 "add  "
    WORD 0x61,0x6e,0x64,0x20,0x20,0x00    # 1010 "and  "
    WORD 0x6f,0x72,0x20,0x20,0x20,0x00    # 1011 "or   "
    WORD 0x78,0x6f,0x72,0x20,0x20,0x00    # 1100 "xor  "
    WORD 0x72,0x6f,0x72,0x20,0x20,0x00    # 1101 "ror  "
    WORD 0x61,0x64,0x63,0x20,0x20,0x00    # 1110 "adc  "
    WORD 0x3f,0x3f,0x3f,0x20,0x20,0x00    # 1111 "???  "
