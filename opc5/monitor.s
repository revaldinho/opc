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

test:
    ld.i    r14, r0, 0x07ff

    JSR     (print_string)
    WORD    0x0a,0x0d,0x4f,0x50,0x43,0x35,0x20,0x4d
    WORD    0x6f,0x6e,0x69,0x74,0x6f,0x72,0x0a,0x0d
    WORD    0x00

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
    sto     r5, r6
    add.i   r6, r0, 1
    ld.i    pc, r0, m2

at:
    ld.i    r6, r5
    ld.i    pc, r0, m2

go:
    JSR     (g1)
    ld.i    pc, r0, m2

g1:
    ld.i    pc, r5


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
# Prints the zero terminated ASCII string following the JSR (print_string)
#
# Entry:
#
# Exit:
# - r1 will be zero, r2 will be trashed
# - all other registers preserved

print_string:
    ld.i    r14, r14, 0x0001
    ld      r2, r14

ps_loop:
    ld      r1, r2
    z.ld.i  pc, r0, ps_exit
    JSR     (oswrch)
    ld.i    r2, r2, 0x0001
    ld.i    pc, r0, ps_loop

ps_exit:
    ld.i    pc, r2, 0x0001


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
     PUSH   (r1)
     ld.i   r1, r0, 0x20
     JSR    (oswrch)
     POP    (r1)
     RTS    ()

