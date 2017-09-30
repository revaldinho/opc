
        #
        # Dummy Tube ROM for emulation only. Read and write char calls implemented
        # but others all just have entry points present and return no data
        #


        ORG 0xFF00
        # --------------------------------------------------------------
        #
        # READCHAR - for simulation/emulation only 
        #
        # Read a single ascii character from the uart (assume always ready)
        #
        # Entry:
        #       none
        # Exit:
        #       r1 is character read in
        #       r2 used as temporary
        # ---------------------------------------------------------------
READCHAR:       
        in      r1, r0, 0xff80
        RTS     ()
        # --------------------------------------------------------------
        #
        # WRITECHAR - for simulation/emulation only 
        #
        # Output a single ascii character to the uart (assume always ready)
        #
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporary
        # ---------------------------------------------------------------
WRITECHAR:
        out     r1, r0, 0xfe09
        RTS     ()
osnewl_code:
        PUSH    (r13)
        mov     r1, r0, 0x0a
        JSR     (OSWRCH)
        mov     r1, r0, 0x0d
        JSR     (OSWRCH)
        POP     (r13)
        RTS     ()

        
        ## Dummy routines for all of the Tube ROM calls
        ORG 0xFFC8
NVRDCH: mov     pc, r0, osrdch
        WORD    0x0000
NVWRCH:                      # &FFCB
        mov     pc, r0, oswrch
        WORD    0x0000

OSFIND:                      # &FFCE
        RTS()
        WORD    0x0000
        WORD    0x0000        
OSGBPB:                      # &FFD1
        RTS()
        WORD    0x0000
        WORD    0x0000
OSBPUT:                      # &FFD4
        RTS()
        WORD    0x0000
        WORD    0x0000
OSBGET:                      # &FFD7
        RTS()
        WORD    0x0000
        WORD    0x0000

OSARGS:                      # &FFDA
        RTS()
        WORD    0x0000
        WORD    0x0000

OSFILE:                      # &FFDD
        RTS()
        WORD    0x0000
        WORD    0x0000

OSRDCH:                      # &FFE0
osrdch:
        mov      pc, r0, READCHAR
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

oswrch: 
OSWRCH:                      # &FFEE
        mov     pc, r0, WRITECHAR
        WORD    0x0000

OSWORD:                      # &FFF1
        RTS()
        WORD    0x0000
        WORD    0x0000              

OSBYTE:                      # &FFF4
        RTS()
        WORD    0x0000
        WORD    0x0000              

OS_CLI:                      # &FFF7
        RTS()
        WORD    0x0000
        WORD    0x0000              


