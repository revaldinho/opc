        # opc7sys_rom.s - opc/bcpl/opc7_rom.s for the OPC7 system (opc7hsys.v): the same entry
        # points, with READCHAR and WRITECHAR on the system UART (I/O 0x00 status, 0x01 data).
        # Built with the program in phase 1: everything below 0x1000 becomes the boot ROM.
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

        ORG 0x0100
        # --------------------------------------------------------------
        #
        # READCHAR - for simulation/emulation only
        #
        # Read a single ascii character from the UART, waiting for one to arrive
        #
        # Entry:
        #       none
        # Exit:
        #       r1 is character read in
        #       r2 used as temporary
        # ---------------------------------------------------------------
READCHAR:
        in      r1, r0, 0x00           # UART status
        and     r1, r0, 0x02           # bit 1: a byte has arrived
        z.mov   pc, r0, READCHAR
        in      r1, r0, 0x01           # pop it
        RTS     ()
        # --------------------------------------------------------------
        #
        # WRITECHAR - for simulation/emulation only
        #
        # Output a single ascii character to the UART, waiting for room in its FIFO
        #
        # Entry:
        #       r1 is the character to output
        # Exit:
        #       r2 used as temporary
        # ---------------------------------------------------------------
WRITECHAR:
        in      r2, r0, 0x00           # UART status
        and     r2, r0, 0x01           # bit 0: room in the TX FIFO
        z.mov   pc, r0, WRITECHAR
        out     r1, r0, 0x01           # push the character
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

        EQU     MOS,    0x00C8
        
        ORG MOS
NVRDCH: lmov    pc,osrdch

        ORG MOS + (0xCB-0xC8)
        
NVWRCH:                      # &07CB
        lmov    pc,oswrch

        ORG MOS + (0xE0-0xC8)
OSRDCH:                      # &07E0
osrdch:
        lmov    pc,READCHAR

        ORG MOS + (0xE3-0xC8)
        
OSASCI:                      # &07E3
        cmp     r1, r0, 0x0d
        nz.lmov pc,OSWRCH

        ORG MOS + (0xE7-0xC8)
        
OSNEWL:                      # &07E7
        lmov    pc,osnewl_code

        ORG MOS + (0xEC-0xC8)
        
OSWRCR:                      # &07EC
        lmov    r1,0x0D

        ORG MOS + (0xEE-0xC8)
        
oswrch:
OSWRCH:                      # &07EE
        lmov    pc,WRITECHAR

ORG MOS + (0xF1-0xC8)

OSWORD:                      # &FFF1
        RTS     ()

ORG MOS + (0xF4-0xC8)

OSBYTE:                      # &FFF4
        RTS     ()
