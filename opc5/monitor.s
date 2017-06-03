MACRO JSR( _address_)
   ld.i     r13, pc, 0x0005
   sto      r13, r14
#   ld.i    r14, r14, 0xffff
   add.i    r14, r0, 0xffff
   ld.i     pc,  r0, _address_
ENDMACRO

MACRO RTS()
    ld.i    r14, r14, 0x0001
    ld      pc, r14
ENDMACRO

ORG 0x0000

test:
    ld.i    r14, r0, 0x07ff
    ld.i    r12, r0, 0xfe09
 
    ld.i    r1, r0, 0x41
    JSR     (oswrch)

    ld.i    r1, r0, 0x42
    JSR     (oswrch)

    JSR     (osnewl)

    JSR     (print_string)

    WORD 0x4f,0x50,0x43,0x35,0x20,0x4d,0x6f,0x6e,0x69,0x74,0x6f,0x72,0x00

halt:
    ld.i    r0, r0

osnewl:
    ld.i    r1, r0, 0x0a
    JSR     (oswrch)

    ld.i    r1, r0, 0x0d    
    # fall through to oswrch
           
oswrch:
    sto     r1, r12
    RTS     ()

print_string:
    ld.i    r14, r14, 0x0001
    ld      r2, r14

ps_loop:
    ld      r1, r2
    z.ld.i  pc, r0, ps_exit
    JSR     (oswrch)
    ld.i    r2, r2, 0x0001
    ld.i    pc, r0, ps_loop

ps_exit:
    ld.i    pc, r2, 0x0001
    
