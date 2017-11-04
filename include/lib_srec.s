##ifndef _LIB_SREC_S

##define _LIB_SREC_S

##include "lib_readhex.s"

# --------------------------------------------------------------

# Load a chunk of data in srecord format: see
#    man srec_motorola
# Only rudimentary error handling and consistency checking
#
# May or may not implement the RUN type of record
# (we begin with the minimum: S1 records)
#
# Typical minimal srecord input:
#   S123204065640DEA204F20446F6E65210DEA606885F66885F79848A000F00320E3FFE6F617
#   S1122060D002E6F7B1F6C9EAD0F168A86CF60031
# (lines up to 74 characters, 10 chars of overhead, that's max 32 bytes of payload)
#
# S1 Format is a data packet with a 16-bit address
#   <whitespace>
#   <line end>
#   Sn     where n=1
#   LL     two hex chars of length: number of bytes in remainder of this record
#   AAAA   four hex chars of address
#   BB<*>  many pairs of hex chars, the data to be stored
#   CC     two hex chars, a checksum
#   <line end>
#   <whitespace>
#
# Entry:
#
# Exit:
# - r1 = 0 (success), 1 (escape), 2 (checksum error), 3 (bad format error)
# - r2, r3, r4, r5, r6 corrupted

srec_load:
    PUSH    (r13)

    mov     r4, r0, -1              # initialize address to 0xffff meaning not yet set

srec_line_loop:
    mov     r1, r0
    mov     r2, r0, srec_osword0_param_block
    JSR     (OSWORD)                # read a line of input into INPBUF
    c.mov   pc, r0, srec_exit_escape

    mov     r1, r0, INPBUF

    JSR     (skip_spaces)           # remove leading spaces, last char read in r2

    cmp     r2, r0, ord('S')
    nz.mov  pc, r0, srec_exit_ok
    INC     (r1, 1)

    ld      r2, r1                  # test for 1
    cmp     r2, r0, ord('1')
    nz.mov  pc, r0, srec_exit_bad_format
    INC     (r1, 1)

    JSR     (read_hex_2)            # r2 = LL
    c.mov   pc, r0, srec_exit_bad_format
    mov     r3, r2                  # LL now held in r3
    mov     r5, r2                  # initialize checksum to LL

    JSR     (read_hex_4)            # r2 = AAAA
    c.mov   pc, r0, srec_exit_bad_format

    cmp     r4, r0, -1              # test if address not set
    z.mov   r4, r2                  # AAAA now held in r4

    add     r5, r2                  # accumulate AAAA in checksum
    BROT    (r2, r2)
    add     r5, r2

    DEC     (r3, 3)
    CLC     ()
    ror     r3, r3                  # convert to words
    c.mov   pc, r0, srec_exit_bad_format    # length expected to be even because we are a word based machine
##ifdef CPU_OPC7
    ror     r3, r3                  # convert to words (4 bytes)
    c.mov   pc, r0, srec_exit_bad_format    # length expected to be even because we are a word based machine
##endif

srec_word_loop:
    # the transmission order is little endian (i.e LSB first)
##ifdef CPU_OPC7
    JSR     (read_hex)              # r2 = BBBBBBBB
    c.mov   pc, r0, srec_exit_bad_format

    mov     r6, r2
    add     r5, r2                  # accumulate LSB in checksum
    BROT    (r2, r2)
    add     r5, r2                  # accumulate in checksum
    BROT    (r2, r2)
    add     r5, r2                  # accumulate in checksum
    movt    r2, r2
    BROT    (r2, r2)
    add     r5, r2                  # accumulate MSB checksum
    movt    r6, r6
    BROT    (r6, r6)
    movt    r2, r6
##else
    JSR     (read_hex_4)            # r2 = BBBB
    c.mov   pc, r0, srec_exit_bad_format

    add     r5, r2                  # accumulate BBBB in checksum
    BROT    (r2, r2)
    add     r5, r2
##endif

    sto     r2, r4                  # store the word


    INC     (r4,1)                  # increment the address pointer
    DEC     (r3,1)
    nz.mov  pc, r0, srec_word_loop

    JSR     (read_hex_2)            # r2 = 00CC
    add     r5, r2, 1               # accumulate CC and 01
    and     r5, r0, 0xff            # result in bits 7..0 should now be zero

    nz.mov  pc, r0, srec_exit_checksum

    mov     pc, r0, srec_line_loop

srec_exit_ok:
    mov     r1, r0

srec_exit:
    POP     (r13)
    RTS     ()

srec_exit_escape:
    mov     r1, r0, 1
    mov     pc, r0, srec_exit

srec_exit_checksum:
    mov     r1, r0, 2
    mov     pc, r0, srec_exit

srec_exit_bad_format:
    mov     r1, r0, 3
    mov     pc, r0, srec_exit

srec_osword0_param_block:
    WORD INPBUF
    WORD INPEND - INPBUF
    WORD 0x20
    WORD 0xFF

##endif
