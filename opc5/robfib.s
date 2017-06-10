        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        ld.i      r10, r0, 1             # r10 = constant 1 for quick incrementing
        ld.i      r11, r0, 0x8000        # r11 = const used in inner loop
        
        ld.i      r1,r0
        ld.i      r2,r10   
        ld.i      r4,r0,results
j0001:
        ld.i      r3,r2
        add.i     r3,r1
        add.i     r3,r3                  # rol to get sign bit into carry
        c.ld.i    pc,r0,endFibbonaci     # if >= 0x8000 then exit
        ror.i     r3,r3                  # restore r3
        sto       r1,r4
        add.i     r4,r10
        ld.i      r1,r2
        ld.i      r2,r3
        ld.i      pc,r0,j0001
endFibbonaci:
        ror.i     r3,r3                  # restore r3        
        sto      r1,r4
        sto      r2,r4,1
        sto      r3,r4,2
endFibbonaci2:
        halt    r0,r0,0x999

        ORG 0x100
results:
        
