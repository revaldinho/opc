# A loose port of C'mon, the Compact monitor, by Bruce Clark, from
# the 65org16 to the opc5.
#
# see: http://biged.github  o/6502-website-archives/lowkey.comuf.com/cmon.htm
#
# (c) 2017 David Banks

MACRO JSR( _address_)
   mov      r13, pc, 0x0005
   sto      r13, r14
   mov      r14, r14, 0xffff
   mov      pc,  r0, _address_
ENDMACRO

MACRO RTS()
    mov     r14, r14, 0x0001
    ld      pc, r14
ENDMACRO

MACRO   PUSH( _data_)
    sto     _data_, r14
    mov     r14, r14, 0xffff
ENDMACRO

MACRO   POP( _data_ )
    mov     r14, r14, 0x0001
    ld      _data_, r14
ENDMACRO

ORG 0x0000

monitor:
    mov     pc, r0, m0

welcome:
    WORD    0x0a,0x0d,0x4f,0x50,0x43,0x35,0x20,0x4d
    WORD    0x6f,0x6e,0x69,0x74,0x6f,0x72,0x0a,0x0d
    WORD    0x00

m0:
    mov     r14, r0, 0x07ff

    mov     r1, r0, welcome
    JSR     (print_string)

m1:
    JSR     (osnewl)
    mov     r1, r0, 0x2D
    JSR     (oswrch)

m2:
    mov     r5, r0          # r5 == NUMBER
    mov     r1, r0

m3:
    and     r1, r0, 0x0F

m4:
    add     r5, r5          # accumulate digit
    add     r5, r5
    add     r5, r5
    add     r5, r5
    or      r5, r1

m6:
    JSR     (osrdch)

    cmp     r1, r0, 0x0D
    z.mov   pc, r0, m1

#
# Insert additional commands for characters (e.g. control characters)
# outside the range $20 (space) to $7E (tilde) here
#

    cmp     r1, r0, 0x20  # don't output if < 0x20
    nc.mov  pc, r0, m6

    cmp     r1, r0, 0x7F  # don't output if >= 07F
    c.mov   pc, r0, m6

    JSR     (oswrch)

    cmp     r1, r0, 0x2c
    z.mov   pc, r0, comma

    cmp     r1, r0, 0x40
    z.mov   pc, r0, at

#
# Insert additional commands for non-letter characters (or case-sensitive
# letters) here
#
    xor     r1, r0, 0x30


    cmp     r1, r0, 0x0A
    nc.mov  pc, r0, m4
    or      r1, r0, 0x20
    sub     r1, r0, 0x77
#
# mapping:
#   A-F -> $FFFA-$FFFF
#   G-O -> $0000-$0008
#   P-Z -> $FFE9-$FFF3
#

    z.mov   pc, r0, go

    cmp     r1, r0, 0xfffa
    c.mov   pc, r0, m3

#
# Insert additional commands for (case-insensitive) letters here
#

    cmp     r1, r0, 0xfff3   # z
    z.mov   pc, r0, dis

    cmp     r1, r0, 0xffeb   # r
    z.mov   pc, r0, regs

    cmp     r1, r0, 0xffec   # s
    z.mov   pc, r0, step

    cmp     r1, r0, 0xfff1   # x
    nz.mov  pc, r0, m6

dump:
    mov     r3, r0

d0:
    JSR     (osnewl)

    mov     r1, r5
    add     r1, r3
    JSR     (print_hex4_sp)

d1:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    JSR     (print_hex4_sp)

    add     r3, r0, 1

    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, d1

    sub     r3, r0, 0x08

d2:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    and     r1, r0, 0x7F

    cmp     r1, r0, 0x20
    nc.mov  pc, r0, d3
    cmp     r1, r0, 0x7F
    nc.mov  pc, r0, d4

d3:
    mov      r1, r0, 0x2E

d4:
    JSR     (oswrch)
    add     r3, r0, 1
    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, d2

    cmp     r3, r0, 0x80
    nc.mov  pc, r0, d0

    add     r5, r3

    mov     pc, r0, m6

comma:
    sto     r5, r4
    add     r4, r0, 1
    mov     pc, r0, m2

at:
    mov     r4, r5
    mov     pc, r0, m2

go:
    JSR     (g1)
    mov     pc, r0, m2

g1:
    mov     pc, r5


dis:

    mov     r3, r0, 16

dis_loop:
    JSR     (osnewl)

    mov     r1, r5
    JSR     (disassemble)
    mov     r5, r1

    sub     r3, r0, 1
    nz.mov  pc, r0, dis_loop

    mov     pc, r0, m6


# Single Step Command
#
# Global registers:
# r4 is the emulated program counter (set by @)
#
# Local registers:
# r5 is the source register number
# r6 is the destination register number
# r7 is the patched source register
# r8 is the patched destination register
# r9 is the emulated flags


step:

    JSR     (osnewl)
    mov     r1, r4                 # display the next instruction
    JSR     (disassemble)
    JSR     (osnewl)

    ld      r1, r4                 # fetch the instruction
    add     r4, r0, 1              # increment the PC

    mov     r5, r1                 # extract the src register num (r5)
    ror     r5, r5
    ror     r5, r5
    ror     r5, r5
    ror     r5, r5
    and     r5, r0, 0x000F

    mov     r6, r1                 # extract the dst register num (r6)
    and     r6, r0, 0x000F

    and     r1, r0, 0xff00         # patch the instruction so:
    or      r1, r0, 0x0078         # src = r7, dst = r8

    sto     r1, r0, instruction    # write the patched instruction

    and     r1, r0, 0x1000         # test for an operand
    z.mov   pc, r0, no_operand

    ld      r1, r4                 # fetch the operand
    add     r4, r0, 1              # increment the PC
    mov     pc, r0, store_operand

no_operand:
    mov     r1, r0, 0xE200         # operand slot is filled with a nop
                                   #   0.and   r0, r0
store_operand:
    sto     r1, r0, operand        # store the operand

    sto     r4, r0, reg_state_pc   # save the updated program counter which
                                   # will now point to the next instruction

    ld      r7, r5, reg_state      # load the src register value
    ld      r8, r6, reg_state      # load the dst register value
    ld      r9, r0, reg_state_zc   # load the z (bit 1) and c (bit 0) flags

    ror     r9, r9                 # carry flag now updated

    and     r9, r0, 1              # zero flag now updated
                                   # (r9 holds the inverse of the Z flag)
instruction:
    WORD    0x0000                 # emulated instruction patched here

operand:
    WORD    0x0000                 # emulated opcode patched here

save_z_flag:
    z.mov   pc, r0, z_flag_set     # save the sero flag

z_flag_clear:
    or      r9, r0, 0x0002         # r9 bit 1 = 1 means Z clear
    mov     pc, r0, save_c_flag

z_flag_set:
    and     r9, r0, 0xfffd         # r9 bit 1 = 0 means Z set

save_c_flag:
    nc.and   r9, r0, 0xfffe        # r9 bit 0 = 0 means C clear
    c.or     r9, r0, 0x0001        # r9 bit 0 = 1 means C set

    sto     r8, r6, reg_state      # save the new dst register value
    sto     r9, r0, reg_state_zc   # save the new flags

    JSR     (print_regs)           # display the saved registers
    ld      r4, r0, reg_state_pc   # load the PC (r5)

    mov     pc, r0, m1             # back to the - prompt

regs:
    JSR     (osnewl)
    JSR     (print_regs)
    mov     pc, r0, m1             # back to the - prompt


# --------------------------------------------------------------
#
# Display the registers from single step
#
# Entry:
#
# Exit:
# - r1, r2, r3 are trashed

print_regs:
    mov      r2, r0
    mov      r3, r0, 16

dr_loop:
    mov      r1, r2
    JSR      (print_reg)           # "r9"
    mov      r1, r0, 0x3d          # "="
    JSR      (oswrch)
    ld       r1, r2, reg_state
    JSR      (print_hex4_sp)       # "1234"
    add      r2, r0, 1
    mov      r1, r2
    and      r1, r0, 0x0003
    nz.mov   pc, r0, no_newline
    JSR      (osnewl)
no_newline:
    sub      r3, r0, 1
    nz.mov   pc, r0, dr_loop

    mov      r1, r0, 0x63          # c
    ld       r2, r0, reg_state_zc
    and      r2, r0, 1
    JSR      (print_flag)

    mov      r1, r0, 0x7a          # z
    ld       r2, r0, reg_state_zc
    ror      r2, r2
    xor      r2, r0, 1

print_flag:
    JSR      (oswrch)              # "c" or "z"
    mov      r1, r0, 0x3d          # "="
    JSR      (oswrch)
    mov      r1, r2
    and      r1, r0, 1
    add      r1, r0, 0x30
    JSR      (oswrch)              # "0" or "1"
    mov      pc, r0, print_sp      # " "

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
    mov     r1, r0, 0x0a
    JSR     (oswrch)

    mov     r1, r0, 0x0d
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
    and     r1, r0, 0x8000
    nz.mov  pc, r0, oswrch_loop
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
    and     r1, r0, 0x4000
    z.mov   pc, r0, osrdch
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
    mov     r2, r1

ps_loop:
    ld      r1, r2
    z.mov   pc, r0, ps_exit
    JSR     (oswrch)
    mov     r2, r2, 0x0001
    mov     pc, r0, ps_loop

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

    mov     r2, r1          # r2 is now the value to be printed

    mov     r3, r0, 0x04    # r3 is a loop counter for 4 digits

ph_loop:
    add     r2, r2          # shift the upper nibble of r2
    adc     r1, r1          # into the lower nibble of r1
    add     r2, r2          # one bit at a time
    adc     r1, r1
    add     r2, r2          # add   rd, rd is the same as ASL
    adc     r1, r1          # adc   rd, rd is the same as ROL
    add     r2, r2
    adc     r1, r1

    and     r1, r0, 0x0F    # mask off everything but the bottom nibble
    cmp     r1, r0, 0x0A    # set the carry if r1 >= 0x0A
    c.add   r1, r0, 0x07    # 'A' - '9' + 1
    add     r1, r0, 0x30    # '0'

    JSR     (oswrch)        # output R1

    sub     r3, r0, 1       # decrement the loop counter
    nz.mov  pc, r0, ph_loop # loop back for four digits

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
     mov    r1, r0, 0x20
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

    mov     r5, r1                      # r5 holds the instruction addess

    JSR     (print_hex4_sp)             # print address

    ld      r6, r5                      # r6 holds the opcode
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r6
    JSR     (print_hex4_sp)             # print opcode

    mov     r1, r6
    and     r1, r0, 0x1000              # test the length bit
    z.mov   pc, r0, dis1

    ld      r7, r5                      # r7 holds the operand
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r7
    JSR     (print_hex4)                # print operand - two words instructions
    mov     pc, r0, dis2

dis1:

    mov     r1, r0, four_spaces
    JSR     (print_string)              # print 4 spaces - one word instructions

dis2:
    JSR     (print_sp)                  # print a space

    mov     r2, r6
    and     r2, r0, 0xE000              # extract predicate
    mov     r1, r0, predicates          # find string for predicate

dis3:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis4
    sub     r2, r0, 0x2000
    add     r1, r0, 0x0005              # move on to next predicate
    mov     pc, r0, dis3

dis4:
    JSR     (print_string)

    mov     r2, r6
    and     r2, r0, 0x0F00              # extract opcode

    mov     r1, r0, opcodes             # find string for opcode

dis5:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis6
    sub     r2, r0, 0x0100
    add     r1, r0, 0x0005              # move on to next opcode
    mov     pc, r0, dis5

dis6:
    JSR     (print_string)
    JSR     (print_sp)                  # print a space

    mov     r1, r6                      # extract destination register
    JSR     (print_reg)

    mov     r1, r0, 0x2c
    JSR     (oswrch)
    JSR     (print_sp)                  # print a space

    mov     r1, r6                      # extract source register
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    JSR     (print_reg)

    mov     r1, r6                      # extract length
    and     r1, r0, 0x1000

    z.mov   pc, r0, dis7

    mov     r1, r0, 0x2c                # print a ,
    JSR     (oswrch)

    JSR     (print_sp)                  # print a space

    mov     r1, r0, 0x30                # print 0x
    JSR     (oswrch)
    mov     r1, r0, 0x78
    JSR     (oswrch)

    mov     r1, r7
    JSR     (print_hex4)                # print the operand

dis7:

    mov     r1, r5                      # return address of next instruction

    POP     (r7)
    POP     (r6)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    RTS     ()

print_reg:

    and     r1, r0, 0x0F
    cmp     r1, r0, 0x0A

    PUSH    (r1)

    c.mov  pc, r0, pr1

    JSR    (print_sp)

pr1:

    mov     r1, r0, 0x72
    JSR     (oswrch)
    POP     (r1)

    nc.mov  pc, r0, pr2

    PUSH    (r1)
    mov     r1, r0, 0x31
    JSR     (oswrch)
    POP     (r1)

    sub     r1, r0, 0x0A

pr2:
    add     r1, r0, 0x30
    mov     pc, r0, oswrch

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
    WORD 0x6d,0x6f,0x76,0x20,0x00    # 0000 "mov "
    WORD 0x61,0x6e,0x64,0x20,0x00    # 0001 "and "
    WORD 0x6f,0x72,0x20,0x20,0x00    # 0010 "or  "
    WORD 0x78,0x6f,0x72,0x20,0x00    # 0011 "xor "
    WORD 0x61,0x64,0x64,0x20,0x00    # 0100 "add "
    WORD 0x61,0x64,0x63,0x20,0x00    # 0101 "adc "
    WORD 0x73,0x74,0x6f,0x20,0x00    # 0110 "sto "
    WORD 0x6c,0x64,0x20,0x20,0x00    # 0111 "ld  "
    WORD 0x72,0x6f,0x72,0x20,0x00    # 1000 "ror "
    WORD 0x6e,0x6f,0x74,0x20,0x00    # 1001 "not "
    WORD 0x73,0x75,0x62,0x20,0x00    # 1010 "sub "
    WORD 0x73,0x62,0x63,0x20,0x00    # 1011 "sbc "
    WORD 0x63,0x6d,0x70,0x20,0x00    # 1100 "cmp "
    WORD 0x63,0x6d,0x70,0x63,0x00    # 1101 "cmpc"
    WORD 0x62,0x73,0x77,0x70,0x00    # 1110 "bswp"
    WORD 0x69,0x6e,0x74,0x72,0x00    # 1111 "intr"

reg_state:
    WORD 0x0000
    WORD 0x1111
    WORD 0x2222
    WORD 0x3333
    WORD 0x4444
    WORD 0x5555
    WORD 0x6666
    WORD 0x7777
    WORD 0x8888
    WORD 0x9999
    WORD 0xaaaa
    WORD 0xbbbb
    WORD 0xcccc
    WORD 0xdddd
    WORD 0xeeee

reg_state_pc:
    WORD 0xffff

reg_state_zc:
    WORD 0x0002

# ----------------------------------------------------
# Some test code (fib)

ORG 0x600
        mov   r10,r0,RSLTS      # initialise the results pointer
        mov   r13,r0,RETSTK     # initialise the return address stack
        mov   r5,r0             # Seed fibonacci numbers in r5,r6
        mov   r6,r0,1
        mov   r1,r0,1           # Use R1 as a constant 1 register
        mov   r11,r0,-1         # use R11 as a constant -1 register

        sto   r5,r10            # save r5 and r6 as first resultson results stack
        add   r10,r1
        sto   r6,r10
        add   r10,r1

        mov   r4,r0,-23         # set up a counter in R4
        mov   r14,r0,CONT       # return address in r14
        mov   r8,r0,FIB         # Store labels in registers to minimize loop instructions
LOOP:   mov   pc,r8             # JSR FIB
CONT:   add   r4,r1             # inc loop counter
        nz.mov  pc,r8           # another iteration if not zero

END:    mov  pc, r0, END


FIB:    sto    r14,r13        # Push return address on stack
        add    r13,r1         # incrementing stack pointer

        mov    r2,r5          # Fibonacci computation
        add    r2,r6
        sto    r2,r10         # Push result in results stack
        add    r10,r1         # incrementing stack pointer

        mov    r5,r6          # Prepare r5,r6 for next iteration
        mov    r6,r2

        add     r13,r11        # Pop return address of stack
        ld      pc,r13        # and return

        ORG 0x700

# 8 deep return address stack and stack pointer
RETSTK: WORD 0,0,0,0,0,0,0,0

# stack for results with stack pointer
RSLTS:  WORD 0



