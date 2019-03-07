MACRO   CLC()
        c.add r0,r0
ENDMACRO

MACRO   PUSH( _data_)
        sto     _data_, r14
        mov    r14, r14, 0xffffff
ENDMACRO

MACRO   POP( _data_ )
        mov    r14, r14, 0x01
        ld     _data_, r14
ENDMACRO
        
MACRO   SEC()
        nc.ror     r0,r0,1
ENDMACRO

MACRO   ASL( _reg_ )
        add     _reg_, _reg_
ENDMACRO

MACRO   ROL( _reg_ )
        rol   _reg_, _reg_
ENDMACRO

MACRO   JSR ( _addr_ )
        ljsr r13, r0,  _addr_
ENDMACRO

MACRO   RTS ()
        mov     pc,r13
ENDMACRO

MACRO   PUSH6(ra,rb,rc,rd,re,rf)
        sto ra, r14
        sto rb, r14,-1
        sto rc, r14,-2
        sto rd, r14,-3
        sto re, r14,-4
        sto rf, r14,-5        
        mov r14, r14, -5        
ENDMACRO

MACRO   POP6(rf,re,rd,rc,rb,ra)
        mov r14, r14, 5
        ld  rf, r14, -5
        ld  re, r14, -4
        ld  rd, r14, -3
        ld  rc, r14, -2
        ld  rb, r14, -1
        ld  ra, r14, 0        
ENDMACRO
        
        
