##ifndef _LIB_DUMPMEM_S

##define  _LIB_DUMPMEM_S

##include "lib_printhex.s"

# set line and block len to fit in 80 cols
# must be a power of two

##ifdef CPU_OPC7
EQU  LINE_LEN, 4
EQU BLOCK_LEN, 64
##else
EQU  LINE_LEN, 8
EQU BLOCK_LEN, 128
##endif

dump_mem:
    PUSH    (r13)
    mov     r4, r1
    mov     r3, r0

dump_mem_0:
    JSR     (OSNEWL)

    cmp     r3, r0, BLOCK_LEN
    c.mov   pc, r0, dump_mem_5

    mov     r1, r4
    add     r1, r3
    JSR     (print_hex_word_spc)

dump_mem_1:
    mov     r1, r4
    add     r1, r3
    ld      r1, r1
    JSR     (print_hex_word_spc)

    add     r3, r0, 1

    mov     r2, r3
    and     r2, r0, LINE_LEN - 1
    nz.mov  pc, r0, dump_mem_1

    sub     r3, r0, LINE_LEN

dump_mem_2:
    mov     r1, r4
    add     r1, r3
    ld      r1, r1
    and     r1, r0, 0x7F

    cmp     r1, r0, 0x20
    nc.mov  pc, r0, dump_mem_3
    cmp     r1, r0, 0x7F
    nc.mov  pc, r0, dump_mem_4

dump_mem_3:
    mov     r1, r0, ord('.')

dump_mem_4:
    JSR     (OSWRCH)
    add     r3, r0, 1
    mov     r2, r3
    and     r2, r0, LINE_LEN - 1
    nz.mov  pc, r0, dump_mem_2
    mov     pc, r0, dump_mem_0

dump_mem_5:
    mov    r1, r4
    add    r1, r3
    POP    (r13)
    RTS    ()

##endif
