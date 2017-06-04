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
    WORD 0x4f,0x50,0x43,0x35,0x20,0x4d,0x6f,0x6e,0x69,0x74,0x6f,0x72,0x00
    JSR     (osnewl)

    ld.i    r1, r0, 0x1234
    JSR     (print_hex4)
    JSR     (osnewl)

    ld.i    r1, r0, 0x5678
    JSR     (print_hex4)
    JSR     (osnewl)

    ld.i    r1, r0, 0x9abc
    JSR     (print_hex4)
    JSR     (osnewl)

    ld.i    r1, r0, 0xdef0
    JSR     (print_hex4)
    JSR     (osnewl)

forever:
    ld.i    pc, r0, forever

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
# Output a single ASCII character
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
