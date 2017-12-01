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

ss_step:

    PUSH    (r13)

    mov     r10, r1, 1             # iteration count + 1

ss_loop:
    ld      r4, r0, reg_state_pc   # load the program counter
    mov     r9, r4                 # save the program counter of the current instruction
    ld      r1, r4                 # fetch the instruction
    INC     (r4,1)                 # increment the PC

    mov     r5, r1                 # extract the src register num (r5)
    ror     r5, r5
    ror     r5, r5
    ror     r5, r5
    ror     r5, r5
    and     r5, r0, 0x000F

    mov     r6, r1                 # extract the dst register num (r6)
    and     r6, r0, 0x000F

    ld      r2, r0, ss_nop         # by default the operand slot is filled with a nop
    sto     r2, r0, ss_operand     # store the operand

    mov     r2, r1
    and     r2, r0, 0x1000         # test for an operand
    z.mov   pc, r0, ss_no_operand  # r2 zero if no operand, which is correct

    ld      r2, r4                 # fetch the operand
    sto     r2, r0, ss_operand     # store back the operand, and leave it in r2
    INC     (r4,1)                 # increment the PC

ss_no_operand:
    sto     r4, r0, reg_state_pc   # save the updated program counter which
                                   # will now point to the next instruction

    ld      r7, r5, reg_state      # load the src register value
    ld      r8, r6, reg_state      # load the dst register value

    # Emulate JSR instruction
    # r1 = instruction, r2 = operand

    mov     r3, r1                 # extract the predicate
    and     r3, r0, 0xe000
    cmp     r3, r0, 0x2000
    z.mov   pc, r0, ss_not_jsr     # never predicate present, so not a jsr

    mov     r3, r1                 # extract the opcode
    and     r3, r0, 0x0f00
    cmp     r3, r0, 0x0c00         # test for inc
    z.mov   pc, r0, ss_skip_src_rewrite
    cmp     r3, r0, 0x0e00         # test for dec
    z.mov   pc, r0, ss_skip_src_rewrite

    cmp     r3, r0, 0x0900         # test for jsr
    nz.mov  pc, r0, ss_not_jsr

    or      r1, r0, 0x1000         # patch the instruction to always have an operand
    mov     r3, r0, ss_jsr_taken
    sto     r3, r0, ss_operand     # patch the operand to be the jsr_taken routine

    add     r2, r7                 # pass EA to jsr_taken by adding the source register (r7) value to the operand (r2)

ss_not_jsr:

    and     r1, r0, 0xff0f         # patch the instruction so:
    or      r1, r0, 0x0070         # src = r7

ss_skip_src_rewrite:
    and     r1, r0, 0xfff0         # patch the instruction so:
    or      r1, r0, 0x0008         # dst = r8

    sto     r1, r0, ss_instruction # write the patched instruction

    mov     r1, r9                 # print state done here to be identical to the emulator
    PUSH    (r2)
    JSR     (ss_print_state)
    POP     (r2)

    ld      r9, r0, reg_state_psr  # load the s (bit 2), c (bit 1) and z (bit 0) flags

    PUTPSR  (r9)                   # load the flags

ss_instruction:
    WORD    0x0000                 # emulated instruction patched here

ss_operand:
    WORD    0x0000                 # emulated opcode patched here

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

ss_nop:
    z.and   r0, r0

ss_jsr_taken:
    sto     r4, r6, reg_state      # store the current PC in the specified link register

    cmp     r2, r0, 0xffee         # EA = oswrch?
    nz.mov  pc, r0, ss_not_oswrch

    ld      r1, r0, reg_state_r1   # emulate oswrch
    JSR     (OSWRCH)
    mov     pc, r0, ss_next_instruction

ss_not_oswrch:
    mov     r4, r2                 # update the PC to the calculated effective address
    sto     r4, r0, reg_state_pc   # save the updated PC
    mov     pc, r0, ss_next_instruction

##endif
