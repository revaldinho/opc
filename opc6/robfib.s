        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        mov      r1,r0
        mov      r2,r0,1
        mov      r4,r0,results
j0001:
        mov      r3,r2
        mi.mov    pc,r0,endFibbonaci     
        add      r3,r1
        sto      r1,r4
        add      r4,r0,1
        mov      r1,r2
        mov      r2,r3
        mov      pc,r0,j0001
endFibbonaci:
        sto      r1,r4
        sto      r2,r4,1
endFibbonaci2:
        halt    r0,r0,0x999

        ORG 0x100
results:
