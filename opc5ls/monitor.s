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
    mov     r14, r0, 0x07ff

    mov     r1, r0, welcome
    JSR     (print_string)

    mov     r11, r0        # enable local echo

mon1:

    and     r11, r11       # don't output prompt if echo off
    nz.mov  pc, r0, mon2

    JSR     (osnewl)
    mov     r1, r0, 0x2D
    JSR     (oswrch)

mon2:
    mov     r5, r0          # r5 == NUMBER
    mov     r1, r0

mon3:
    and     r1, r0, 0x0F

mon4:
    add     r5, r5          # accumulate digit
    add     r5, r5
    add     r5, r5
    add     r5, r5
    or      r5, r1

mon6:
    JSR     (osrdch)

    cmp     r1, r0, 0x0D
    z.mov   pc, r0, mon1

#
# Insert additional commands for characters (e.g. control characters)
# outside the range $20 (space) to $7E (tilde) here
#

    and     r11, r11      # don't output if echo off
    nz.mov  pc, r0, echo_off

    cmp     r1, r0, 0x20  # don't output if < 0x20
    nc.mov  pc, r0, mon6

    cmp     r1, r0, 0x7F  # don't output if >= 07F
    c.mov   pc, r0, mon6

    JSR     (oswrch)

echo_off:
    cmp     r1, r0, 0x23
    z.mov   pc, r0, toggle_echo

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
    nc.mov  pc, r0, mon4
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
    c.mov   pc, r0, mon3

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
    nz.mov  pc, r0, mon6

dump:
    mov     r3, r0

d0:
    JSR     (osnewl)

    mov     r1, r5
    add     r1, r3
    JSR     (print_hex4_sp)

dump1:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    JSR     (print_hex4_sp)

    add     r3, r0, 1

    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, dump1

    sub     r3, r0, 0x08

dump2:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    and     r1, r0, 0x7F

    cmp     r1, r0, 0x20
    nc.mov  pc, r0, dump3
    cmp     r1, r0, 0x7F
    nc.mov  pc, r0, dump4

dump3:
    mov      r1, r0, 0x2E

dump4:
    JSR     (oswrch)
    add     r3, r0, 1
    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, dump2

    cmp     r3, r0, 0x80
    nc.mov  pc, r0, d0

    add     r5, r3

    mov     pc, r0, mon6

comma:
    sto     r5, r4
    add     r4, r0, 1
    mov     pc, r0, mon2

at:
    mov     r4, r5
    mov     pc, r0, mon2

toggle_echo:
    xor     r11, r0, 1
    mov     pc, r0, mon2

go:
    sto     r5, r0, go2
    JSR     (load_regs)
    JSR     (go1)
    JSR     (save_regs)
    mov     pc, r0, mon1

go1:
    WORD    0x100F   # mov pc, r0, ...
go2:
    WORD    0x0000


load_regs:
    ld      r1, r0, reg_state_r1
    ld      r2, r0, reg_state_r2
    ld      r3, r0, reg_state_r3
    ld      r4, r0, reg_state_r4
    ld      r5, r0, reg_state_r5
    ld      r6, r0, reg_state_r6
    ld      r7, r0, reg_state_r7
    ld      r8, r0, reg_state_r8
    ld      r9, r0, reg_state_r9
    ld      r10, r0, reg_state_r10
    ld      r11, r0, reg_state_r11
    ld      r12, r0, reg_state_r12
    RTS     ()

save_regs:
    sto     r1, r0, reg_state_r1
    sto     r2, r0, reg_state_r2
    sto     r3, r0, reg_state_r3
    sto     r4, r0, reg_state_r4
    sto     r5, r0, reg_state_r5
    sto     r6, r0, reg_state_r6
    sto     r7, r0, reg_state_r7
    sto     r8, r0, reg_state_r8
    sto     r9, r0, reg_state_r9
    sto     r10, r0, reg_state_r10
    sto     r11, r0, reg_state_r11
    sto     r12, r0, reg_state_r12
    RTS     ()

dis:

    mov     r3, r0, 16

dis_loop:
    JSR     (osnewl)

    mov     r1, r5
    JSR     (disassemble)
    mov     r5, r1

    sub     r3, r0, 1
    nz.mov  pc, r0, dis_loop

    mov     pc, r0, mon6


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
# r10 is the iteration count

step:
    mov     r10, r5, 1             # iteration count + 1

step_loop:
    JSR     (print_state)

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
    mov     r1, r0, 0x2200         # operand slot is filled with a nop
                                   #   0.and   r0, r0
store_operand:
    sto     r1, r0, operand        # store the operand

    sto     r4, r0, reg_state_pc   # save the updated program counter which
                                   # will now point to the next instruction

    ld      r7, r5, reg_state      # load the src register value
    ld      r8, r6, reg_state      # load the dst register value
    ld      r9, r0, reg_state_psr  # load the s (bit 2), c (bit 1) and z (bit 0) flags

    psr     psr, r9                # load the flags

instruction:
    WORD    0x0000                 # emulated instruction patched here

operand:
    WORD    0x0000                 # emulated opcode patched here

    psr     r9, psr                # save the flags

    cmp     r6, r0, 15             # was the destination register r15
    nz.sto  r9, r0, reg_state_psr  # no, then save the flags

    sto     r8, r6, reg_state      # save the new dst register value

    ld      r4, r0, reg_state_pc   # load the PC (r5)

    sub     r10, r0, 1             # decrement the iteration count
    nz.mov  pc, r0, step_loop      # and loop back for more instructions

    JSR     (print_state)          # print the final state

    mov     pc, r0, mon1           # back to the - prompt

regs:
    JSR     (osnewl)
    JSR     (print_regs)
    mov     pc, r0, mon1           # back to the - prompt

print_state:
    JSR     (osnewl)
    mov     r1, r4                 # display the next instruction
    JSR     (disassemble)

pad1:
    cmp     r12, r0, 42            # pad instruction like the emulator does
    z.mov   pc, r0, pad2
    JSR     (print_sp)
    mov     pc, r0, pad1

pad2:
    JSR     (print_delim)
    # fall through into print_regs

# --------------------------------------------------------------
#
# Display the registers from single step
#
# Entry:
#
# Exit:
# - r1, r2, r3 are trashed

print_regs:

    ld       r1, r0, reg_state_psr # extract S flag
    ror      r1, r1
    ror      r1, r1
    JSR      (print_flag)

    ld       r1, r0, reg_state_psr # extract C flag
    ror      r1, r1
    JSR      (print_flag)

    ld       r1, r0, reg_state_psr # extract Z flag
    JSR      (print_flag)

    mov      r1, r0, 0x3A          # ":"
    JSR      (oswrch)

    mov      r2, r0
    mov      r3, r0, 16
dr_loop:
    ld       r1, r2, reg_state
    JSR      (print_sp)
    JSR      (print_hex4)          # "1234"
    add      r2, r0, 1
    sub      r3, r0, 1
    nz.mov   pc, r0, dr_loop
    RTS      ()

print_flag:
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
# Exit:
# - r12 is the horizontal position
# - r13 (the scratch register) is trashed
# - all other registers preserved

oswrch:
    ld      r13, r0, 0xfe08
    and     r13, r0, 0x8000
    nz.mov  pc, r0, oswrch
    sto     r1, r0, 0xfe09
    mov     r12, r12, 1       # increment the horizontal position
    mov     r13, r1           #
    xor     r13, r0, 13       # test for <cr> without corrupting x
    z.mov   r12, r0           # reset horizontal position
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
    and     r1, r0, 0xff
    z.mov   pc, r0, ps_exit
    JSR     (oswrch)
    ld      r1, r2
    bswp    r1, r1
    and     r1, r0, 0xff
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
    c.add   r1, r0, 0x27    # 'a' - '9' + 1
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
# print_delim
#
# Prints a <space>:<space> delimeter
#
# Entry:
#
# Exit:
# - all registers preserved

print_delim:
     PUSH   (r1)
     mov    r1, r0, 0x3a
     JSR    (oswrch)
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
    JSR     (print_delim)               # print ": " delimiter

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
    JSR     (print_sp)                  # print space
    JSR     (print_delim)               # print ": " delimiter

    mov     r2, r6
    and     r2, r0, 0xE000              # extract predicate
    mov     r1, r0, predicates          # find string for predicate

dis3:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis4
    sub     r2, r0, 0x2000
    add     r1, r0, 0x0002              # move on to next predicate
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
    add     r1, r0, 0x0003              # move on to next opcode
    mov     pc, r0, dis5

dis6:
    JSR     (print_string)
    JSR     (print_sp)                  # print a space

    mov     r1, r6                      # extract destination register
    JSR     (print_reg)

    mov     r1, r0, 0x2c
    JSR     (oswrch)

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

    PUSH    (r1)
    mov     r1, r0, 0x72
    JSR     (oswrch)
    POP     (r1)

    cmp     r1, r0, 0x0A
    nc.mov  pc, r0, print_reg_num

    PUSH    (r1)
    mov     r1, r0, 0x31
    JSR     (oswrch)
    POP     (r1)

    sub     r1, r0, 0x0A

print_reg_num:
    add     r1, r0, 0x30
    mov     pc, r0, oswrch

welcome:
    WORD    0x0D0A
    BSTRING "OPC5 Monitor"
    WORD    0x0D0A, 0x0000

predicates:       # Each predicate must be 2 words, zero terminated
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


four_spaces:
    BSTRING "    "
    WORD    0x0000

opcodes:    # Each opcode must be 3 words, zero terminated
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

reg_state:
    WORD 0x0000
reg_state_r1:
    WORD 0x0000
reg_state_r2:
    WORD 0x0000
reg_state_r3:
    WORD 0x0000
reg_state_r4:
    WORD 0x0000
reg_state_r5:
    WORD 0x0000
reg_state_r6:
    WORD 0x0000
reg_state_r7:
    WORD 0x0000
reg_state_r8:
    WORD 0x0000
reg_state_r9:
    WORD 0x0000
reg_state_r10:
    WORD 0x0000
reg_state_r11:
    WORD 0x0000
reg_state_r12:
    WORD 0x0000
reg_state_r13:
    WORD 0x0000
reg_state_r14:
    WORD 0x0000
reg_state_pc:
    WORD 0x0000
reg_state_psr:
    WORD 0x0000

# Limit check to precent code running into next block...

Limit1:
    EQU dummy, 0 if (Limit1 < 0x0800) else limit1_error

# ----------------------------------------------------
# Some test code (fastfib)

        ORG     0x700

fib:
        mov     r4, r0, fibRes
        mov     r5, r0, fibEnd
        mov     r6, r0, fibLoop
        mov     r10, r0, 1

        mov     r1, r0     # r1 = 0
        mov     r2, r10    # r2 = 1
fibLoop:
        add     r1, r2
        c.mov   pc, r5     # r5 = fibEnd
        sto     r1, r4     # r4 = results
        add     r4, r10    # r10 = 1
        add     r2, r1
        c.mov   pc, r5     # r5 = fibEnd
        sto     r2, r4     # r4 = results
        add     r4, r10    # r10 = 1
        mov     pc, r6     # r6 = fibLoop

fibEnd:
        RTS     ()

        ORG     0x780

fibRes:

# ----------------------------------------------------
# Some test code (pi)

        ;;  pi program by Bruce Clark as seen on 6502.org
        ;;  ported from 65816 to 65Org16 and then to OPC5ls
        ;;  see http://forum.6502.org/viewtopic.php?p=15708#p15708

        ;; r15 is pc
        ;; r14 is stack pointer
        ;; r13 is temporary used by JSR

        ;; r1  will be used as a was in 65org16
        ;; r2  will be used as x was in 65org16
        ;; r3  will be used as y was in 65org16

        ;; r4 is the stacked value of a
        ;; r5 is the stacked value of x
        ;; r6 is the stacked value of y

        ;; r9  stands for s
        ;; r10 stands for r
        ;; r11 stands for q
        ;; r12 stands for p (a pointer)

# 3 digits in 10431 instructions, 26559 cycles
# 4 digits in 16590 instructions, 42229 cycles
# 5 digits in 23644 instructions, 60186 cycles
# 6 digits in 33412 instructions, 85040 cycles
# 7 digits in 42589 instructions, 108368 cycles
# 8 digits in 52659 instructions, 133981 cycles

        ORG 359 # Original target 359 digits
ndigits:

        ORG 1193 # 1193  should be 1+ndigits*10/3
psize:

        ORG 0x1000
start:
        ;; trivial banner
        mov r1, r0, 0x4f
        JSR(oswrch)
        mov r1, r0, 0x6b
        JSR(oswrch)
        mov r1, r0, 0x20
        JSR(oswrch)


        ;; mov r14, r0, stack   ; initialise stack pointer
        JSR( init)
        mov r2, r0, ndigits     # ldx #359
        mov r3, r0, psize       # ldy #1193
l1:
        mov r6, r3              # phy
        mov r4, r1              # pha
        mov r5, r2              # phx
        mov r11, r0             # stz q
        mov r1, r3              # tya
        mov r2, r1              # tax

l2:     mov r1, r2              # txa
        JSR (mul)
        mov r9, r1              # sta s
        mov r1, r0, 10          # lda #10
        mov r11, r1             # sta q
        ld  r1, r2, p-1         # lda p-1,x
        JSR (mul)
                                # clc
        add r1, r9              # adc s
        mov r11, r1             # sta q
        mov r1, r2              # txa
        add r1, r1              # asl
        mov r1, r1, -1          # dec
        JSR (div)
        sto r1, r2, p-1         # sta p-1,x
        mov r2, r2, -1          # dex
        nz.mov pc, r0, l2       # bne l2

        mov r1, r0, 10          # lda #10
        JSR (div)
        sto r1, r0, p           # sta p
        mov r2, r5              # plx
        mov r1, r4              # pla
        mov r3, r11             # ldy q
        cmp r3, r0, 10          # cpy #10
        nc.mov pc, r0, l3       # bcc l3
        mov r3, r0              # ldy #0
        mov r1, r1, 1           # inc
l3:
        cmp r2, r0, ndigits-1   # cpx #358
        nc.mov pc, r0, l4       # bcc l4
        nz.mov pc, r0, l5       # bne l5
        JSR (oswrch)
        mov r1, r0, 46          # lda #46
l4:
        JSR (oswrch)
l5:     mov r1, r3              # tya
        xor r1, r0, 48          # eor #48
        mov r3, r6              # ply
        cmp r2, r0, ndigits-1   # cpx #358
        c.mov pc, r0, l6        # bcs l6
                                # dey
                                # dey
        mov r3, r3, -3          # dey by 3
l6:     mov r2, r2, -1          # dex
        nz.mov pc, r0, l1       # bne l1
        JSR (oswrch)
        mov r0, r0, 3142        # RTS()
        RTS()
done:   mov pc, r0, done

init:
        mov r1, r0, 2           # lda #2
        mov r2, r0, psize       # was ldx #1192
i1:     sto r1, r2, p-1         # was sta p,x
        mov r2, r2, -1          # dex
        nz.mov pc, r0, i1       # bne instead of bpl i1
        RTS()

mul:                            # uses y as loop counter
        mov r10, r1             # sta r
        mov r3, r0, 16          # ldy #16
m1:     add r1, r1              # asl
        add r11, r11            # asl q
        nc.mov pc, r0, m2       # bcc m2
                                # clc
        add r1, r10             # adc r
m2:     mov r3, r3, -1          # dey
        nz.mov pc, r0, m1       # bne m1
        RTS()

div:                            # uses y as loop counter
        mov r10, r1             # sta r
        mov r3, r0, 16          # ldy #16
        mov r1, r0, 0           # lda #0
        add r11, r11            # asl q
d1:     adc r1, r1              # rol
        cmp r1, r10             # cmp r
        nc.mov pc, r0, d2       # bcc d2
        sbc r1, r10             # sbc r
d2:     adc r11, r11            # rol q
        mov r3, r3, -1          # dey
        nz.mov pc, r0, d1       # bne d1
        RTS()

base:   WORD 0,0,0,0,0,0,0,0,0  # reserve some stack space
stack:  WORD 0
p:      WORD 0  # needs 1193 words but there's nothing beyond

