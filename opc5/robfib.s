        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        ld.i      r1,r0
        ld.i      r2,r0,1
        ld.i      r4,r0,results
j0001:
        ld.i      r3,r2
        add.i     r3,r1
        c.ld.i    pc, r0, endFibbonaci
        sto       r1,r4
        add.i     r4,r0,1
        ld.i      r1,r2
        ld.i      r2,r3
        ld.i      pc,r0,j0001
endFibbonaci:
        sto      r1,r4
        sto      r2,r4,1
endFibbonaci2:
        halt    r0,r0,0x999

        ORG 0x100
results:
