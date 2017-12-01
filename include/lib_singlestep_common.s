##ifndef _LIB_SINGLESTEPCOMMON_S

##define  _LIB_SINGLESTEPCOMMON_S

##include "lib_printhex.s"

# --------------------------------------------------------------
#
# Set the trace flag, to control output diring single stepping
#
# Entry:
# - r1 contains the new value of the trace flag
# - bit 0 = 1 to disasseble the instruction
# - bit 1 = 1 to display register state

ss_trace:
    sto     r1, r0, ss_trace_flag
    RTS     ()

# --------------------------------------------------------------
#
# Print a disassembly of the current instruction, plus presrved
# register state. Used by the single stepper
#
# Entry:
# - r1 contains the address of the current instruction
#
# Exit:
# - r1, r2, r3 are trashed

ss_print_state:
    PUSH    (r13)

    ld      r2, r0, ss_trace_flag  # read the trace flag
    and     r2, r0, 3              # just look at bits 0 and 1
    z.mov   pc, r0, ss_skip_state

    PUSH    (r1)                   # something will be output, so start with a new line
    JSR     (OSNEWL)
    POP     (r1)

    ror     r2, r2
    nc.mov  pc, r0, ss_skip_disassemble

    # Display disassembly of current instruction
    JSR     (disassemble)
ss_pad1:
    ld      r1, r0, HPOS
##ifdef CPU_OPC7
    cmp     r1, r0, 46             # pad instruction like the emulator does
##else
    cmp     r1, r0, 42             # pad instruction like the emulator does
##endif
    z.mov   pc, r0, ss_pad2
    JSR     (print_spc)
    mov     pc, r0, ss_pad1
ss_pad2:
    JSR     (print_delim)
ss_skip_disassemble:

    ror     r2, r2
    nc.mov  pc, r0, ss_skip_state

    # Display register state
    JSR     (ss_print_regs)
ss_skip_state:

    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# Print the preserved register state
#
# Entry:
#
# Exit:
# - r1, r2, r3 are trashed

ss_print_regs:

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
    JSR     (ss_print_flag)

    ld      r1, r0, reg_state_psr # extract S flag
    ror     r1, r1
    ror     r1, r1
    JSR     (ss_print_flag)

    ld      r1, r0, reg_state_psr # extract C flag
    ror     r1, r1
    JSR     (ss_print_flag)

    ld      r1, r0, reg_state_psr # extract Z flag
    JSR     (ss_print_flag)

    mov     r1, r0, 0x3A          # ":"
    JSR     (OSWRCH)

    mov     r2, r0
    mov     r3, r0, 16
ss_dr_loop:
    ld      r1, r2, reg_state
    JSR     (print_spc)
    JSR     (print_hex_word)      # "1234"
    INC     (r2,1)
    DEC     (r3,1)
    nz.mov  pc, r0, ss_dr_loop
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
# Print a single flag value
#
# Entry:
#   r1 bit 0 contains the flag value to print as "0 " or "1 "
#
# Exit:
# - r1 trashed
#

ss_print_flag:
    PUSH    (r13)
    and     r1, r0, 1
    add     r1, r0, 0x30
    JSR     (OSWRCH)              # "0" or "1"
    JSR     (print_spc)           # " "
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
# Register state during single stepping
#

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

ss_trace_flag:
    WORD 0x0003

##endif
