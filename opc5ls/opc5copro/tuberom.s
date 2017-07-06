EQU        BASE, 0xE000
EQU        CODE, 0xF800

EQU       STACK, CODE - 1
EQU     MEM_BOT, 0x0400
EQU     MEM_TOP, CODE - 1

EQU NUM_VECTORS, 27           # number of vectors in DefaultVectors table

EQU        ADDR, 0x00F6       # tube execution address
EQU      TMP_R1, 0x00FC       # tmp store for R1 during IRQ
EQU    LAST_ERR, 0x00FD       # last error
EQU ESCAPE_FLAG, 0x00FF       # escape flag

EQU       USERV, 0x0200
EQU        BRKV, 0x0202
EQU       IRQ1V, 0x0204
EQU       IRQ2V, 0x0206
EQU        CLIV, 0x0208
EQU       BYTEV, 0x020A
EQU       WORDV, 0x020C
EQU       WRCHV, 0x020E
EQU       RDCHV, 0x0210
EQU       FILEV, 0x0212
EQU       ARGSV, 0x0214
EQU       BGETV, 0x0216
EQU       BPUTV, 0x0218
EQU       GBPBV, 0x021A
EQU       FINDV, 0x021C
EQU        FSCV, 0x021E
EQU       EVNTV, 0x0220

EQU      ERRBUF, 0x0236
EQU      INPBUF, 0x0236
EQU      INPEND, 0x0300

EQU     EI_MASK, 0x0008
EQU    SWI_MASK, 0x00F0
EQU   SWI0_MASK, 0x0010
EQU   SWI1_MASK, 0x0020
EQU   SWI2_MASK, 0x0040
EQU   SWI3_MASK, 0x0080

# -----------------------------------------------------------------------------
# Macros
# -----------------------------------------------------------------------------

MACRO   CLC()
    c.add r0,r0
ENDMACRO

MACRO   SEC()
    nc.ror r0,r0,1
ENDMACRO

MACRO   EI()
    psr     r12, psr
    or      r12, r12, EI_MASK
    psr     psr, r12
ENDMACRO

MACRO   DI()
    psr     r12, psr
    and     r12, r12, ~EI_MASK
    psr     psr, r12
ENDMACRO

MACRO JSR( _address_)
    mov     r13, pc, 0x0002
    mov     pc,  r0, _address_
ENDMACRO

MACRO RTS()
    mov     pc, r13
ENDMACRO

MACRO   PUSH( _data_)
    mov     r14, r14, -1
    sto     _data_, r14, 1
ENDMACRO

MACRO   POP( _data_ )
    ld      _data_, r14, 1
    mov     r14, r14, 1
ENDMACRO

MACRO ERROR (_address_)
    mov     r1, r0, _address_
    psr     psr, r0, SWI0_MASK
ENDMACRO

# -----------------------------------------------------------------------------
# 8K Rom Start
# -----------------------------------------------------------------------------

// These end up at 0x0000 and get used by the Real Co Pro
ORG BASE
    mov      pc, r0, ResetHandler
    mov      pc, r0, InterruptHandler

ORG CODE

ResetHandler:
    mov     r14, r0, STACK              # setup the stack

    mov     r2, r0, NUM_VECTORS         # copy the vectors
    mov     r3, r0, NUM_VECTORS * 2
InitVecLoop:
    ld      r1,  r2, DefaultVectors
    sto     r1,  r3, USERV
    sub     r3,  r0, 2
    sub     r2,  r0, 1
    pl.mov  pc,  r0, InitVecLoop

    EI      ()                          # enable interrupts

    mov     r1, r0, BannerMessage       # send the reset message
    JSR     (PrintString)

    mov     r1, r0                      # send the terminator
    JSR     (OSWRCH)

    JSR     (WaitByteR2)                # wait for the response and ignore

CmdPrompt:

CmdOSLoop:
    mov     r1, r0, 0x2a
    JSR     (OSWRCH)

    mov     r1, r0
    mov     r2, r0, osword0_param_block
    JSR     (OSWORD)
    c.mov   pc, r0, CmdOSEscape

    mov     r1, r0, INPBUF
    JSR     (OS_CLI)
    mov     pc, r0, CmdOSLoop

CmdOSEscape:
    mov     r1, r0, 0x7e
    JSR     (OSBYTE)
    ERROR   (EscapeError)

# --------------------------------------------------------------
# MOS interface
# --------------------------------------------------------------

NullReturn:
    RTS     ()

# --------------------------------------------------------------

Unsupported:
    RTS     ()

# --------------------------------------------------------------

ErrorHandler:

    mov     r14, r0, STACK              # Clear the stack

    JSR     (OSNEWL)
    ld       r1, r0, LAST_ERR           # Address of the last error: <error num> <err string> <00>
    add      r1, r0, 1                  # Skip over error num
    JSR     (PrintString)               # Print error string
    JSR     (OSNEWL)

    mov     pc, r0, CmdPrompt           # Jump to command prompt

# --------------------------------------------------------------

osARGS:
    # TODO
    RTS     ()

# --------------------------------------------------------------

osBGET:
    # TODO
    RTS     ()

# --------------------------------------------------------------

osBPUT:
    # TODO
    RTS     ()

# --------------------------------------------------------------

# OSBYTE - Byte MOS functions
# ===========================
# On entry, r1, r2, r3=OSBYTE parameters
# On exit,  r1  preserved
#           If r1<$80, r2=returned value
#           If r1>$7F, r2, r3, Carry=returned values
#
osBYTE:
    PUSH    (r13)
    cmp     r1, r0, 0x80        # Jump for long OSBYTEs
    c.mov   pc, r0, ByteHigh
#
# Tube data  $04 X A    --  X
#
    PUSH    (r1)
    mov     r1, r0, 0x04        # Send command &04 - OSBYTELO
    JSR     (SendByteR2)
    mov     r1, r2
    JSR     (SendByteR2)        # Send single parameter
    POP     (r1)
    PUSH    (r1)
    JSR     (SendByteR2)        # Send function
    JSR     (WaitByteR2)        # Get return value
    mov     r1, r2
    POP     (r1)
    POP     (r13)
    RTS     ()

ByteHigh:
    cmp     r1, r0, 0x82        # Read memory high word
    z.mov   pc, r0, Byte82
    cmp     r1, r0, 0x83        # Read bottom of memory
    z.mov   pc, r0, Byte83
    cmp     r1, r0, 0x84        # Read top of memory
    z.mov   pc, r0, Byte84
#
# Tube data  $06 X Y A  --  Cy Y X
#

    PUSH    (r1)
    mov     r1, r0, 0x06
    JSR     (SendByteR2)        # Send command &06 - OSBYTEHI
    mov     r2, r1
    JSR     (SendByteR2)        # Send parameter 1
    mov     r3, r1
    JSR     (SendByteR2)        # Send parameter 2
    POP     (r1)
    PUSH    (r1)
    JSR     (SendByteR2)        # Send function
#   cmp     r1, r0, 0x8e        # If select language, check to enter code
#   z.mov   pc, r0, CheckAck
    cmp     r1, r0, 0x9d        # Fast return with Fast BPUT
    z.mov   pc, r0, FastReturn
    JSR     (WaitByteR2)        # Get carry - from bit 7
    add     r1, r0, 0xff80
    JSR     (WaitByteR2)        # Get high byte
    mov     r1, r3
    JSR     (WaitByteR2)        # Get low byte
    mov     r1, r2
FastReturn:
    POP     (r1)                # restore original r1
    POP     (r13)
    RTS     ()

Byte84:                         # Read top of memory
    mov      r1, r0, MEM_TOP
    POP     (r13)
    RTS     ()
Byte83:                         # Read bottom of memory
    mov     r1, r0, MEM_BOT
    POP     (r13)
    RTS     ()

Byte82:                         # Return &0000 as memory high word
    mov     r1, r0
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

# OSCLI - Send command line to host
# =================================
# On entry, r1=>command string
#
# Tube data  &02 string &0D  --  &7F or &80
#

osCLI:
    PUSH    (r13)
    PUSH    (r2)

    PUSH    (r1)                    # save the string pointer
    JSR     (cmdLocal)              # try to handle the command locally
    cmp     r1, r0                  # was command handled locally? (r1 = 0)
    z.mov   pc, r0, dontEnterCode   # yes, then nothing more to do
    POP     (r1)                    # restore the string pointer

    PUSH    (r1)                    # save the string pointer
    mov     r2, r1
    mov     r1, r0, 0x02            # Send command &02 - OSCLI
    JSR     (SendByteR2)
    JSR     (SendStringR2)          # Send string pointed to by r2

osCLI_Ack:
    JSR     (WaitByteR2)
    cmp     r1, r0, 0x80
    nc.mov  pc, r0, dontEnterCode

    JSR     (enterCode)

dontEnterCode:
    POP     (r1)

    POP     (r2)
    POP     (r13)
    RTS     ()

enterCode:
    ld      pc, r0, ADDR

# --------------------------------------------------------------
# Local Command Processor
#
# On Entry:
# - r1 points to the user command
#
# On Exit:
# - r1 == 0 if command successfully processed locally
# - r1 != 0 if command should be
#
# Register usage:
# r1 points to start of user command
# r2 points within command table
# r3 points within user command
# r4 is current character in command table
# r5 is current character in user command

cmdLocal:
    PUSH    (r2)
    PUSH    (r3)
    PUSH    (r4)
    PUSH    (r5)
    PUSH    (r13)

    JSR     (SkipSpaces)

    mov     r2, r0, cmdTable-1      # initialize command table pointer (to char before)

cmdLoop1:
    mov     r3, r1, 0xffff          # initialize user command pointer (to char before)

cmdLoop2:
    add     r2, r0, 1               # increment command table pointer
    add     r3, r0, 1               # increment user command pointer
    ld      r4, r2                  # read next character from command table
    mi.mov  pc, r0, cmdExec         # if an address, then we are done
    ld      r5, r3                  # read next character from user command
    or      r5, r0, 0x20            # convert to lower case
    cmp     r5, r4                  # compare the characters
    z.mov   pc, r0, cmdLoop2        # if a match, loop back for more

    sub     r2, r0, 1
cmdLoop3:                           # skip to the end of the command in the table
    add     r2, r0, 1
    ld      r4, r2
    pl.mov  pc, r0, cmdLoop3

    cmp     r5, r0, 0x2e            # was the mis-match a '.'
    nz.mov  pc, r0, cmdLoop1        # no, then start again with next command

cmdExec:

    mov     r1, r3                  # r1 = the command pointer to the params
    mov     r2, r4                  # r2 = the execution address

    JSR     (cmdExecR2)

    POP     (r13)
    POP     (r5)
    POP     (r4)
    POP     (r3)
    POP     (r2)
    RTS     ()

# --------------------------------------------------------------

cmdGo:
    PUSH   (r13)
    JSR    (ReadHex)
    JSR    (cmdExecR2)
    mov    r1, r0
    POP    (r13)
    RTS    ()

# --------------------------------------------------------------

cmdMem:
    PUSH    (r13)
    JSR     (ReadHex)
    mov     r5, r2
    mov     r3, r0

cmdMem0:
    JSR     (OSNEWL)

    cmp     r3, r0, 0x80
    c.mov   pc, r0, cmdMem5

    mov     r1, r5
    add     r1, r3
    JSR     (PrintHexSp)

cmdMem1:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    JSR     (PrintHexSp)

    add     r3, r0, 1

    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, cmdMem1

    sub     r3, r0, 0x08

cmdMem2:
    mov     r1, r5
    add     r1, r3
    ld      r1, r1
    and     r1, r0, 0x7F

    cmp     r1, r0, 0x20
    nc.mov  pc, r0, cmdMem3
    cmp     r1, r0, 0x7F
    nc.mov  pc, r0, cmdMem4

cmdMem3:
    mov     r1, r0, 0x2E

cmdMem4:
    JSR     (OSWRCH)
    add     r3, r0, 1
    mov     r2, r3
    and     r2, r0, 0x07
    nz.mov  pc, r0, cmdMem2
    mov     pc, r0, cmdMem0

cmdMem5:
    mov    r1, r0
    POP    (r13)
    RTS    ()

# --------------------------------------------------------------

cmdHelp:
    PUSH   (r13)
    mov    r1, r0, msgHelp
    JSR    (PrintString)
    mov    r1, r0, 1
    POP    (r13)
    RTS    ()

msgHelp:
    STRING   "OPC5LS 0.50"
    WORD     10, 13, 0

# --------------------------------------------------------------

cmdTest:
    PUSH   (r13)
    JSR    (ReadHex)
    mov    r1, r2
    JSR    (PrintHexSp)
    JSR    (PrintDec)
    JSR    (OSNEWL)
    mov    r1, r0
    POP    (r13)
    RTS    ()

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

cmdSrec:
    PUSH    (r13)

    mov     r4, r0, 0xffff          # initialize address to 0xffff meaning not yet set

cmdSrecLineLoop:
# read a line of input into INPBUF
    mov     r1, r0
    mov     r2, r0, osword0_param_block
    JSR     (OSWORD)
    c.mov   pc, r0, CmdOSEscape

    mov     r1, r0, INPBUF

    JSR     (SkipSpaces)            # remove leading spaces

    ld      r2, r1                  # test for S
    cmp     r2, r0, ord('S')
    nz.mov  pc, r0, cmdSrecExit
    add     r1, r0, 1

    ld      r2, r1                  # test for 1
    cmp     r2, r0, ord('1')
    nz.mov  pc, r0, cmdSrecError
    add     r1, r0, 1


    JSR     (ReadHex2)              # r2 = LL
    c.mov   pc, r0, cmdSrecError
    mov     r3, r2                  # LL now held in r3
    mov     r5, r2                  # initialize checksum to LL

    JSR     (ReadHex4)              # r2 = AAAA
    c.mov   pc, r0, cmdSrecError

    cmp     r4, r0, 0xffff          # test if address not set
    z.mov   r4, r2                  # AAAA now held in r4

    add     r5, r2                  # accumulate AAAA in checksum
    bswp    r2, r2
    add     r5, r2

    sub     r3, r0, 3
    CLC     ()
    ror     r3, r3                  # convert to words
    c.mov   pc, r0, cmdSrecError    # length expected to be even because we are a word based machine


cmdSrecWordLoop:

    JSR     (ReadHex4)              # r2 = BBBB
    c.mov   pc, r0, cmdSrecError

    add     r5, r2                  # accumulate BBBB in checksum
    bswp    r2, r2
    add     r5, r2

    sto     r2, r4                  # store the word
    add     r4, r0, 1               # increment the address pointer

    sub     r3, r0, 1
    nz.mov  pc, r0, cmdSrecWordLoop

    JSR     (ReadHex2)              # r2 = 00CC
    add     r5, r2, 1               # accumulate CC and 01
    and     r5, r0, 0xff            # result in bits 7..0 should now be zero

    nz.mov  pc, r0, cmdSrecChecksumError

    mov     pc, r0, cmdSrecLineLoop

cmdSrecExit:
    mov     r1, r0
    POP     (r13)
    RTS     ()

cmdSrecError:
    ERROR   (BadFormatError)

BadFormatError:
    WORD    17                    # TODO assign proper error code
    STRING "Bad Format"
    WORD    0x00

cmdSrecChecksumError:
    ERROR   (ChecksumError)

ChecksumError:
    WORD    17                    # TODO assign proper error code
    STRING "Checksum mismatch"
    WORD    0x00

# ---------------------------------------------------------

cmdEnd:
    mov    r1, r0, 1
    RTS    ()

# --------------------------------------------------------------

cmdExecR2:
    mov    pc, r2

# --------------------------------------------------------------

cmdTable:
    STRING  "."
    WORD    cmdEnd
    STRING  "go"
    WORD    cmdGo
    STRING  "mem"
    WORD    cmdMem
    STRING  "help"
    WORD    cmdHelp
    STRING  "test"
    WORD    cmdTest
    STRING  "srec"
    WORD    cmdSrec
    WORD    cmdEnd

# --------------------------------------------------------------
# Skip Spaces
#
# Entry:
# - r1 is the address of the string
#
# Exit:
# - r1 is updated to skip and spaces
# - all other registers preserved

SkipSpaces:
    PUSH    (r2)
    sub     r1, r0, 1
skipSpcLoop:
    add     r1, r0, 1
    ld      r2, r1
    cmp     r2, r0, 0x20
    z.mov   pc, r0, skipSpcLoop
    POP     (r2)
    RTS     ()

# --------------------------------------------------------------
#
# ReadHex
#
# Read a multi-digit hex value, terminated by a non hex character
#
# Entry:
# - r1 is the address of the hex string
#
# Exit:
# - r1 is updated after processing the string
# - r2 contains the hex value
#
# - all registers preserved

ReadHex:
    PUSH    (r13)
    JSR     (SkipSpaces)
    mov     r2, r0          # r2 is will contain the hex value

rh_loop:
    JSR     (ReadHex1)
    nc.mov  pc, r0, rh_loop
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# ReadHex2
#
# Read a 2-digit hex value
#
# Entry:
# - r1 is the address of the hex string
#
# Exit:
# - r1 is updated after processing the string
# - r2 contains the hex value
# - carry set if there was an error
# - all registers preserved

ReadHex2:
    PUSH    (r13)
    mov     r2, r0          # r2 is will contain the hex value
    JSR     (ReadHex1)
    JSR     (ReadHex1)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# ReadHex4
#
# Read a 4-digit hex value
#
# Entry:
# - r1 is the address of the hex string
#
# Exit:
# - r1 is updated after processing the string
# - r2 contains the hex value
# - carry set if there was an error
# - all registers preserved

ReadHex4:
    PUSH    (r13)
    mov     r2, r0          # r2 is will contain the hex value
    JSR     (ReadHex1)
    JSR     (ReadHex1)
    JSR     (ReadHex1)
    JSR     (ReadHex1)
    POP     (r13)
    RTS     ()

ReadHex1:
    PUSH    (r3)
    ld      r3, r1
    cmp     r3, r0, 0x30
    nc.mov  pc, r0, rh1_invalid
    cmp     r3, r0, 0x3A
    nc.mov  pc, r0, rh1_valid
    and     r3, r0, 0xdf
    sub     r3, r0, 0x07
    nc.mov  pc, r0, rh1_invalid
    cmp     r3, r0, 0x40
    c.mov   pc, r0, rh1_invalid

rh1_valid:
    add     r2, r2
    add     r2, r2
    add     r2, r2
    add     r2, r2

    and     r3, r0, 0x0F
    add     r2, r3

    add     r1, r0, 1
    CLC     ()
    mov     pc, r0, rh1_exit

rh1_invalid:
    SEC     ()

rh1_exit:
    POP     (r3)
    RTS     ()

# --------------------------------------------------------------
#
# PrintHexSp
#
# Prints a 4-digit hex value followed by a space
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

PrintHexSp:
    PUSH    (r13)
    JSR     (PrintHex)
    JSR     (PrintSpc)
    POP     (r13)
    RTS     ()

PrintSpc:
    PUSH    (r13)
    PUSH    (r1)
    mov     r1, r0, 0x20
    JSR     (OSWRCH)
    POP     (r1)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# PrintDecimal
#
# Prints a 16-bit value as decimal
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved


# PrintDec:
#     PUSH    (r13)
#     PUSH    (r1)
#     PUSH    (r2)
#     PUSH    (r3)
#     PUSH    (r4)
#
#     mov     r2, r1
#     mov     r3, r0, DecTable - 1
#
# PrintDec1:
#     add     r3, r0, 1
#     ld      r4, r3
#     z.mov   pc, r0, PrintDec4
#
#     mov     r1, r0, 0x30
# PrintDec2:
#     cmp     r2, r4
#     nc.mov  pc, r0, PrintDec3
#     add     r1, r0, 1
#     sub     r2, r4
#     mov     pc, r0, PrintDec2
#
# PrintDec3:
#     JSR     (osWRCH)
#     mov     pc, r0, PrintDec1
#
# PrintDec4:
#     POP     (r4)
#     POP     (r3)
#     POP     (r2)
#     POP     (r1)
#     POP     (r13)
#     RTS     ()
#
# DecTable:
#     WORD    10000, 1000, 100, 10, 1, 0


# digit = 0
#          if (a >= 40000) a = a - 40000; digit = digit + 4
# a = a*2; if (a >= 40000) a = a - 40000; digit = digit + 2
# a = a*2; if (a >= 40000) a = a - 40000; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 32000) a = a - 32000; digit = digit + 8
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 4
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 2
# a = a*2; if (a >= 32000) a = a - 32000; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 25600) a = a - 25600; digit = digit + 8
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 4
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 2
# a = a*2; if (a >= 25600) a = a - 25600; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 20480) a = a - 20480; digit = digit + 8
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 4
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 2
# a = a*2; if (a >= 20480) a = a - 20480; digit = digit + 1
# output character (digit ^ $30)
# digit = 0
#          if (a >= 16384) a = a - 16384; digit = digit + 8
# a = a*2; if (a >= 16384) a = a - 16384; digit = digit + 4
# a = a*2; if (a >= 16484) a = a - 16384; digit = digit + 2
# a = a*2; if (a >= 16384) a = a - 16384; digit = digit + 1
# output character (digit ^ $30)

# Based on
# http://6502org.wikidot.com/software-output-decimal

PrintDec:
    PUSH    (r13)
    PUSH    (r1)
    PUSH    (r2)
    PUSH    (r3)
    PUSH    (r4)

    mov     r2, r1
    mov     r3, r0, 4
    mov     r1, r0, 0x2006

PrintDec1:
    ld      r4, r3, DecTable
    CLC     ()
    ror     r2, r2

PrintDec2:
    adc     r2, r2
    c.mov   pc, r0, PrintDec3
    cmp     r2, r4
    nc.mov  pc, r0, PrintDec4

PrintDec3:
    sub     r2, r4
    SEC     ()

PrintDec4:
    adc     r1, r1
    nc.mov  pc, r0, PrintDec2

    JSR     (osWRCH)

    mov     r1, r0, 0x1003
    sub     r3, r0, 1
    pl.mov  pc, r0, PrintDec1

    POP     (r4)
    POP     (r3)
    POP     (r2)
    POP     (r1)
    POP     (r13)
    RTS     ()

DecTable:
    WORD        8 * (2**11)
    WORD       80 * (2** 8)
    WORD      800 * (2** 5)
    WORD     8000 * (2** 2)
    WORD    40000 * (2** 0)

# --------------------------------------------------------------
#
# PrintHex
#
# Prints a 4-digit hex value
#
# Entry:
# - r1 is the value to be printed
#
# Exit:
# - all registers preserved

PrintHex:

    PUSH    (r13)
    PUSH    (r1)            # preserve working registers
    PUSH    (r2)
    PUSH    (r3)

    mov     r2, r1          # r2 is now the value to be printed

    mov     r3, r0, 0x04    # r3 is a loop counter for 4 digits

ph_loop:
    add     r2, r2          # shift the upper nibble of r2
    adc     r1, r1          # into the lower nibble of r1
    add     r2, r2          # one bit at a time
    adc     r1, r1
    add     r2, r2          # add   rd, rd is the same as ASL
    adc     r1, r1          # adc   rd, rd is the same as ROL
    add     r2, r2
    adc     r1, r1

    and     r1, r0, 0x0F    # mask off everything but the bottom nibble
    cmp     r1, r0, 0x0A    # set the carry if r1 >= 0x0A
    c.add   r1, r0, 0x07    # 'A' - '9' + 1
    add     r1, r0, 0x30    # '0'

    JSR     (osWRCH)        # output R1

    sub     r3, r0, 1       # decrement the loop counter
    nz.mov  pc, r0, ph_loop # loop back for four digits

    POP     (r3)            # restore working registers
    POP     (r2)
    POP     (r1)
    POP     (r13)

    RTS     ()

# --------------------------------------------------------------

osFILE:
    # TODO
    RTS     ()

# --------------------------------------------------------------

osFIND:
    # TODO
    RTS     ()

# --------------------------------------------------------------

osGBPB:
    # TODO
    RTS     ()

# --------------------------------------------------------------

osWORD:
    cmp     r1, r0
    z.mov   pc, r0, RDLINE

    # TODO
    RTS     ()

# --------------------------------------------------------------


#
# RDLINE - Read a line of text
# ============================
# On entry, r1 = 0
#           r2 = control block
#
# On exit,  r1 = 0
#           r2 = control block
#           r3 = length of returned string
#           Cy=0 ok, Cy=1 Escape
#
# Tube data  &0A block  --  &FF or &7F string &0D
#

RDLINE:
    PUSH    (r2)
    PUSH    (r13)
    mov     r1, r0, 0x0a
    JSR     (SendByteR2)  # Send command &0A - RDLINE

    ld      r1, r2, 3     # Send <char max>
    JSR     (SendByteR2)
    ld      r1, r2, 2     # Send <char min>
    JSR     (SendByteR2)
    ld      r1, r2, 1     # Send <buffer len>
    JSR     (SendByteR2)
    mov     r1, r0, 0x07  # Send <buffer addr MSB>
    JSR     (SendByteR2)
    mov     r1, r0        # Send <buffer addr LSB>
    JSR     (SendByteR2)
    JSR     (WaitByteR2)  # Wait for response &FF [escape] or &7F
    ld      r3, r0        # initialize response length to 0
    cmp     r1, r0, 0x80  # test for escape
    c.mov   pc, r0, RdLineEscape

    ld      r2, r2        # Load the local input buffer from the control block
RdLineLp:
    JSR     (WaitByteR2)  # Receive a response byte
    sto     r1, r2
    mov     r2, r2, 1     # Increment buffer pointer
    mov     r3, r3, 1     # Increment count
    cmp     r1, r0, 0x0d  # Compare against terminator and loop back
    nz.mov  pc, r0, RdLineLp

    CLC     ()            # Clear carry to indicate not-escape

RdLineEscape:
    POP     (r13)
    POP     (r2)
    mov     r1, r0        # Clear r0 to be tidy
    RTS     ()

-------------------------------------------------------------
# Control block for command prompt input
# --------------------------------------------------------------

osword0_param_block:
    WORD INPBUF
    WORD INPEND - INPBUF
    WORD 0x20
    WORD 0xFF


# --------------------------------------------------------------

osWRCH:
    ld      r12, r0, r1status
    and     r12, r0, 0x40
    z.mov   pc, r0, osWRCH
    sto     r1, r0, r1data
    RTS     ()

# --------------------------------------------------------------

osRDCH:
    PUSH    (r13)
    mov     r1, r0        # Send command &00 - OSRDCH
    JSR     (SendByteR2)
    JSR     (WaitByteR2)  # Receive carry
    add     r1, r0, 0xff80
    JSR     (WaitByteR2)  # Receive A
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

# -----------------------------------------------------------------------------
# Interrupts handlers
# -----------------------------------------------------------------------------

IRQ1Handler:
    ld      r1, r0, r4status
    and     r1, r0, 0x80
    nz.mov  pc, r0, r4_irq
    ld      r1, r0, r1status
    and     r1, r0, 0x80
    nz.mov  pc, r0, r1_irq
    ld      pc, r0, IRQ2V


# -----------------------------------------------------------------------------
# Interrupt generated by data in Tube R1
# -----------------------------------------------------------------------------

r1_irq:
    ld      r1, r0, r1data
    cmp     r1, r0, 0x80
    c.mov   pc, r0, r1_irq_escape

    PUSH   (r13)          # Save registers
    PUSH   (r2)
    PUSH   (r3)
    JSR    (WaitByteR1)   # Get Y parameter from Tube R1
    mov    r3, r1
    JSR    (WaitByteR1)   # Get X parameter from Tube R1
    mov    r2, r1
    JSR    (WaitByteR1)   # Get event number from Tube R1
    JSR    (LFD36)        # Dispatch event
    POP    (r3)           # restore registers
    POP    (r2)
    POP    (r13)

    ld     r1, r0, TMP_R1 # restore R1 from tmp location
    rti    pc, pc         # rti

LFD36:
    ld     pc, r0, EVNTV

r1_irq_escape:
    add    r1, r1
    sto    r1, r0, ESCAPE_FLAG

    ld     r1, r0, TMP_R1 # restore R1 from tmp location
    rti    pc, pc         # rti

# -----------------------------------------------------------------------------
# Interrupt generated by data in Tube R4
# -----------------------------------------------------------------------------

r4_irq:

    ld      r1, r0, r4data
    cmp     r1, r0, 0x80
    nc.mov  pc, r0, LFD65  # b7=0, jump for data transfer

#
# Error    R4: &FF R2: &00 err string &00
#

    PUSH    (r2)
    PUSH    (r13)

    JSR     (WaitByteR2)   # Skip data in Tube R2 - should be 0x00

    mov    r2, r0, ERRBUF

    JSR     (WaitByteR2)   # Get error number
    sto     r1, r2
    mov     r2, r2, 1

err_loop:
    JSR     (WaitByteR2)   # Get error message bytes
    sto     r1, r2
    mov     r2, r2, 1
    cmp     r1, r0
    nz.mov  pc, r0, err_loop

    ERROR   (ERRBUF)

#
# Transfer R4: action ID block sync R3: data
#

LFD65:
    PUSH    (r13)
    PUSH    (r2)           # working register for transfer type
    PUSH    (r3)           # working register for transfer address
    mov     r2, r1
    JSR     (WaitByteR4)
    cmp     r2, r0, 0x05
    z.mov   pc, r0, Release
    JSR     (WaitByteR4)   # block address MSB - ignored for now
    JSR     (WaitByteR4)   # block address ... - ignored for now
    JSR     (WaitByteR4)   # block address ...
    bswp    r1, r1
    mov     r3, r1
    JSR     (WaitByteR4)   # block address LSB
    or      r3, r1

    ld      r1, r0, r3data
    ld      r1, r0, r3data

    JSR     (WaitByteR4)   # sync

    add     r2, r0, TransferHandlerTable
    ld      pc, r2

Release:
    POP     (r3)
    POP     (r2)
    POP     (r13)

    ld      r1, r0, TMP_R1 # restore R1 from tmp location
    rti     pc, pc         # rti


TransferHandlerTable:
    WORD    Type0
    WORD    Type1
    WORD    Type2
    WORD    Type3
    WORD    Type4
    WORD    Release # not actually used
    WORD    Type6
    WORD    Type7

# ============================================================
# Type 0 transfer: 1-byte parasite -> host (SAVE)
#
# r1 - scratch register
# r2 - data register (16-bit data value read from memory)
# r3 - address register (16-bit memory address)
# ============================================================

Type0:

    mov     r2, r0                # clean the odd byte flag (start with an even byte)

Type0_loop:
    ld      r1, r0, r4status      # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    ld      r1, r0, r3status      # Wait for Tube R3 free
    and     r1, r0, 0x40
    z.mov   pc, r0, Type0_loop

    and     r2, r2                # test odd byte flag
    mi.mov  pc, r0, Type0_odd_byte

    ld      r2, r3                # Read word from memory, increment memory pointer
    mov     r3, r3, 1
    sto     r2, r0, r3data        # Send even byte to Tube R3
    bswp    r2, r2
    or      r2, r0, 0x8000        # set the odd byte flag
    mov     pc, r0, Type0_loop

Type0_odd_byte:
    sto     r2, r0, r3data        # Send odd byte to Tube R3
    mov     pc, r0, Type0        # loop back, clearing odd byte flag

# ============================================================
# Type 1 transfer: 1-byte host -> parasite (LOAD)
#
# r1 - scratch register
# r2 - data register (16-bit data value read from memory)
# r3 - address register (16-bit memory address)
# ============================================================

Type1:

    mov     r2, r0                # clean the odd byte flag (start with an even byte)

Type1_loop:
    ld      r1, r0, r4status      # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    ld      r1, r0, r3status      # Wait for Tube R3 free
    and     r1, r0, 0x80
    z.mov   pc, r0, Type1_loop

    and     r2, r2                # test odd byte flag
    mi.mov  pc, r0, Type1_odd_byte

    ld      r2, r0, r3data        # Read the even byte from Tube T3
    or      r2, r0, 0x8000        # set the odd byte flag
    mov     pc, r0, Type1_loop

Type1_odd_byte:

    ld      r1, r0, r3data        # Read the odd byte from Tube T3
    bswp    r1, r1                # Shift it to the upper byte
    and     r2, r0, 0x00FF        # Clear the odd byte flag
    or      r2, r1                # Or the odd byte in the MSB

    sto     r2, r3                # Write word to memory, increment memory pointer
    mov     r3, r3, 1
    mov     pc, r0, Type1         # loop back, clearing odd byte flag


Type2:
    mov     pc, r0, Release

Type3:
    mov     pc, r0, Release

Type4:
    sto     r3, r0, ADDR
    mov     pc, r0, Release

Type6:
    mov     pc, r0, Release

Type7:
    mov     pc, r0, Release

# -----------------------------------------------------------------------------
# Initial interrupt handler, called from 0x0002 (or 0xfffe in PTD)
# -----------------------------------------------------------------------------

InterruptHandler:
    sto     r1, r0, TMP_R1
    psr     r1, psr
    and     r1, r0, SWI_MASK
    nz.mov  pc, r0, SWIHandler
    ld      pc, r0, IRQ1V        # invoke the IRQ handler

SWIHandler:
    psr     r1, psr
    and     r1, r0, ~SWI_MASK
    psr     psr, r1
    ld      r1, r0, TMP_R1       # restore R1 from tmp location
    sto     r1, r0, LAST_ERR     # save the address of the last error
    EI      ()                   # re-enable interrupts
    ld      pc, r0, BRKV         # invoke the BRK handler

# Limit check to precent code running into next block...

Limit1:
    EQU dummy, 0 if (Limit1 < 0xFEF8) else limit1_error

# -----------------------------------------------------------------------------
# TUBE ULA registers
# -----------------------------------------------------------------------------

ORG 0xFEF8

r1status:
    WORD 0x0000     # 0xFEF8
r1data:
    WORD 0x0000     # 0xFEF9
r2status:
    WORD 0x0000     # 0xFEFA
r2data:
    WORD 0x0000     # 0xFEFB
r3status:
    WORD 0x0000     # 0xFEFC
r3data:
    WORD 0x0000     # 0xFEFD
r4status:
    WORD 0x0000     # 0xFEFE
r4data:
    WORD 0x0000     # 0xFEFF

# -----------------------------------------------------------------------------
# DEFAULT VECTOR TABLE
# -----------------------------------------------------------------------------

DefaultVectors:
    WORD Unsupported    # &200 - USERV
    WORD ErrorHandler   # &202 - BRKV
    WORD IRQ1Handler    # &204 - IRQ1V
    WORD Unsupported    # &206 - IRQ2V
    WORD osCLI          # &208 - CLIV
    WORD osBYTE         # &20A - BYTEV
    WORD osWORD         # &20C - WORDV
    WORD osWRCH         # &20E - WRCHV
    WORD osRDCH         # &210 - RDCHV
    WORD osFILE         # &212 - FILEV
    WORD osARGS         # &214 - ARGSV
    WORD osBGET         # &216 - BGetV
    WORD osBPUT         # &218 - BPutV
    WORD osGBPB         # &21A - GBPBV
    WORD osFIND         # &21C - FINDV
    WORD Unsupported    # &21E - FSCV
    WORD NullReturn     # &220 - EVNTV
    WORD Unsupported    # &222 - UPTV
    WORD Unsupported    # &224 - NETV
    WORD Unsupported    # &226 - VduV
    WORD Unsupported    # &228 - KEYV
    WORD Unsupported    # &22A - INSV
    WORD Unsupported    # &22C - RemV
    WORD Unsupported    # &22E - CNPV
    WORD NullReturn     # &230 - IND1V
    WORD NullReturn     # &232 - IND2V
    WORD NullReturn     # &234 - IND3V

# -----------------------------------------------------------------------------
# Helper methods
# -----------------------------------------------------------------------------

# Wait for byte in Tube R1 while allowing requests via Tube R4
WaitByteR1:
    ld      r12, r0, r1status
    and     r12, r0, 0x80
    nz.mov  pc, r0, GotByteR1

    ld      r12, r0, r4status
    and     r12, r0, 0x80
    z.mov   pc, r0, WaitByteR1

# TODO
#
# 6502 code uses re-entrant interrups at this point
#
# we'll need to think carefully about this case
#
#LDA $FC             # Save IRQ's A store in A register
#PHP                 # Allow an IRQ through to process R4 request
#CLI
#PLP
#STA $FC             # Restore IRQ's A store and jump back to check R1
#JMP WaitByteR1

GotByteR1:
    ld     r1, r0, r1data    # Fetch byte from Tube R1 and return
    RTS    ()

# --------------------------------------------------------------

WaitByteR2:
    ld      r1, r0, r2status
    and     r1, r0, 0x80
    z.mov   pc, r0, WaitByteR2
    ld      r1, r0, r2data
    RTS     ()

# --------------------------------------------------------------

WaitByteR4:
    ld      r1, r0, r4status
    and     r1, r0, 0x80
    z.mov   pc, r0, WaitByteR4
    ld      r1, r0, r4data
    RTS     ()

# --------------------------------------------------------------

SendByteR2:
    ld      r12, r0, r2status     # Wait for Tube R2 free
    and     r12, r0, 0x40
    z.mov   pc, r0, SendByteR2
    sto     r1, r0, r2data        # Send byte to Tube R2
    RTS()

# --------------------------------------------------------------

SendStringR2:
    PUSH    (r13)
    PUSH    (r2)

SendStringR2Lp:
    ld      r1, r2
    JSR     (SendByteR2)
    mov     r2, r2, 1
    cmp     r1, r0, 0x0d
    nz.mov  pc, r0, SendStringR2Lp
    POP     (r2)
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------
#
# PrintString
#
# Prints the zero terminated ASCII string
#
# Entry:
# - r1 points to the zero terminated string
#
# Exit:
# - all other registers preserved

PrintString:
    PUSH    (r2)
    PUSH    (r13)
    mov     r2, r1

ps_loop:
    ld      r1, r2
    and     r1, r0, 0xff
    z.mov   pc, r0, ps_exit
    JSR     (OSWRCH)
    mov     r2, r2, 0x0001
    mov     pc, r0, ps_loop

ps_exit:
    POP     (r13)
    POP     (r2)
    RTS     ()

# --------------------------------------------------------------

osnewl_code:
    PUSH    (r13)
    mov     r1, r0, 0x0a
    JSR     (OSWRCH)
    mov     r1, r0, 0x0d
    JSR     (OSWRCH)
    POP     (r13)
    RTS     ()

# -----------------------------------------------------------------------------
# Messages
# -----------------------------------------------------------------------------

BannerMessage:
    WORD    0x0a
    STRING "OPC5LS Co Processor"
    WORD    0x0a, 0x0a, 0x0d, 0x00

EscapeError:
    WORD    17
    STRING "Escape"
    WORD    0x00

# Currently about 10 words free

# Limit check to precent code running into next block...

Limit2:
    EQU dummy, 0 if (Limit2 < 0xFFC8) else limit2_error

# -----------------------------------------------------------------------------
# MOS interface
# -----------------------------------------------------------------------------

ORG 0xFFC8

NVRDCH:                      # &FFC8
    ld      pc, r0, osRDCH
    WORD    0x0000

NVWRCH:                      # &FFCB
    ld      pc, r0, osWRCH
    WORD    0x0000

OSFIND:                      # &FFCE
    ld      pc, r0, FINDV
    WORD    0x0000

OSGBPB:                      # &FFD1
    ld      pc, r0, GBPBV
    WORD    0x0000

OSBPUT:                      # &FFD4
    ld      pc, r0, BPUTV
    WORD    0x0000

OSBGET:                      # &FFD7
    ld      pc, r0, BGETV
    WORD    0x0000

OSARGS:                      # &FFDA
    ld      pc, r0, ARGSV
    WORD    0x0000

OSFILE:                      # &FFDD
    ld      pc, r0, FILEV
    WORD    0x0000

OSRDCH:                      # &FFE0
    ld      pc, r0, RDCHV
    WORD    0x0000

OSASCI:                      # &FFE3
    cmp     r1, r0, 0x0d
    nz.mov  pc, r0, OSWRCH

OSNEWL:                      # &FFE7
    mov     pc, r0, osnewl_code
    WORD    0x0000
    WORD    0x0000
    WORD    0x0000

OSWRCR:                      # &FFEC
    mov     r1, r0, 0x0D

OSWRCH:                      # &FFF1
    ld      pc, r0, WRCHV
    WORD    0x0000

OSWORD:                      # &FFEE
    ld      pc, r0, WORDV
    WORD    0x0000

OSBYTE:                      # &FFF4
    ld      pc, r0, BYTEV
    WORD    0x0000

OS_CLI:                      # &FFF7
    ld      pc, r0, CLIV
    WORD    0x0000

# -----------------------------------------------------------------------------
# Reset vectors, used by PiTubeDirect
# -----------------------------------------------------------------------------

NMI_ENTRY:                   # &FFFA
    WORD    0x0000
    WORD    0x0000

RST_ENTRY:                   # &FFFC
    mov     pc, r0, ResetHandler

IRQ_ENTRY:                   # &FFFE
    mov     pc, r0, InterruptHandler
