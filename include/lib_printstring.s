##ifndef _LIB_PRINTSTRING_S

##define _LIB_PRINTSTRING_S

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
    PUSH    (r13)
    mov     r2, r1

print_string_loop:
    ld      r1, r2
    and     r1, r0, 0xff
    z.mov   pc, r0, print_string_exit
    JSR     (OSWRCH)
    mov     r2, r2, 0x0001
    mov     pc, r0, print_string_loop

print_string_exit:
    POP     (r13)
    POP     (r2)
    RTS     ()
        
##endif
