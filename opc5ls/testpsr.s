MACRO   PUSH( _data_, _ptr_)
        sto   _data_,_ptr_
        add   _ptr_,r0,1
ENDMACRO


    mov r10,r0,results
    mov r1,r0    #set zero flag
    PUSH (r1,r10)
    psr r2,psr   #save psr
    PUSH (r2,r10)

    mov  pc, r0, L1
L2:
    psr  r4,psr
    PUSH (r4,r10)
    mov r1, r0, 0x8000
    add r1, r1        # set C flag
    psr r2, psr       #save flags
    PUSH (r2,r10)
    psr psr, r3       # restore flags
    psr psr, r2       # restore different flags
    psr r3, psr
    PUSH (r3,r10)
    halt r0,r0,0x999

L1: psr r3,psr
    PUSH (r3,r10)
    mov  pc, r0, L2


results:
