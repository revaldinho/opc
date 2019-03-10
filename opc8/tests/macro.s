
MACRO BROL (_rd_, _rs_ )
        brol _rd_,_rs_,0        
ENDMACRO

MACRO BROR (_rd_, _rs_ )
        bror _rd_,_rs_,0        
ENDMACRO

        
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

MACRO   JSR_CC ( _cond_, _addr_ )
        _cond_.mov  r13, pc, +2
        _cond_.lmov pc, r0, _addr_
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
        
MACRO   PUSHALL()
        mov     r14,r14, -9
        sto     r5, r14, 1
        sto     r6, r14, 2
        sto     r7, r14, 3
        sto     r8, r14, 4
        sto     r9, r14, 5
        sto     r10, r14, 6
        sto     r11, r14, 7
        sto     r12, r14, 8
        sto     r13, r14, 9                        
ENDMACRO

MACRO   POPALL()
        ld      r5, r14, 1
        ld      r6, r14, 2
        ld      r7, r14, 3
        ld      r8, r14, 4
        ld      r9, r14, 5
        ld      r10, r14, 6
        ld      r11, r14, 7
        ld      r12, r14, 8
        ld      r13, r14, 9
        mov     r14, r14, 9
ENDMACRO


MACRO   SPRINT( _str_addr_, _eol_ )
        lmov    r1, r0, _str_addr_
        lmov    r2,r0, _eol_
        JSR (sprint)
ENDMACRO
        
