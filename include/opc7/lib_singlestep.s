##ifndef _LIB_SINGLESTEP_S

##define  _LIB_SINGLESTEP_S

##include "lib_disassemble.s"

##include "lib_singlestep_common.s"

# Single Step one or more instructions
#
# Entry:
#    r1 contains the number of instructions to step
#
# Exit:
#    all registers trashed
#
# Local registers:
# r1 is the fetched instruction
# r2 is the operand (for JSR)
# r3 is a temporary working register
# r4 is the program counter
# r5 is the source register number
# r6 is the destination register number
# r7 is the emulated source register
# r8 is the emulated destination register
# r9 is the saved pc value, and then the emulated flags
# r10 is the iteration count
#
# TODO
#
# - support PUTPSR and GETPSR (not setting SWI)
#     - "psr" should be r0
#     - but we re-write src/dst so need to check if values other than r0 are ok
# - support SWI and RTI (???)
#     - need to emulate the shadow PC/shadow PSR

ss_step:

    PUSH    (r13)

    mov     r10, r1, 1             # iteration count + 1

ss_loop:
    ld      r4, r0, reg_state_pc   # load the program counter
    mov     r9, r4                 # save the program counter of the current instruction
    ld      r1, r4                 # fetch the instruction
    INC     (r4,1)                 # increment the PC

    mov     r5, r1                 # extract the src register num (r5)
    bperm   r5, r5, 0x4442
    and     r5, r0, 0x000f

    mov     r6, r1                 # extract the dst register num (r6)
    bperm   r6, r6, 0x4442
    ror     r6, r6
    ror     r6, r6
    ror     r6, r6
    ror     r6, r6
    and     r6, r0, 0x000f

    sto     r4, r0, reg_state_pc   # save the updated program counter which
                                   # will now point to the next instruction

    ld      r7, r5, reg_state      # load the src register value
    ld      r8, r6, reg_state      # load the dst register value

    mov     r3, r1                 # extract the opcode
    bperm   r3, r3, 0x4443         # move it into the low byte
    and     r3, r0, 0x1f           # mask off the predicate bits
    cmp     r3, r0, 0x1d           # test for long move, long load, long store
    c.mov   pc, r0, ss_skip_src_rewrite

    # Handle JSR
    # opcode 0x0C = JSR rd, rs, imm16
    # opcode 0x1C = JSR rd, imm20
    #
    # We need to calculate the EA into r2, and then rewrite the instruction
    # as a long jsr to this EA

    mov     r2, r1                 # initialize the EA from the instruction

    cmp     r3, r0, 0x1c
    z.mov   pc, r0, ss_long_jsr
    cmp     r3, r0, 0x0c
    nz.mov  pc, r0, ss_not_jsr

ss_short_jsr:
    movt    r2, r0                 # Clear bits 31..16 of the EA
    add     r2, r7                 # add the source register to the EA
    mov     pc, r0, ss_rewrite_jsr

ss_long_jsr:
    bperm   r3, r1, 0x4442         # Extract just imm19:16
    and     r3, r1, 0x000F         # into r3
    movt    r2, r3                 # and move back to the top of the EA

ss_rewrite_jsr:
    # At this point, all we need to retain from the original instruction is the predicate
    #
    #
    bperm   r3, r1, 0x4443
    and     r3, r0, 0x00e0
    or      r3, r0, 0x001c
    bperm   r3, r3, 0x0444         # so now r3 is p.ljsr

    mov     r1, r0, (ss_jsr_taken & 0xffff)
    movt    r1, r0, ((ss_jsr_taken >> 16) & 0x000f)
    add     r1, r3                 # add back in the predicate and opcode
    mov     pc, r0, ss_skip_src_rewrite

ss_not_jsr:

    bperm   r1, r1, 0x1032         # swap top/bottom 16 bits
    and     r1, r0, 0xfffffff0     # patch the instruction so:
    or      r1, r0, 0x00000007     # src = r7
    bperm   r1, r1, 0x1032         # swap top/bottom 16 bits back

ss_skip_src_rewrite:

    bperm   r1, r1, 0x1032         # swap top/bottom 16 bits
    and     r1, r0, 0xffffff0f     # patch the instruction so:
    or      r1, r0, 0x00000080     # dst = r8
    bperm   r1, r1, 0x1032         # swap top/bottom 16 bits back

    sto     r1, r0, ss_instruction # write the patched instruction

    mov     r1, r9                 # print state done here to be identical to the emulator
    PUSH    (r2)
    JSR     (ss_print_state)
    POP     (r2)

    ld      r9, r0, reg_state_psr  # load the s (bit 2), c (bit 1) and z (bit 0) flags

    PUTPSR  (r9)                   # load the flags

ss_instruction:
    WORD    0x00000000             # emulated instruction patched here

    GETPSR  (r9)                   # save the flags

    cmp     r6, r0, 15             # was the destination register r15
    nz.sto  r9, r0, reg_state_psr  # no, then save the flags

    cmp     r6, r0                 # was the destination register r0
    nz.sto  r8, r6, reg_state      # no, then save the new dst register value

ss_next_instruction:
    DEC     (r10, 1)               # decrement the iteration count
    nz.mov  pc, r0, ss_loop        # and loop back for more instructions

    ld      r1, r0, reg_state_pc
    JSR     (ss_print_state)       # print the final state

    POP     (r13)

    RTS     ()

ss_jsr_taken:
    sto     r4, r6, reg_state      # store the current PC in the specified link register

    cmp     r2, r0, OSWRCH         # EA = oswrch?
    nz.mov  pc, r0, ss_not_oswrch

    ld      r1, r0, reg_state_r1   # emulate oswrch
    JSR     (OSWRCH)
    mov     pc, r0, ss_next_instruction

ss_not_oswrch:
    mov     r4, r2                 # update the PC to the calculated effective address
    sto     r4, r0, reg_state_pc   # save the updated PC
    mov     pc, r0, ss_next_instruction

##endif
