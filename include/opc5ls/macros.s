# -----------------------------------------------------------------------------
# Macros
# -----------------------------------------------------------------------------

# set the cpu type to support conditional assembly
##define CPU_OPC5LS

EQU     EI_MASK, 0x0008
EQU    SWI_MASK, 0x00F0
EQU   SWI0_MASK, 0x0010
EQU   SWI1_MASK, 0x0020
EQU   SWI2_MASK, 0x0040
EQU   SWI3_MASK, 0x0080
        
MACRO   CPU_STRING()
    STRING "OPC5LS"
ENDMACRO

MACRO   CPU_BSTRING()
    BSTRING "OPC5LS"
ENDMACRO

MACRO   CLC()
    c.add r0,r0
ENDMACRO

MACRO   SEC()
    nc.ror r0,r0,1
ENDMACRO

MACRO   GETPSR(_reg_)
    psr     _reg_, psr
ENDMACRO

MACRO   PUTPSR(_reg_)
    psr     psr, _reg_
ENDMACRO

MACRO   SWI0() {
    psr     psr, r0, SWI0_MASK
ENDMACRO
        
MACRO   SWI1() {
    psr     psr, r0, SWI1_MASK
ENDMACRO
        
MACRO   SWI2() {
    psr     psr, r0, SWI2_MASK
ENDMACRO
        
MACRO   SWI3() {
    psr     psr, r0, SWI3_MASK
ENDMACRO
        
MACRO   EI()
    GETPSR  (r12)
    or      r12, r12, EI_MASK
    PUTPSR  (r12)
ENDMACRO

MACRO   DI()
    GETPSR  (r12)
    and     r12, r12, ~EI_MASK
    PUTPSR  (r12)
ENDMACRO

MACRO JSR( _address_)
    mov     r13, pc, 0x0002
    mov     pc,  r0, _address_
ENDMACRO

MACRO RTS()
    mov     pc, r13
ENDMACRO

MACRO   PUSH( _data_)
    mov     r14, r14, -1
    sto     _data_, r14, 1
ENDMACRO

MACRO   POP( _data_ )
    ld      _data_, r14, 1
    mov     r14, r14, 1
ENDMACRO

MACRO   IN(_reg_, _address_)
    ld      _reg_, r0, _address_
ENDMACRO
        
MACRO   OUT(_reg_, _address_)
    sto     _reg_, r0, _address_
ENDMACRO
