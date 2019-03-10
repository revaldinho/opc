        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        mov      r1,r0
        mov      r2,r0,1
        lmov      r4,r0,results
        lmov      r5,r0, 0x7FFF
j0001:
        mov      r3,r2
        lcmp     r3,r5          # make sequence bail out in same place as 16 b version
        pl.mov    pc,pc,endFibbonaci-PC
        add      r3,r1
        sto      r1,r4
        add      r4,r0,1
        mov      r1,r2
        mov      r2,r3
        mov      pc,pc,j0001-PC
endFibbonaci:
        sto      r1,r4
        sto      r2,r4,1
endFibbonaci2:
        halt    r0,r0,0x99

        ORG 0x100
results:
