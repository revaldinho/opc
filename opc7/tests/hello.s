    # demonstrate character output

    ORG   0x0000

    lmov    r1,48      # start with a '0'
    lmov    r2,43      # 43 characters takes us to 'Z'


    # convenience constants for best size and speed
    lmov    r3,1
    lmov    r4,0xfe09  # the output device (like Acorn's BBC Micro)
    lmov    r5,LOOP
    lmov    r6,-1

LOOP:
    out       r1, r4
    add       r1, r3
    add       r2, r6
    nz.mov    pc, r5

DONE:
    halt       r0,r0,0x321
