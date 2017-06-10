        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        ld.i      r10, r0, 1             # r10 = constant 1 for quick incrementing
        ld.i      r11, r0, endFibbonaci  # r11 = label constant in inner loop
        ld.i      r12, r0, j0001         # r12 = label constant in inner loop
        ld.i      r1,r0
        ld.i      r2,r10
        ld.i      r4,r0,results
j0001:
        ld.i      r3,r2
        add.i     r3,r1
        c.ld.i    pc, r11               # r11 = endFibonacci
        sto       r1,r4
        add.i     r4,r10
        ld.i      r1,r2
        ld.i      r2,r3
        ld.i      pc,r12                # r12 = j0001
endFibbonaci:
        sto      r1,r4
        sto      r2,r4,1
endFibbonaci2:
        halt    r0,r0,0x999

        ORG 0x100
results:
