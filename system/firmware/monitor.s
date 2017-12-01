# A loose port of C'mon, the Compact monitor, by Bruce Clark, from
# the 65org16 to the opc5.
#
# see: http://biged.github  o/6502-website-archives/lowkey.comuf.com/cmon.htm
#
# (c) 2017 David Banks

##include "macros.s"

##ifdef CPU_OPC7
# Currently fixed addresses on opc7
EQU        BASE, 0x0000
EQU        CODE, 0x0100
EQU   UART_ADDR, 0xFFFFFE08
EQU         MOS, 0x00C8
EQU     EXAMPLE, 0x0800
##else
# Inject _BASE_from the build script (C000 on Xilinx, F000 on ICE40)
EQU        BASE, _BASE_
EQU        CODE, 0xF800
EQU   UART_ADDR, 0xFE08
EQU         MOS, 0xFFC8
EQU     EXAMPLE, BASE + 0x0100
##endif

# These are passed in directly from the makefile
EQU     MEM_BOT, _MEM_BOT_
EQU     MEM_TOP, _MEM_TOP_
EQU       STACK, _STACK_

EQU UART_STATUS, UART_ADDR
EQU   UART_DATA, UART_ADDR + 1

# This is the main stack, used by the monitor and by programs that are run with GO
EQU  MAIN_STACK, STACK - 0x100

# This is second stack, used by the single step emulation
EQU    SS_STACK, STACK    # Second stack

EQU      INPBUF, 0x0008
EQU      INPEND, 0x00C0
EQU        HPOS, 0x0006

ORG BASE
    mov     pc, r0, monitor

ORG BASE + 2
    rti    pc, pc

ORG BASE + 4
    rti    pc, pc

ORG CODE

##include "lib_printhex.s"
##include "lib_printbstring.s"
##include "lib_dumpmem.s"
##include "lib_srec.s"
##include "lib_disassemble.s"
##include "lib_singlestep.s"

# ---------------------------------------------------------

monitor:
    mov     r14, r0, MAIN_STACK

    mov     r1, r0, welcome
    JSR     (print_bstring)

    mov     r11, r0        # enable local echo

mon1:

    mov     r14, r0, MAIN_STACK

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

    cmp     r1, r0, 0xfffa-0x10000
    c.mov   pc, r0, mon3

#
# Insert additional commands for (case-insensitive) letters here
#

    cmp     r1, r0, 0xfff3-0x10000   # z
    z.mov   pc, r0, dis

    cmp     r1, r0, 0xffeb-0x10000   # r
    z.mov   pc, r0, regs

    cmp     r1, r0, 0xffec-0x10000   # s
    z.mov   pc, r0, step

    cmp     r1, r0, 0xffed-0x10000   # t
    z.mov   pc, r0, trace

    cmp     r1, r0, 0x0005           # l
    z.mov   pc, r0, srec

    cmp     r1, r0, 0xfff1-0x10000   # x
    nz.mov  pc, r0, mon6

# ---------------------------------------------------------

dump:
    mov     r1, r5
    JSR     (dump_mem)
    mov     r5, r1
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
    INC     (r4,1)
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
    JSR     (ss_print_regs)
    mov     pc, r0, mon1           # back to the - prompt

# ---------------------------------------------------------

step:

    mov     r1, r5                 # number of instructions to step
    JSR     (ss_step)
    mov     pc, r0, mon1           # back to the - prompt

# ---------------------------------------------------------

trace:

    mov     r1, r5                 # value for the trace flag
    JSR     (ss_trace)
    mov     pc, r0, mon1           # back to the - prompt

# ---------------------------------------------------------

toggle_echo:
    xor     r11, r0, 1
    mov     pc, r0, mon2

# ---------------------------------------------------------

go:
##ifdef CPU_OPC7
    mov     r1, r0, 0xffffffff
    movt    r1, r0, 0x000f
    and     r5, r1
    mov     r1, r0         # opcode for mov pc, r0 is 0x00f00000
    movt    r1, r0, 0x00f0
    or      r5, r1
    sto     r5, r0, go1
##else
    sto     r5, r0, go1 + 1
##endif
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

    DEC     (r3, 1)
    nz.mov  pc, r0, dis_loop

    mov     pc, r0, mon6

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
    IN      (r13, UART_STATUS)
##ifdef CPU_OPC7
    and     r13, r0, 0xffff8000
    nz.mov  pc, r0, oswrch_loop
##else
    mi.mov  pc, r0, oswrch_loop
##endif
    OUT     (r1, UART_DATA)
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
    IN      (r1, UART_STATUS)
    and     r1, r0, 0x4000
    z.mov   pc, r0, osRDCH
    IN      (r1, UART_DATA)
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
    DEC     (r3,1)      # allow space for terminator
    ld      r2, r2      # r2 = input buffer

osWORD0_loop:
    JSR     (OSRDCH)
    cmp     r1, r0, 0x0d
    z.mov   pc, r0, osWORD0_exit
    sto     r1, r2
    INC     (r2, 1)
    DEC     (r3, 1)
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

##ifdef CPU_OPC5LS

# Limit check to precent code running into next block...

Limit1:
    EQU dummy, 0 if (Limit1 < UART_ADDR) else limit1_error

ORG UART_ADDR

    WORD 0x0000
    WORD 0x0000

##endif


# -----------------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------------

welcome:
##ifdef CPU_OPC7
    BSTRING "\n\rOPC7 Monitor\n\r"
##else
    WORD    0x0D0A
    CPU_BSTRING()
    BSTRING " Monitor"
    WORD    0x0D0A
##endif
    WORD    0x0000

# -----------------------------------------------------------------------------
# MOS interface
# (this is only fixed in the 16 bit machines)
# -----------------------------------------------------------------------------

# Limit check to precent code running into next block...

##ifndef CPU_OPC7
Limit2:
    EQU dummy, 0 if (Limit2 < MOS) else limit2_error
##endif

ORG MOS

NVRDCH:                      # &FFC8
    mov     pc, r0, osRDCH

ORG MOS + (0xCB-0xC8)

NVWRCH:                      # &FFCB
    mov     pc, r0, osWRCH

ORG MOS + (0xCE-0xC8)

OSFIND:                      # &FFCE
    RTS     ()

ORG MOS + (0xD1-0xC8)

OSGBPB:                      # &FFD1
    RTS     ()

ORG MOS + (0xD4-0xC8)

OSBPUT:                      # &FFD4
    RTS     ()

ORG MOS + (0xD7-0xC8)

OSBGET:                      # &FFD7
    RTS     ()

ORG MOS + (0xDA-0xC8)

OSARGS:                      # &FFDA
    RTS     ()

ORG MOS + (0xDD-0xC8)

OSFILE:                      # &FFDD
    RTS     ()

ORG MOS + (0xE0-0xC8)

OSRDCH:                      # &FFE0
    mov     pc, r0, osRDCH

ORG MOS + (0xE3-0xC8)

OSASCI:                      # &FFE3
    cmp     r1, r0, 0x0d
    nz.mov  pc, r0, OSWRCH

ORG MOS + (0xE7-0xC8)

OSNEWL:                      # &FFE7
    mov     pc, r0, osNEWL

ORG MOS + (0xEC-0xC8)

OSWRCR:                      # &FFEC
    mov     r1, r0, 0x0D

ORG MOS + (0xEE-0xC8)

OSWRCH:                      # &FFEE
    mov     pc, r0, osWRCH

ORG MOS + (0xF1-0xC8)

OSWORD:                      # &FFF1
    mov     pc, r0, osWORD

ORG MOS + (0xF4-0xC8)

OSBYTE:                      # &FFF4
    RTS     ()

ORG MOS + (0xF7-0xC8)

OS_CLI:                      # &FFF7
    RTS     ()

# ----------------------------------------------------
# Some test code (fastfib)

        ORG     EXAMPLE

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

        ORG     EXAMPLE + 0x80

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

        ORG EXAMPLE + 0x100
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
        mov r3, r0, WORD_SIZE   # ldy #16
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
        mov r3, r0, WORD_SIZE   # ldy #16
        mov r1, r0, 0           # lda #0
        add r11, r11            # asl q
d1:     ROL (r1, r1)            # rol
        cmp r1, r10             # cmp r
        nc.mov pc, r0, d2       # bcc d2
        sub r1, r10             # sbc r
d2:     ROL(r11, r11)           # rol q
        mov r3, r3, -1          # dey
        nz.mov pc, r0, d1       # bne d1
        RTS()


p:      WORD 0  # needs 1193 words but there's nothing beyond
