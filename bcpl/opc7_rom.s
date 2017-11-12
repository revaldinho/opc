	# 
	#  :------------------- : 
	#  :0xFFFF Data Space   :     
	#  :          |         :    
	#  :          v         :    
	#  :                    :     
	#  :                    : 
	#  :          ^         : 
	#  :          |         :
	#  :      Local Vars    :
	#  :          ^         :
	#  :          |         :
	#  :      Global Vec.   :                        
	#  :          ^         :                        
	#  :          |         :                        
	#  :0x01000 Prog start  :        
	#  :------------------- :        
	#  :0x00FFF Stack       :        
	#  :          |         :        
	#  :0x00800   v         :  
	#  :--------------------:
	#  :0x007FF             :         
	#  :          (Tube)    : 
	#  :           ROM      :
	#  :           OR       :
	#  :0x00000   Monitor   : 
	#  :------------------- : 
	#  :                    : 
	#  :        OPC7        : 
	#            (D)          
        #
        # Dummy Tube ROM for emulation only. Read and write char calls implemented
        # but others all just have entry points present and return no data
        #

        ORG 0x0700
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
        lmov    r1,0x0a
        JSR     (OSWRCH)
        lmov    r1,0x0d
        JSR     (OSWRCH)
        POP     (r13)
        RTS     ()


        ## Dummy routines for all of the Tube ROM calls
        ORG 0x07C8
NVRDCH: lmov    pc,osrdch
        WORD    0x0000         
NVWRCH:                      # &07CB
        lmov    pc,oswrch
        WORD    0x0000

OSFIND:                      # &07CE
        RTS()
        WORD    0x0000
        WORD    0x0000
OSGBPB:                      # &07D1
        RTS()
        WORD    0x0000
        WORD    0x0000
OSBPUT:                      # &07D4
        RTS()
        WORD    0x0000
        WORD    0x0000
OSBGET:                      # &07D7
        RTS()
        WORD    0x0000
        WORD    0x0000

OSARGS:                      # &07DA
        RTS()
        WORD    0x0000
        WORD    0x0000

OSFILE:                      # &07DD
        RTS()
        WORD    0x0000
        WORD    0x0000

OSRDCH:                      # &07E0
osrdch:
        lmov    pc,READCHAR
        WORD    0x0000

OSASCI:                      # &07E3
        cmp     r1, r0, 0x0d
        nz.lmov pc,OSWRCH

OSNEWL:                      # &07E7
        lmov    pc,osnewl_code
        WORD    0x0000
        WORD    0x0000
        WORD    0x0000

OSWRCR:                      # &07EC
        lmov    r1,0x0D

oswrch:
OSWRCH:                      # &07EE
        lmov    pc,WRITECHAR
        WORD    0x0000

OSWORD:                      # &07F1
        RTS()
        WORD    0x0000
        WORD    0x0000

OSBYTE:                      # &07F4
        RTS()
        WORD    0x0000
        WORD    0x0000

OS_CLI:                      # &07F7
        RTS()
        WORD    0x0000
        WORD    0x0000


