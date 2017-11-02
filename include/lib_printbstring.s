##ifndef _LIB_PRINTBSTRING_S

##define _LIB_PRINTBSTRING_S

# --------------------------------------------------------------
#
# print_bstring
#
# Prints the zero terminated ASCII bstring
#
# Entry:
# - r1 points to the zero terminated bstring
#
# Exit:
# - all other registers preserved
#
# TODO: This needs re-writing to be more space efficient with OPC7

print_bstring:
    PUSH    (r13)
    PUSH    (r1)
    PUSH    (r2)
    mov     r2, r1

print_bstring_loop:
    ld      r1, r2
    and     r1, r0, 0xff
    z.mov   pc, r0, print_bstring_exit
    JSR     (OSWRCH)
    ld      r1, r2
    BROT    (r1, r1)
    and     r1, r0, 0xff
    z.mov   pc, r0, print_bstring_exit
    JSR     (OSWRCH)
##ifdef CPU_OPC7
    ld      r1, r2
    BROT    (r1, r1)
    BROT    (r1, r1)
    and     r1, r0, 0xff
    z.mov   pc, r0, print_bstring_exit
    JSR     (OSWRCH)
    ld      r1, r2
    BROT    (r1, r1)
    BROT    (r1, r1)
    BROT    (r1, r1)
    and     r1, r0, 0xff
    z.mov   pc, r0, print_bstring_exit
    JSR     (OSWRCH)
##endif 
    mov     r2, r2, 0x0001
    mov     pc, r0, print_bstring_loop

print_bstring_exit:
    POP     (r2)
    POP     (r1)
    POP     (r13)
    RTS     ()
        
##endif
