        ORG     0xFFE0
        # --------------------------------------------------------------
        #
        # osrdch - for simulation/emulation only 
        #
        # Read a single ascii character from the uart (assume always ready)
        #
        # Entry:
        #       none
        # Exit:
        #       r1 is character read in
        #       r2 used as temporary
        # ---------------------------------------------------------------
osrdch:
OSRDCH: 
        in      r1, r0, 0xff80
        RTS     ()
        
        ORG     0xFFEE
        # --------------------------------------------------------------
        #
        # oswrch - for simulation/emulation only 
        #
        # Output a single ascii character to the uart (assume always ready)
        #
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporary
        # ---------------------------------------------------------------
oswrch:
OSWRCH: 
        out     r1, r0, 0xfe09
        RTS     ()
