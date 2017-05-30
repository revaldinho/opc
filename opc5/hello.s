    # demonstrate character output

    ORG   0x0000

    ld.i       r1, r0, 48      # start with a '0'
    ld.i       r2, r0, 43      # 43 characters takes us to 'Z'


    # convenience constants for best size and speed
    ld.i       r3, r0, 1
    ld.i       r4, r0, 0xfe09  # the output device (like Acorn's BBC Micro)
    ld.i       r5, r0, LOOP
    ld.i       r6, r0, -1

LOOP:
    sto        r1, r4
    add.i      r1, r3
    add.i      r2, r6
    nz.ld.i    pc, r5

DONE:
    halt       r0,r0,0x321
