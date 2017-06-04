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

halt:
    ld.i    r0, r0

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

    # the first loop calculates and stacks the 4 hex digits

    ld.i    r3, r0, 0x04

ph_loop1:

    ld.i    r2, r1

    and.i   r2, r0, 0x0F    # mask off everything but the bottom nibble
    add.i   r2, r0, -0x0A   # there must be a better way to do a compare!
    c.add.i  r2, r0, 0x07   # 'A' - '9' + 1
    add.i r2, r0, 0x3A      # '0' (plus the 0x0A from the compare)

    PUSH    (r2)

    ror.i     r1, r1
    ror.i     r1, r1
    ror.i     r1, r1
    ror.i     r1, r1

    add.i   r3, r0, -1
    nz.ld.i pc, r0, ph_loop1

    # the second loop calculates and unstacks and prints the 4 hex digits

    ld.i    r3, r0, 0x04

ph_loop2:

    POP     (r1)
    JSR     (oswrch)

    add.i   r3, r0, -1
    nz.ld.i pc, r0, ph_loop2

    POP     (r3)            # restore working registers
    POP     (r2)
    POP     (r1)

    RTS     ()


    
