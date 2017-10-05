# A loose port of C'mon, the Compact monitor, by Bruce Clark, from
# the 65org16 to the opc5.
#
# see: http://biged.github  o/6502-website-archives/lowkey.comuf.com/cmon.htm
#
# (c) 2017 David Banks

##include "macros.s"

# Inject _BASE_from the build script (C000 on Xilinx, F000 on ICE40)        
EQU        BASE, _BASE_
EQU        CODE, 0xF800

EQU   UART_ADDR, 0xFE08

EQU     MEM_BOT, 0x0100
EQU     MEM_TOP, CODE - 1

# This is the main stack, used by the monitor and by programs that are run with GO
EQU       STACK, CODE - 1

# This is second stack, used by the single step emulation
EQU    SS_STACK, STACK - 0x100  # Second stack

EQU      INPBUF, 0x0030
EQU      INPEND, 0x00F6
EQU        HPOS, 0x00FE

ORG BASE
    mov     pc, r0, monitor

ORG CODE

##include "lib_printhex.s"
##include "lib_printbstring.s"
##include "lib_dumpmem.s"
##include "lib_srec.s"

# ---------------------------------------------------------

monitor:
    mov     r14, r0, STACK

    mov     r1, r0, welcome
    JSR     (print_bstring)

    mov     r11, r0        # enable local echo

mon1:

    mov     r14, r0, STACK

    and     r11, r11       # don't output prompt if echo off
    nz.mov  pc, r0, mon2

    JSR     (OSNEWL)
    mov     r1, r0, 0x2D
    JSR     (OSWRCH)

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
    JSR     (OSRDCH)

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

    JSR     (OSWRCH)

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

    cmp     r1, r0, 0x0005   # l
    z.mov   pc, r0, srec

    cmp     r1, r0, 0xfff1   # x
    nz.mov  pc, r0, mon6

# ---------------------------------------------------------

dump:
    mov     r1, r5
    JSR     (dump_mem)
    add     r5, r0, 0x80
    mov     pc, r0, mon6

# ---------------------------------------------------------

srec:
    JSR     (OSNEWL)
    mov     r1, r0, srec_start_msg
    JSR     (print_bstring)
    JSR     (OSNEWL)
    JSR     (srec_load)
    cmp     r1, r0
    z.mov   pc, r0, mon2
    cmp     r1, r0, 2
    z.mov   pc, r0, srec_checksum_error

srec_bad_format_error:
    mov     r1, r0, srec_bad_format_error_msg
    JSR     (print_bstring)
    mov     pc, r0, mon1

srec_checksum_error:
    mov     r1, r0, srec_checksum_error_msg
    JSR     (print_bstring)
    mov     pc, r0, mon1

srec_start_msg:
    BSTRING "Paste srecords followed by a blank line"
    WORD 0x0000

srec_bad_format_error_msg:
    BSTRING "Bad Format"
    WORD 0x0000

srec_checksum_error_msg:
    BSTRING "Checksum Mismatch"
    WORD 0x0000

# ---------------------------------------------------------

comma:
    sto     r5, r4
    add     r4, r0, 1
    mov     pc, r0, mon2

# ---------------------------------------------------------

at:
    mov     r4, r5                 # r4 is used by the comma command

    sto     r5, r0, reg_state_pc   # Initialize the emulated state used by single step
    sto     r0, r0, reg_state_psr
    mov     r1, r0, spin           # r13 is the link register
    sto     r1, r0, reg_state_r13  # this gives the emulation somewhere to go after the last rst
    mov     r1, r0, SS_STACK       # r14 is the stack pointer
    sto     r1, r0, reg_state_r14  # this gives the emulation a seperate stack area
    mov     pc, r0, mon2

spin:
    mov     pc, r0, spin           # single stepped ends up here
                                   # if you step beyond the last rts

# ---------------------------------------------------------

regs:
    JSR     (OSNEWL)
    JSR     (print_regs)
    mov     pc, r0, mon1           # back to the - prompt

# ---------------------------------------------------------

toggle_echo:
    xor     r11, r0, 1
    mov     pc, r0, mon2

# ---------------------------------------------------------

go:
    sto     r5, r0, go1 + 1
    PUSH    (r11)          # save echo state
    JSR     (load_regs)
    JSR     (go1)
    JSR     (save_regs)
    POP     (r11)          # restore echo state
    mov     pc, r0, mon1

go1:
    mov     pc, r0, 0x0000

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

# ---------------------------------------------------------

dis:
    mov     r3, r0, 16

dis_loop:
    JSR     (OSNEWL)

    mov     r1, r5
    JSR     (disassemble)
    mov     r5, r1

    sub     r3, r0, 1
    nz.mov  pc, r0, dis_loop

    mov     pc, r0, mon6

# ---------------------------------------------------------

# Single Step Command
#
# Local registers:
# r1 is the fetched instruction
# r2 is the fetched operand
# r3 is a temporary working register
# r4 is the program counter
# r5 is the source register number
# r6 is the destination register number
# r7 is the emulated source register
# r8 is the emulated destination register
# r9 is the saved pc value, and then the emulated flags
# r10 is the iteration count
#
# TODO: for OPC6
#
# - support PUTPSR and GETPSR (not setting SWI)
#     - "psr" should be r0
#     - but we re-write src/dst so need to check if values other than r0 are ok
# - support SWI and RTI (???)
#     - need to emulate the shadow PC/shadow PSR

step:
    mov     r10, r5, 1             # iteration count + 1

step_loop:
    ld      r4, r0, reg_state_pc   # load the program counter
    mov     r9, r4                 # save the program counter of the current instruction
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

    ld      r2, r0, nop            # by default the operand slot is filled with a nop
    sto     r2, r0, operand        # store the operand

    mov     r2, r1
    and     r2, r0, 0x1000         # test for an operand
    z.mov   pc, r0, no_operand     # r2 zero if no operand, which is correct

    ld      r2, r4                 # fetch the operand
    sto     r2, r0, operand        # store back the operand, and leave it in r2
    add     r4, r0, 1              # increment the PC

no_operand:
    sto     r4, r0, reg_state_pc   # save the updated program counter which
                                   # will now point to the next instruction

    ld      r7, r5, reg_state      # load the src register value
    ld      r8, r6, reg_state      # load the dst register value

##ifdef CPU_OPC6

    #
    # Emulate OPC6 JSR instruction

    # r1 = instruction, r2 = operand

    mov     r3, r1                 # extract the predicate
    and     r3, r0, 0xe000
    cmp     r3, r0, 0x2000
    z.mov   pc, r0, not_jsr        # never predicate present, so not a jsr

    mov     r3, r1                 # extract the opcode
    and     r3, r0, 0x0f00
    cmp     r3, r0, 0x0c00         # test for inc
    z.mov   pc, r0, skip_src_rewrite
    cmp     r3, r0, 0x0e00         # test for dec
    z.mov   pc, r0, skip_src_rewrite

    cmp     r3, r0, 0x0900         # test for jsr
    nz.mov  pc, r0, not_jsr

    or      r1, r0, 0x1000         # patch the instruction to always have an operand
    mov     r3, r0, jsr_taken
    sto     r3, r0, operand        # patch the operand to be the jsr_taken routine

    add     r2, r7                 # pass EA to jsr_taken by adding the source register (r7) value to the operand (r2)

not_jsr:

##endif

    and     r1, r0, 0xff0f         # patch the instruction so:
    or      r1, r0, 0x0070         # src = r7

skip_src_rewrite:
    and     r1, r0, 0xfff0         # patch the instruction so:
    or      r1, r0, 0x0008         # dst = r8

    sto     r1, r0, instruction    # write the patched instruction

    mov     r1, r9                 # print state done here to be identical to the emulator
    PUSH    (r2)
    JSR     (print_state)
    POP     (r2)

    ld      r9, r0, reg_state_psr  # load the s (bit 2), c (bit 1) and z (bit 0) flags

    PUTPSR  (r9)                   # load the flags

instruction:
    WORD    0x0000                 # emulated instruction patched here

operand:
    WORD    0x0000                 # emulated opcode patched here

    GETPSR  (r9)                   # save the flags

    cmp     r6, r0, 15             # was the destination register r15
    nz.sto  r9, r0, reg_state_psr  # no, then save the flags

    cmp     r6, r0                 # was the destination register r0
    nz.sto  r8, r6, reg_state      # no, then save the new dst register value

next_instruction:
    sub     r10, r0, 1             # decrement the iteration count
    nz.mov  pc, r0, step_loop      # and loop back for more instructions

    ld      r1, r0, reg_state_pc
    JSR     (print_state)          # print the final state

    mov     pc, r0, mon1           # back to the - prompt

nop:
    z.and   r0, r0

##ifdef CPU_OPC6

jsr_taken:
    sto     r4, r6, reg_state      # store the current PC in the specified link register

    cmp     r2, r0, 0xffee         # EA = oswrch?
    nz.mov  pc, r0, not_oswrch

    ld      r1, r0, reg_state_r1   # emulate oswrch
    JSR     (OSWRCH)
    mov     pc, r0, next_instruction

not_oswrch:
    mov     r4, r2                 # update the PC to the calculated effective address
    sto     r4, r0, reg_state_pc   # save the updated PC
    mov     pc, r0, next_instruction

##endif

print_state:
    PUSH    (r13)
    PUSH    (r1)
    JSR     (OSNEWL)
    POP     (r1)
    JSR     (disassemble)

pad1:
    ld      r1, r0, HPOS
    cmp     r1, r0, 42             # pad instruction like the emulator does
    z.mov   pc, r0, pad2
    JSR     (print_spc)
    mov     pc, r0, pad1

pad2:
    JSR     (print_delim)
    JSR     (print_regs)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# Display the registers from single step
#
# Entry:
#
# Exit:
# - r1, r2, r3 are trashed

print_regs:

    PUSH    (r13)
    JSR     (print_spc)
    ld      r1, r0, reg_state_psr # extract SWI flag
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    and     r1, r0, 0x0f
    JSR     (print_hex_1)
    JSR     (print_spc)
    JSR     (print_spc)

    ld      r1, r0, reg_state_psr # extract EI flag
    ror     r1, r1
    ror     r1, r1
    ror     r1, r1
    JSR     (print_flag)

    ld      r1, r0, reg_state_psr # extract S flag
    ror     r1, r1
    ror     r1, r1
    JSR     (print_flag)

    ld      r1, r0, reg_state_psr # extract C flag
    ror     r1, r1
    JSR     (print_flag)

    ld      r1, r0, reg_state_psr # extract Z flag
    JSR     (print_flag)

    mov     r1, r0, 0x3A          # ":"
    JSR     (OSWRCH)

    mov     r2, r0
    mov     r3, r0, 16
dr_loop:
    ld      r1, r2, reg_state
    JSR     (print_spc)
    JSR     (print_hex_4)         # "1234"
    add     r2, r0, 1
    sub     r3, r0, 1
    nz.mov  pc, r0, dr_loop
    POP     (r13)
    RTS     ()

print_flag:
    PUSH    (r13)
    and     r1, r0, 1
    add     r1, r0, 0x30
    JSR     (OSWRCH)              # "0" or "1"
    JSR     (print_spc)           # " "
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# osNEWL
#
# Outputs <cr> then <lf>
#
# Entry:
#
# Exit:
# - r1 trashed

osNEWL:
    PUSH    (r13)
    mov     r1, r0, 0x0a
    JSR     (OSWRCH)
    mov     r1, r0, 0x0d
    JSR     (OSWRCH)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# osWRCH
#
# Output a single ASCII character to the UART
#
# Entry:
# - r1 is the character to output
# Exit:
# - r12 is the horizontal position
# - all other registers preserved

osWRCH:
    PUSH    (r13)
oswrch_loop:
    ld      r13, r0, uart_status
    mi.mov  pc, r0, oswrch_loop
    sto     r1, r0, uart_data
    ld      r13, r0, HPOS     # increment the horizontal position
    mov     r13, r13, 1
    sto     r13, r0, HPOS
    mov     r13, r1
    xor     r13, r0, 13       # test for <cr> without corrupting x
    z.sto   r0, r0, HPOS      # reset horizontal position
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# osRDCH
#
# Read a single ASCII character from the UART
#
# Entry:
#
# Exit:
# - r1 is the character read

osRDCH:
    ld      r1, r0, uart_status
    and     r1, r0, 0x4000
    z.mov   pc, r0, osRDCH
    ld      r1, r0, uart_data
    RTS     ()


# --------------------------------------------------------------
#
# osWORD
#
# Minimal implementation of OSWORD
#
# Just implements OSWORD0 (ReadLine)
#
# Entry:
# - r1 is the OSWORD number
# - r2 points to the OSWORD param block
#
# Exit:
# - r1 is the character read
#
# TODO:
# - better handle lines > max length (currently no 0x0d terminator)
# - support delete-last-char (Delete)
# - support delete-line (Ctrl-U)
# - support character range checking

osWORD:
    cmp     r1, r0
    z.mov   pc, r0, osWORD0
    RTS     ()

osWORD0:
    PUSH    (r13)
    PUSH    (r3)
    ld      r3, r2, 1   # r3 = maximum line length
    sub     r3, r0, 1   # allow space for terminator
    ld      r2, r2      # r2 = input buffer

osWORD0_loop:
    JSR     (OSRDCH)
    cmp     r1, r0, 0x0d
    z.mov   pc, r0, osWORD0_exit
    sto     r1, r2
    add     r2, r0, 1
    sub     r3, r0, 1
    nz.mov  pc, r0, osWORD0_loop

osWORD0_exit:
    mov     r1, r0, 0x0d
    sto     r1, r2
    POP     (r3)
    POP     (r13)
    CLC     ()
    RTS     ()

# -----------------------------------------------------------------------------
# Serial port
# -----------------------------------------------------------------------------

# Limit check to precent code running into next block...

Limit1:
    EQU dummy, 0 if (Limit1 < UART_ADDR) else limit1_error

ORG UART_ADDR

uart_status:
    WORD 0x0000

uart_data:
    WORD 0x0000


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

    JSR     (print_hex_4_spc)           # print address
    JSR     (print_delim)               # print ": " delimiter

    ld      r6, r5                      # r6 holds the opcode
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r6
    JSR     (print_hex_4_spc)           # print opcode

    mov     r1, r6
    and     r1, r0, 0x1000              # test the length bit
    z.mov   pc, r0, dis1

    ld      r7, r5                      # r7 holds the operand
    add     r5, r0, 1                   # increment the address pointer

    mov     r1, r7
    JSR     (print_hex_4)               # print operand - two words instructions
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
    add     r1, r0, 0x0002              # move on to next predicate
    mov     pc, r0, dis3

dis4:
    JSR     (print_bstring)

    mov     r2, r6
    and     r2, r0, 0x0F00              # extract opcode

##ifdef CPU_OPC6
    mov     r1, r6
    and     r1, r0, 0xE000
    cmp     r1, r0, 0x2000
    z.add   r2, r0, 0x1000
    PUSH    (r2)                        # save the opcode so we can later test for inc/dec
##endif

    mov     r1, r0, opcodes             # find string for opcode

dis5:
    add     r2, r0                      # is r2 zero?
    z.mov   pc, r0, dis6
    sub     r2, r0, 0x0100
    add     r1, r0, 0x0003              # move on to next opcode
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

##ifdef CPU_OPC6
    POP     (r2)                        # restore the opcode (bits 12..8)
    and     r2, r0, 0x1D00              # inc = 0x0C00, dec = 0x0E00
    cmp     r2, r0, 0x0C00              # both now map to 0x0C00
    nz.jsr  r13, r0, OSWRCH             # if not inc/dec, src is a register
##else
    JSR     (OSWRCH)
##endif

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
    JSR     (print_hex_4)               # print the operand

dis7:

    mov     r1, r5                      # return address of next instruction

    POP     (r7)
    POP     (r6)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    POP     (r13)
    RTS     ()

print_reg_num:
    PUSH    (r13)
    and     r1, r0, 0x0F

    cmp     r1, r0, 0x0A
    nc.mov  pc, r0, print_reg_num_1

    PUSH    (r1)
    mov     r1, r0, 0x31
    JSR     (OSWRCH)
    POP     (r1)

    sub     r1, r0, 0x0A

print_reg_num_1:
    add     r1, r0, 0x30
    JSR     (OSWRCH)
    POP     (r13)
    RTS     ()

# -----------------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------------

welcome:
    WORD    0x0D0A
    CPU_BSTRING()
    BSTRING " Monitor"
    WORD    0x0D0A, 0x0000

predicates:       # Each predicate must be 2 words, zero terminated
    WORD 0x0000
    WORD 0x0000

##ifdef CPU_OPC6
    WORD 0x0000
##else
    BSTRING "0."
##endif
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
##ifdef CPU_OPC6
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
##else
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

Limit2:
    EQU dummy, 0 if (Limit2 < 0xFFC8) else limit2_error


# -----------------------------------------------------------------------------
# MOS interface
# -----------------------------------------------------------------------------

ORG 0xFFC8

NVRDCH:                      # &FFC8
    mov     pc, r0, osRDCH
    WORD    0x0000

NVWRCH:                      # &FFCB
    mov     pc, r0, osWRCH
    WORD    0x0000

OSFIND:                      # &FFCE
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSGBPB:                      # &FFD1
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSBPUT:                      # &FFD4
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSBGET:                      # &FFD7
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSARGS:                      # &FFDA
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSFILE:                      # &FFDD
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OSRDCH:                      # &FFE0
    mov     pc, r0, osRDCH
    WORD    0x0000

OSASCI:                      # &FFE3
    cmp     r1, r0, 0x0d
    nz.mov  pc, r0, OSWRCH

OSNEWL:                      # &FFE7
    mov     pc, r0, osNEWL
    WORD    0x0000
    WORD    0x0000
    WORD    0x0000

OSWRCR:                      # &FFEC
    mov     r1, r0, 0x0D

OSWRCH:                      # &FFEE
    mov     pc, r0, osWRCH
    WORD    0x0000

OSWORD:                      # &FFF1
    mov     pc, r0, osWORD
    WORD    0x0000
    WORD    0x0000

OSBYTE:                      # &FFF4
    RTS     ()
    WORD    0x0000
    WORD    0x0000

OS_CLI:                      # &FFF7
    RTS     ()
    WORD    0x0000
    WORD    0x0000



# ----------------------------------------------------
# Some test code (fastfib)

        ORG     BASE + 0x100

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

        ORG     BASE + 0x180

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

# 3 digits in 10431 instructions, 26559 cycles
# 4 digits in 16590 instructions, 42229 cycles
# 5 digits in 23644 instructions, 60186 cycles
# 6 digits in 33412 instructions, 85040 cycles
# 7 digits in 42589 instructions, 108368 cycles
# 8 digits in 52659 instructions, 133981 cycles

        EQU ndigits,  6 # Original target 359 digits
        EQU   psize, 21 # Should be 1+ndigits*10/3

        ORG BASE + 0x200
start:
        PUSH(r13)
        ;; trivial banner
        mov r1, r0, 0x4f
        JSR(OSWRCH)
        mov r1, r0, 0x6b
        JSR(OSWRCH)
        mov r1, r0, 0x20
        JSR(OSWRCH)

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
        JSR (OSWRCH)
        mov r1, r0, 46          # lda #46
l4:
        JSR (OSWRCH)
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
        JSR (OSWRCH)
        mov r0, r0, 3142        # RTS()
        POP(r13)
        RTS()

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


p:      WORD 0  # needs 1193 words but there's nothing beyond
