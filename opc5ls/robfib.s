        #
        # Port of Rob's fib program on his Butterfly machine
        #
        # http://anycpu.org/forum/viewtopic.php?f=3&t=376&start=60
        #
reset:
        mov      r11, r0, 1             # r11 = constant 1 for quick incrementing
        mov      r12, r0, endFibbonaci  # stash label in r12
        mov      r13, r0, j0001         # stash label in r13
        mov      r1,r0
        mov      r2,r11   
        mov      r4,r0,results
j0001:
        mov      r3,r2
        add      r3,r1
        cmp      r3,r0,0x8000
        c.mov    pc,r12                 # r12=endFibbonaci
        sto      r1,r4
        add      r4,r11
        mov      r1,r2
        mov      r2,r3
        mov      pc,r13                 # r13=j0001
endFibbonaci:
        sto      r1,r4
        sto      r2,r4,1
        sto      r3,r4,2
endFibbonaci2:
        halt    r0,r0,0x999

        ORG 0x100
results:
        
