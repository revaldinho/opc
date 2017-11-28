##include "macros.s"

##ifdef CPU_OPC7
EQU        BASE, 0x00000
EQU        CODE, 0x00200
EQU        TUBE, 0xFFEF8
EQU         MOS, 0x000C8
EQU        WORK, 0x00100
EQU  END_MARKER, 0x80000000   # makes the end of each command -ve
##else
EQU        BASE, 0xE000
EQU        CODE, 0xF800
EQU        TUBE, 0xFEF8
EQU         MOS, 0xFFC8
EQU        WORK, 0x0000
EQU  END_MARKER, 0x8000       # makes the end of each command -ve
##endif

# These are passed in directly from the makefile
EQU     MEM_BOT, _MEM_BOT_
EQU     MEM_TOP, _MEM_TOP_
EQU       STACK, _STACK_

EQU    r1status, TUBE
EQU      r1data, TUBE + 1
EQU    r2status, TUBE + 2
EQU      r2data, TUBE + 3
EQU    r3status, TUBE + 4
EQU      r3data, TUBE + 5
EQU    r4status, TUBE + 6
EQU      r4data, TUBE + 7

EQU NUM_VECTORS, 27           # number of vectors in DefaultVectors table

# -----------------------------------------------------------------------------
# Memory from 0x0000 to 0x00FF is reserved for system use
# -----------------------------------------------------------------------------

# 0x0000 = OPC5/6 Reset address

# 0x0002 = OPC5/6 IRQ0 address

# 0x0004 = OPC6 IRQ1 address

EQU       USERV, WORK + 0x0010
EQU        BRKV, WORK + 0x0011
EQU       IRQ1V, WORK + 0x0012
EQU       IRQ2V, WORK + 0x0013
EQU        CLIV, WORK + 0x0014
EQU       BYTEV, WORK + 0x0015
EQU       WORDV, WORK + 0x0016
EQU       WRCHV, WORK + 0x0017
EQU       RDCHV, WORK + 0x0018
EQU       FILEV, WORK + 0x0019
EQU       ARGSV, WORK + 0x001A
EQU       BGETV, WORK + 0x001B
EQU       BPUTV, WORK + 0x001C
EQU       GBPBV, WORK + 0x001D
EQU       FINDV, WORK + 0x001E
EQU        FSCV, WORK + 0x001F
EQU       EVNTV, WORK + 0x0020
EQU        UPTV, WORK + 0x0021       # not implemented
EQU        NETV, WORK + 0x0022       # not implemented
EQU        VDUV, WORK + 0x0023       # not implemented
EQU        KEYV, WORK + 0x0024       # not implemented
EQU        INSV, WORK + 0x0025       # not implemented
EQU        REMV, WORK + 0x0026       # not implemented
EQU        CNPV, WORK + 0x0027       # not implemented
EQU       IND1V, WORK + 0x0028       # not implemented
EQU       IND2V, WORK + 0x0029       # not implemented
EQU       IND3V, WORK + 0x002A       # not implemented

EQU      ERRBUF, WORK + 0x0030
EQU      INPBUF, WORK + 0x0030
EQU      INPEND, WORK + 0x00F6

EQU        ADDR, WORK + 0x00F6       # tube execution address
EQU      TMP_R1, WORK + 0x00FC       # tmp store for R1 during IRQ
EQU    LAST_ERR, WORK + 0x00FD       # last error
EQU ESCAPE_FLAG, WORK + 0x00FF       # escape flag

MACRO ERROR (_address_)
    mov     r1, r0, _address_
    SWI0    ()
ENDMACRO

# -----------------------------------------------------------------------------
# 8K Rom Start
# -----------------------------------------------------------------------------

// These end up at 0x0000 and get used by the Real Co Pro
ORG BASE
    mov      pc, r0, ResetHandler

ORG BASE + 2
    mov      pc, r0, InterruptHandler

ORG CODE

##include "lib_printstring.s"
##include "lib_printhex.s"
##include "lib_printdec.s"
##include "lib_readhex.s"
##include "lib_srec.s"
##include "lib_dumpmem.s"

##ifndef CPU_OPC5LS
##include "lib_disassemble.s"
##endif

ResetHandler:
    mov     r14, r0, STACK              # setup the stack

    mov     r2, r0, NUM_VECTORS - 1     # copy the vectors
InitVecLoop:
    ld      r1, r2, DefaultVectors
    sto     r1, r2, USERV
    sub     r2, r0, 1
    pl.mov  pc, r0, InitVecLoop

    EI      ()                          # enable interrupts

    mov     r1, r0, BannerMessage       # send the reset message
    JSR     (print_string)

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
    JSR     (print_string)              # Print error string
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
    add     r1, r0, -0x80
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

    POP     (r1)
    PUSH    (r1)

    JSR     (prep_env)

    JSR     (enterCode)

dontEnterCode:
    POP     (r1)

    POP     (r2)
    POP     (r13)
    RTS     ()

enterCode:
    ld      pc, r0, ADDR

# Find the start of the command string
#
# Lots of ways a file can be run:
# *    filename params
# * /  filename params
# *R.  filename params
# *RU. filename params
# *RUN filename params
#   
#
# In general you want:
# - skip leading space or * characters
# - skip any form of *RUN, followed by trailing spaces
# - leave the environment point at the first character of filename

prep_env:
    PUSH    (r13)
    DEC     (r1, 1)
prep_env_1:                         # skip leading space or * characters
    INC     (r1, 1)
    JSR     (skip_spaces)
    cmp     r2, r0, 0x2A            # *
    z.mov   pc, r0, prep_env_1

    cmp     r2, r0, 0x2F            # /
    z.mov   pc, r0, prep_env_4

    mov     r2, r0, run_string - 1
    mov     r3, r1, -1
prep_env_2:                         # skip a possibly abbreviated RUN
    INC     (r2, 1)
    ld      r4, r2                  # Read R U N <0>
    z.mov   pc, r0, prep_env_3
    INC     (r3, 1)
    ld      r5, r3
    cmp     r5, r0, 0x2E            # .
    z.mov   pc, r0, prep_env_3
    and     r5, r0, 0xDF            # force upper case
    cmp     r4, r5                  # match against R U N
    nz.mov  pc, r0, prep_env_5
    mov     pc, r0, prep_env_2      # loop back for more characters

prep_env_3:
    mov     r1, r3

prep_env_4:
    INC     (r1, 1)

prep_env_5:
    JSR     (skip_spaces)
    POP     (r13)
    RTS     ()

run_string:
    STRING  "RUN"
    WORD    0

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

    sub     r1, r0, 1
cmdLoop0:
    add     r1, r0, 1
    JSR     (skip_spaces)           # skip leading spaces
    cmp     r2, r0, ord('*')        # also skip leading *
    z.mov   pc, r0, cmdLoop0

    mov     r2, r0, cmdTable-1      # initialize command table pointer (to char before)

cmdLoop1:
    mov     r3, r1, -1              # initialize user command pointer (to char before)

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
    PUSH    (r13)
    JSR     (read_hex)
    JSR     (cmdExecR2)
    mov     r1, r0
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

cmdMem:
    PUSH    (r13)
    JSR     (read_hex)
    mov     r1, r2
    JSR     (dump_mem)
    mov     r1, r0
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

##ifndef CPU_OPC5LS
cmdDis:
    PUSH    (r13)
    JSR     (read_hex)

    mov     r3, r0, 16
dis_loop:
    mov     r1, r2
    JSR     (disassemble)
    mov     r2, r1
    JSR     (OSNEWL)
    DEC     (r3, 1)
    nz.mov  pc, r0, dis_loop
    mov     r1, r0
    POP     (r13)
    RTS     ()
##endif
# --------------------------------------------------------------

cmdHelp:
    PUSH   (r13)
    mov    r1, r0, msgHelp
    JSR    (print_string)
    mov    r1, r0, 1
    POP    (r13)
    RTS    ()

msgHelp:
    CPU_STRING()
    STRING   " 0.52"
    WORD     10, 13, 0

# --------------------------------------------------------------

cmdTest:
    PUSH   (r13)
    JSR    (read_hex)
    mov    r1, r2
    JSR    (print_hex_word_spc)
    JSR    (print_dec_word)
    JSR    (OSNEWL)
    mov    r1, r0
    POP    (r13)
    RTS    ()

# ---------------------------------------------------------

cmdSrec:
    PUSH   (r13)
    JSR    (srec_load)
    cmp    r1, r0, 1
    z.mov  pc, r0, CmdOSEscape
    cmp    r1, r0, 2
    z.mov  pc, r0, cmdSrecChecksumError
    cmp    r1, r0
    nz.mov pc, r0, cmdSrecBadFormatError
    POP    (r13)
    RTS    ()

cmdSrecChecksumError:
    ERROR   (checksumError)

checksumError:
    WORD    17                    # TODO assign proper error code
    STRING "Checksum Mismatch"
    WORD    0x00

cmdSrecBadFormatError:
    ERROR   (badFormatError)

badFormatError:
    WORD    17                    # TODO assign proper error code
    STRING "Bad Format"
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
    WORD    cmdEnd  | END_MARKER
    STRING  "go"
    WORD    cmdGo   | END_MARKER
    STRING  "mem"
    WORD    cmdMem  | END_MARKER
##ifndef CPU_OPC5LS
    STRING  "dis"
    WORD    cmdDis  | END_MARKER
##endif
    STRING  "help"
    WORD    cmdHelp | END_MARKER
    STRING  "test"
    WORD    cmdTest | END_MARKER
    STRING  "srec"
    WORD    cmdSrec | END_MARKER
    WORD    cmdEnd  | END_MARKER

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
    PUSH    (r12)
osWRCH1:
    IN      (r12, r1status)
    and     r12, r0, 0x40
    z.mov   pc, r0, osWRCH1
    OUT     (r1, r1data)
    POP     (r12)
    RTS     ()

# --------------------------------------------------------------

osRDCH:
    PUSH    (r13)
    mov     r1, r0        # Send command &00 - OSRDCH
    JSR     (SendByteR2)
    JSR     (WaitByteR2)  # Receive carry
    add     r1, r0, -0x80
    JSR     (WaitByteR2)  # Receive A
    POP     (r13)
    RTS     ()

# --------------------------------------------------------------

# -----------------------------------------------------------------------------
# Interrupts handlers
# -----------------------------------------------------------------------------

IRQ1Handler:
    IN      (r1, r4status)
    and     r1, r0, 0x80
    nz.mov  pc, r0, r4_irq
    IN      (r1, r1status)
    and     r1, r0, 0x80
    nz.mov  pc, r0, r1_irq
    ld      pc, r0, IRQ2V


# -----------------------------------------------------------------------------
# Interrupt generated by data in Tube R1
# -----------------------------------------------------------------------------

r1_irq:
    IN      (r1, r1data)
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

    IN      (r1, r4data)
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
##ifdef CPU_OPC7
    JSR     (WaitByteR4)   # block address MSB
    bperm   r3, r1, 0x4404
    JSR     (WaitByteR4)   # block address ...
    or      r3, r1
    bperm   r3, r3, 0x2104
    JSR     (WaitByteR4)   # block address ...
    or      r3, r1
    bperm   r3, r3, 0x2104
    JSR     (WaitByteR4)   # block address LSB
    or      r3, r1
##else
    JSR     (WaitByteR4)   # block address MSB - ignored
    JSR     (WaitByteR4)   # block address ... - ignored
    JSR     (WaitByteR4)   # block address ...
    bswp    r1, r1
    mov     r3, r1
    JSR     (WaitByteR4)   # block address LSB
    or      r3, r1
##endif
    IN      (r1, r3data)
    IN      (r1, r3data)

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

# TODO: we should be able to have one common implementation
# i.e. the 16-bit should be a degenerate case of 32-bit

Type0:
##ifdef CPU_OPC7

# r2 also tracks when we need load a new word, because
# we cycle a ff through from the MSB. So the continuation
# test sees one of the following:
#    ff 33 22 11     (3 bytes remaining)
#    00 ff 33 22     (2 bytes remaining)
#    00 00 ff 33     (1 bytes remaining)
#    00 00 00 ff     (0 bytes remaining, need to reload)

    mov     r2, r0                # clear the continuation flag

Type0_loop:
    IN      (r1, r4status)        # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    IN      (r1, r3status)        # Wait for Tube R3 free
    and     r1, r0, 0x40
    z.mov   pc, r0, Type0_loop

    bperm   r1, r2, 0x3214        # test continuation flag, more efficient than mov r1, r2 + and r1, r0, 0xffffff00
    nz.mov  pc, r0, Type0_continuation

    ld      r2, r3                # Read word from memory, increment memory pointer
    mov     r3, r3, 1
    OUT     (r2, r3data)          # Send LSB to Tube R3
    or      r2, r0, 0xff          # set the continuation flag
    bperm   r2, r2, 0x0321        # cyclic rotate, r2 = ff 33 22 11
    mov     pc, r0, Type0_loop

Type0_continuation:

    OUT     (r2, r3data)         # Send odd byte to Tube R3
    bperm   r2, r2, 0x4321       # shift right one byte
    mov     pc, r0, Type0_loop   # loop back, clearing odd byte flag

##else

    mov     r2, r0                # clean the odd byte flag (start with an even byte)

Type0_loop:
    IN      (r1, r4status)        # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    IN      (r1, r3status)        # Wait for Tube R3 free
    and     r1, r0, 0x40
    z.mov   pc, r0, Type0_loop

    and     r2, r2                # test odd byte flag
    mi.mov  pc, r0, Type0_odd_byte

    ld      r2, r3                # Read word from memory, increment memory pointer
    mov     r3, r3, 1
    OUT     (r2, r3data)          # Send even byte to Tube R3
    bswp    r2, r2
    or      r2, r0, 0x8000        # set the odd byte flag
    mov     pc, r0, Type0_loop

Type0_odd_byte:
    OUT     (r2, r3data)         # Send odd byte to Tube R3
    mov     pc, r0, Type0        # loop back, clearing odd byte flag

##endif

# ============================================================
# Type 1 transfer: 1-byte host -> parasite (LOAD)
#
# r1 - scratch register
# r2 - data register (16-bit data value read from memory)
# r3 - address register (16-bit memory address)
# ============================================================

# TODO: we should be able to have one common implementation
# i.e. the 16-bit should be a degenerate case of 32-bit

Type1:
##ifdef CPU_OPC7

    mov     r2, r0, 0xff          # set the last byte flag in byte 0

Type1_loop:
    IN      (r1, r4status)        # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    IN      (r1, r3status)        # Wait for Tube R3 free
    and     r1, r0, 0x80
    z.mov   pc, r0, Type1_loop

    IN      (r1, r3data)          # Read the last byte from Tube T3

    and     r2, r2                # test last byte flag
    mi.mov  pc, r0, Type1_last_byte

    bperm   r2, r2, 0x2104
    or      r2, r1
    mov     pc, r0, Type1_loop

Type1_last_byte:

    bperm   r2, r2, 0x2104
    or      r2, r1
    bperm   r2, r2, 0x0123        # byte swap to make it little endian

    sto     r2, r3                # Write word to memory, increment memory pointer
    mov     r3, r3, 1
    mov     pc, r0, Type1         # loop back, clearing last byte flag

##else

    mov     r2, r0                # clean the odd byte flag (start with an even byte)

Type1_loop:
    IN      (r1, r4status)        # Test for an pending interrupt signalling end of transfer
    and     r1, r0, 0x80
    nz.mov  pc, r0, Release

    IN      (r1, r3status)        # Wait for Tube R3 free
    and     r1, r0, 0x80
    z.mov   pc, r0, Type1_loop

    and     r2, r2                # test odd byte flag
    mi.mov  pc, r0, Type1_odd_byte

    IN      (r2, r3data)          # Read the even byte from Tube T3
    or      r2, r0, 0x8000        # set the odd byte flag
    mov     pc, r0, Type1_loop

Type1_odd_byte:

    IN      (r1, r3data)          # Read the odd byte from Tube T3
    bswp    r1, r1                # Shift it to the upper byte
    and     r2, r0, 0x00FF        # Clear the odd byte flag
    or      r2, r1                # Or the odd byte in the MSB

    sto     r2, r3                # Write word to memory, increment memory pointer
    mov     r3, r3, 1
    mov     pc, r0, Type1         # loop back, clearing odd byte flag

##endif

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
    GETPSR  (r1)
    and     r1, r0, SWI_MASK
    nz.mov  pc, r0, SWIHandler
    ld      pc, r0, IRQ1V        # invoke the IRQ handler

SWIHandler:
    GETPSR  (r1)
    and     r1, r0, ~SWI_MASK
    PUTPSR  (r1)
    ld      r1, r0, TMP_R1       # restore R1 from tmp location
    sto     r1, r0, LAST_ERR     # save the address of the last error
    EI      ()                   # re-enable interrupts
    ld      pc, r0, BRKV         # invoke the BRK handler

##ifdef CPU_OPC5LS

# Limit check to precent code running into next block...

Limit1:
    EQU dummy, 0 if (Limit1 < 0xFEF8) else limit1_error

# -----------------------------------------------------------------------------
# TUBE ULA registers
# -----------------------------------------------------------------------------

ORG TUBE
    WORD 0x0000     # 0xFEF8
    WORD 0x0000     # 0xFEF9
    WORD 0x0000     # 0xFEFA
    WORD 0x0000     # 0xFEFB
    WORD 0x0000     # 0xFEFC
    WORD 0x0000     # 0xFEFD
    WORD 0x0000     # 0xFEFE
    WORD 0x0000     # 0xFEFF

##endif

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
    IN      (r12, r1status)
    and     r12, r0, 0x80
    nz.mov  pc, r0, GotByteR1

    IN      (r12, r4status)
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
    IN     (r1, r1data)    # Fetch byte from Tube R1 and return
    RTS    ()

# --------------------------------------------------------------

WaitByteR2:
    IN      (r1, r2status)
    and     r1, r0, 0x80
    z.mov   pc, r0, WaitByteR2
    IN      (r1, r2data)
    RTS     ()

# --------------------------------------------------------------

WaitByteR4:
    IN      (r1, r4status)
    and     r1, r0, 0x80
    z.mov   pc, r0, WaitByteR4
    IN      (r1, r4data)
    RTS     ()

# --------------------------------------------------------------

SendByteR2:
    IN      (r12, r2status)       # Wait for Tube R2 free
    and     r12, r0, 0x40
    z.mov   pc, r0, SendByteR2
    OUT     (r1, r2data)          # Send byte to Tube R2
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
    CPU_STRING()
    STRING " Co Processor"
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

ORG MOS

NVRDCH:                      # &FFC8
    ld      pc, r0, osRDCH

ORG MOS + (0xCB-0xC8)

NVWRCH:                      # &FFCB
    ld      pc, r0, osWRCH

ORG MOS + (0xCE-0xC8)

OSFIND:                      # &FFCE
    ld      pc, r0, FINDV

ORG MOS + (0xD1-0xC8)

OSGBPB:                      # &FFD1
    ld      pc, r0, GBPBV

ORG MOS + (0xD4-0xC8)

OSBPUT:                      # &FFD4
    ld      pc, r0, BPUTV

ORG MOS + (0xD7-0xC8)

OSBGET:                      # &FFD7
    ld      pc, r0, BGETV

ORG MOS + (0xDA-0xC8)

OSARGS:                      # &FFDA
    ld      pc, r0, ARGSV

ORG MOS + (0xDD-0xC8)

OSFILE:                      # &FFDD
    ld      pc, r0, FILEV

ORG MOS + (0xE0-0xC8)

OSRDCH:                      # &FFE0
    ld      pc, r0, RDCHV

ORG MOS + (0xE3-0xC8)

OSASCI:                      # &FFE3
    cmp     r1, r0, 0x0d
    nz.mov  pc, r0, OSWRCH

ORG MOS + (0xE7-0xC8)

OSNEWL:                      # &FFE7
    mov     pc, r0, osnewl_code

ORG MOS + (0xEC-0xC8)

OSWRCR:                      # &FFEC
    mov     r1, r0, 0x0D

ORG MOS + (0xEE-0xC8)

OSWRCH:                      # &FFEE
    ld      pc, r0, WRCHV

ORG MOS + (0xF1-0xC8)

OSWORD:                      # &FFF1
    ld      pc, r0, WORDV

ORG MOS + (0xF4-0xC8)

OSBYTE:                      # &FFF4
    ld      pc, r0, BYTEV

ORG MOS + (0xF7-0xC8)

OS_CLI:                      # &FFF7
    ld      pc, r0, CLIV

# -----------------------------------------------------------------------------
# Reset vectors, used by PiTubeDirect
# -----------------------------------------------------------------------------

ORG MOS + (0xFA-0xC8)

NMI_ENTRY:                   # &FFFA

ORG MOS + (0xFC-0xC8)

RST_ENTRY:                   # &FFFC
    mov     pc, r0, ResetHandler

ORG MOS + (0xFE-0xC8)

IRQ_ENTRY:                   # &FFFE
    mov     pc, r0, InterruptHandler
