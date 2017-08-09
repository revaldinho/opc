


    mov   r1,r0,1
    inc   r1,10
    inc   pc,L1-PC
    mov   r0,r0

L1: mov r1, r0,-10

L2:
    inc r1,1
    nz.dec pc,PC-L2


    halt r0,r0,0
