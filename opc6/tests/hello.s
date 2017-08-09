    # demonstrate character output

    ORG   0x0000

    mov       r1, r0, 48      # start with a '0'
    mov       r2, r0, 43      # 43 characters takes us to 'Z'


    # convenience constants for best size and speed
    mov       r3, r0, 1
    mov       r4, r0, 0xfe09  # the output device (like Acorn's BBC Micro)
    mov       r5, r0, LOOP
    mov       r6, r0, -1

LOOP:
    out       r1, r4
    add       r1, r3
    add       r2, r6
    nz.mov    pc, r5

DONE:
    halt       r0,r0,0x321
