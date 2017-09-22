#!/usr/bin/env python3
## ============================================================================
## sial2opc6.py - Backend code converter for SIAL (BCPL) intermediate code 
##                to OPC6 assembler
##
## COPYRIGHT 2017 Richard Evans
##
## The program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## sial2opc6.py is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## See  <http://www.gnu.org/licenses/> for a copy of the GNU Lesser General
## Public License
##
## ============================================================================
'''
USAGE ::

  sial2opc6.py translates BCPL's SIAL intermediate code to OPC6 assembler

REQUIRED SWITCHES ::
 
  -f --filename <filename>  Specify the SIAL source code. May be used multiple times
                            and the files will be read in the sequence they appear in
                            the command line

OPTIONAL SWITCHES ::

  -h  --help                Show this help message

  -s --syslib   <filename>  Specify the syslib file which implements the sys() function
                            and other OPC6 specific calls, written in OPC6 assembler 
                            already.

  -g --sialhdr  <filename>  Specify the path to the sial.h header file contained in the
                            BCPL distribution. By default the program will look for the 
                            header file in ${BCPLHDRS}/sial.h, using one of the environment
                            variables set up for using the BCPL system.

  -n  --noheader            Suppress the standard start up sequence at the head of assembler
                            output


All output is sent to stdout.

EXAMPLES ::

  sial2opc6.py -f file1.sial -f bcpllib.sial -g ~/src/BCPL/cintcode/g/sial.h -s syslib.s

  concatenates the standard BCPL library functions onto the end of the user file file1.sial
  before translation. (There is no separate linker here, so the source for bcpllib needs to 
  be included in the translation for now.) 

  The assembly output is in the following sequence

  Standard startup    - stack initialization, setup of data pointers etc
  file1 translation   - assembly code generated from translating file1.sial
  bcpllib translation - assembly code generated from translating bcpllib.sial
  syslib              - syslib code taken verbatim from syslib.s (if required)
  global vector       - the BCPL global vector

  ie the entire bcpllib (currently not large) is concatenated with the source and assembled
  together and the global vector ends at the end of the assembled code. All memory beyond
  that point is available for data.

'''
import sys
import getopt
import os
import re
import codecs

def showUsageAndExit() :
    print (__doc__)
    sys.exit(2)


def getstring( s_list):
    # Convert string in format[ "K<len>", "C<char>" ...] into string
    str = []
    for i in range (1, len(s_list)):
        c = int(s_list[i][1:]) & 0xFF
        if c < 32:
            c = '\\%03o' % c
        else:
            c = chr(c)
        str.append(c)
    return ''.join(str)

def getnum( str ):
    # Convert literal of form K<n> to number
    num = int(str[1:])
    return num

def code ( codestring, source=""):
    words = codestring.split()

    if len(words) > 0 and words[0].endswith(':'):
        leading = ""
        trailing = " "*8
    else :
        leading = " "*8
        trailing = ""
    print( "%s%-48s%s # %s" % (leading,codestring,trailing,source))


def print_header():
    print('''
        ## --------------------------------------------------------------
        ## OPC6 assembly code generated from SIAL using sial2opc.py
        ## --------------------------------------------------------------
        ##
        ## OPC6 to SIAL resource mapping
        ##
        ## r1  == A
        ## r2  == B
        ## r3  == C
        ## r11 == P (local ptr)
        ## r12 == G (global vector ptr)
        ## r15 == PC
        ##
        ## System register usage
        ##
        ## r4,5,6 == tmp registers, not persistent across instructions
        ## r9     == stack pointer on entry to BCPL (used for sys abort)
        ## r10    == Global memory wavefront
        ## r13    == link reg  
        ## r14    == stack ptr          
        ## --------------------------------------------------------------
        ## Cut off this section for running via the monitor on hardware
        ORG 0x0000 
        mov   r14,r0,0x0FFE                 # Set stack to grow down from here for monitor
        mov   pc,r0,0x1000                  # Program start at 0x1000 for use with monitor/copro
        ## --------------------------------------------------------------
        ORG 0x1000
        push     r13, r14                   # Save all registers for clean return to monitor
        push     r12, r14
        push     r11, r14
        push     r10, r14
        push      r9, r14
        push      r8, r14
        push      r7, r14
        push      r6, r14
        push      r5, r14
        push      r4, r14
        push      r3, r14
        push      r2, r14
        push      r1, r14                
        mov r9,r14                          # Snapshot stack pointer in case need of abort
        mov r12,r0,__global_vector          # Global vector and variable space
        mov r11,r0,__global_vector+0x1000   # Rest of space for local variables

        mov r10,r12,0x1000                  # initial free vector memory pointer to 0xEFFF and grows downwards
        mov r3,r11                          # duplicate r11 in r3 because standard subroutine entry will copy r3->r11
        mov r4,r0,__start                   # similar for r4 which will stack the subroutine entry point on entry
        jsr r13,r4                          # Call to main BCPL code
    
__sys_exit:
        halt r0,r0,0x999                    # Signal simulator to stop
        pop     r1, r14                     # restore all registers before returning to monitor
        pop     r2, r14
        pop     r3, r14
        pop     r4, r14
        pop     r5, r14
        pop     r6, r14
        pop     r7, r14
        pop     r8, r14
        pop     r9, r14
        pop    r10, r14
        pop    r11, r14
        pop    r12, r14
        pop    r13, r14
        mov pc, r13                         # return to monitor using return address on stack 

        ## BCPL generated code follows
''')

def process_syslib(syslib):
    # Verbatim print out of the syslib file
    with open( syslib, 'r') as f :
        print( ''.join(f.readlines()))


def process_sial( sialhdr, sialtext, noheader=False):
    ## Get the tokens from the sial.h file directly passed as an argument (in case they change again)
    sialop = {}
    
    with open(sialhdr,"r") as f:
        for l in f.readlines() :
            line = re.sub("//.*", "", l)
            if not re.match(".*({|}|MANIFEST).*", line):
                exec( line.strip(), globals(), sialop )

    sectionname = ""
    functionname = "" 
    firstlabel = False
    localcounter = 0
    global_vector = ["BLIB_abort"] * 0x1000
    global_vector[3] = "__sys" # will be defined in syslib.s
    gv_hightide = 0

    for i in sialtext:
        line = re.sub( '(?P<label>(L|M)\d*?)', '%s_\g<label>' % sectionname, i.strip())
        fields = line.split()
        if len(fields)>0 and i.startswith("F"):
            opcode = int(fields[0][1:])
            if opcode == sialop['f_section'] :    # section   Kn C1 ... Cn         Name of section
                sectionname = getstring(fields[1:])
                code("","Section - %s" % sectionname)            
            elif opcode == sialop['f_lp'] :       # lp        Pn         a := P!n 
                code("ld r1,r11,%d" % getnum(fields[1]), line)
            elif opcode == sialop['f_lg'] :       # lg        Gn         a := G!n 
                code("ld r1,r12,%d" % getnum(fields[1]), line)
            elif opcode == sialop['f_ll'] :       # ll        Ln         a := !Ln
                code("ld r1,r0,%s" % fields[1], line)            
            elif opcode == sialop['f_llp'] :      # llp       Pn         a := @ P!n
                code("mov r1, r11, %d" % getnum(fields[1]), line)
            elif opcode == sialop['f_llg'] :      # llg       Gn         a := @ G!n
                code("mov r1, r12, %d" % getnum(fields[1]), line)
            elif opcode == sialop['f_lll'] :      # lll       Ln         a := @ !Ln [ie address of label Ln]
                code("mov r1, r0, %s" % fields[1], line)
            elif opcode in (sialop['f_lf'],sialop['f_lw']):# lf or lw   Ln        a := byte or word address of Ln [using word address for both]
                code("mov r1,r0,%s" % fields[1],  line)
            elif opcode == sialop['f_l'] :        # l         Kn         a := n
                code("mov r1,r0,%d" % getnum(fields[1]), line)            
            elif opcode == sialop['f_lm'] :       # lm        Kn         a := - n 
                code("mov r1,r0,%d" % -getnum(fields[1]), line)
            elif opcode == sialop['f_sp'] :       # sp        Pn         P!n := a
                code("sto r1,r11,%d" % getnum(fields[1]), line)
            elif opcode == sialop['f_sg'] :       # sg        Gn         G!n := a
                code("sto r1,r12,%d" % getnum(fields[1]), line)
            elif opcode == sialop['f_sl'] :       # sl        Ln         !Ln := a
                code("sto r1,r0,%s" % fields[1], line)
            elif opcode == sialop['f_ap'] :       # ap        Pn         a := a + P!n
                code("ld r4,r11,%d" % getnum(fields[1]), line)   
                code("add r1,r4")
            elif opcode == sialop['f_ag'] :       # ag        Gn         a := a + G!n
                code("ld r4,r12,%d" % getnum(fields[1]), line)   
                code("add r1,r4")
            elif opcode == sialop['f_a'] :        # a         Kn         a := a + n
                n = getnum(fields[1])
                if 0<= n <= 15:
                    code("inc r1,%d" % n, line)                       
                else :
                    code("add r1,r0,%d" % n, line)   
            elif opcode == sialop['f_s'] :        # s         Kn         a := a - n
                n = getnum(fields[1])
                if 0<= n <= 15:
                    code("dec r1,%d" % n, line)                       
                else :
                    code("sub r1,r0,%d" % n, line)   
            elif opcode == sialop['f_lkp'] :      # lkp       Kk Pn      a := P!n!k
                code("ld r4,r11,%d" % getnum(fields[2]), line)
                code("ld r1,r4,%d" % getnum(fields[1]))
            elif opcode == sialop['f_lkg'] :      # lkg       Kk Gn      a := G!n!k
                code("ld r4,r12,%d" % getnum(fields[2]), line)
                code("ld r1,r4,%d" % getnum(fields[1]))
            elif opcode == sialop['f_st'] :       # !a := b
                code("sto r2,r1", line)
            elif opcode == sialop['f_stp'] :      # stp       Pn           P!n!a := b
                code("ld r4,r11,%d" % getnum(fields[1]), line)
                code("add r4,r1")
                code("sto r2,r4")
            elif opcode == sialop['f_stk'] :      # stk       Kn           a!n := b
                code("ld r4,r1,%d" % getnum(fields[1]), line)
                code("sto r2,r4")
            elif opcode == sialop['f_stkp'] :     # stkp      Kk Pn        P!n!k := a
                code("ld r4,r11,%d" % getnum(fields[2]), line)
                code("sto r1,r4,%d" % getnum(fields[1]))
            elif opcode == sialop['f_skg'] :      # skg       Kk Gn        G!n!k := a
                code("ld r4,r12,%d" % getnum(fields[2]), line)
                code("sto r1,r4,%d" % getnum(fields[1]))
            elif opcode == sialop['f_xst'] :      # xst                  !b := a
                code("sto r1,r2", line)
            elif opcode == sialop['f_rv'] :       # rv                   a := !a
                code("ld r1,r1", line)
            elif opcode == sialop['f_rvp'] :      # rvp       Pn         a := P!n!a
                code("ld r4,r11,%d" % getnum(fields[1]), line)
                code("add r4,r1")
                code("ld r1,r4")
            elif opcode == sialop['f_rvk'] :      # rvk       Kn         a := a!k
                code("ld r1,r1,%d" % getnum(fields[1]), line)
            elif opcode == sialop['f_atb'] :      # atb                  b := a
                code("mov r2, r1", line)
            elif opcode == sialop['f_atc'] :      # atc                  c := a
                code("mov r3, r1", line)
            elif opcode == sialop['f_bta'] :      # bta                  a := b
                code("mov r1, r2", line)
            elif opcode == sialop['f_btc'] :      # btc                  c := b
                code("mov r3, r2", line)
            elif opcode == sialop['f_xch'] :      # xch                  swap a and b
                code("mov r4, r1", line)
                code("mov r1, r2")
                code("mov r2, r4")
            elif opcode == sialop['f_and']:      # and                  a := b & a
                code("and r1,r2", line)            
            elif opcode == sialop['f_or'] :       # or                   a := b | a
                code("or r1,r2", line)            
            elif opcode == sialop['f_xor'] :      # xor                  a := b ^ a
                code("xor r1,r2", line)            
            elif opcode == sialop['f_eqv'] :      # eqv                  a := !(b ^ a)
                code("xor r1,r2", line)            
                code("not r1,r1")
            elif opcode == sialop['f_neg'] :      # neg                  a := -a
                code("not r1,r1,-1", line)            
            elif opcode == sialop['f_not'] :      # not                  a := ~ a
                code("not r1,r1", line)            
            elif opcode == sialop['f_abs'] :      # abs                  a := ABS a
                code("not r4,r1,-1", line)   # 2's complement A
                code("pl.mov r1,r4")         # if positive then get the positive version
            elif opcode in (sialop['f_lsh'],sialop['f_rsh']):
                # lsh                  a := b << a            
                # rsh                  a := b >> a
                codestring = "add r1,r1" if opcode==sialop['f_lsh'] else "asr r1,r1"
                code("mov r4,r1",line) # Get the number of places to shift in r4 + 1
                code("mov r1,r2")      # r2 preserved so shift in r1
                code("cmp r4,r0")      # is r4 ==0 (ie shift dist==0)?
                code("z.inc pc,_L%04d - PC" % (localcounter+1))
                code("_L%04d:" % localcounter)
                code(codestring)
                code("dec r4,1")
                code("nz.inc pc,_L%04d - PC" % localcounter) # PC op preserves Z flag from dec r4
                code("_L%04d:" % (localcounter+1))
                localcounter += 2
            elif opcode == sialop['f_atbl'] :     # atbl      Kk         b := a; a := k
                code("mov r2,r1", line)            
                code("mov r1,r0,%d" % getnum(fields[1]))
            elif opcode == sialop['f_atblp'] :    # atblp     Pn         b := a; a := P!n            
                code("mov r2,r1", line)
                code("ld r1,r11,%d" % getnum(fields[1]))                        
            elif opcode == sialop['f_atblg'] :    # atblg     Gn         b := a; a := G!n            
                code("mov r2,r1")
                code("ld r1,r12,%d" % getnum(fields[1]), line)                        
            elif opcode == sialop['f_lab'] :      # lab       Lm         Program label
                code("%s:" % fields[1])
                if firstlabel:
                    ## Got here with an OPC jsr 
                    code("sto r11,r3")   # C!0 := P
                    code("mov r11,r3")   # P   := C
                    code("sto r13,r11,1")# P!1 = return address
                    code("sto r4,r11,2") # P!2 = entry address
                    code("sto r1,r11,3") # P!3 = first argument                
                    firstlabel=False
            elif opcode == sialop['f_lstr'] :     # lstr      Mn                   a := Mn   (pointer to string)
                code("mov r1,r0,%s" % fields[1], line)
            elif opcode == sialop['f_entry'] :    # entry     Kn C1 ... Cn         Start of a function
                functionname = getstring(fields[1:])
                code("","Module Entry - %s" % functionname)
                if not functionname == "start" :
                    print("%s_%s:" % (sectionname,functionname))
                else: 
                    print("__start:")                   
                firstlabel = True
            elif opcode == sialop['f_j'] :       # j        Ln         Jump to Ln 
                code("mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jeq'] :     # jeq      Ln         Jump to Ln if a == b
                code("cmp r1,r2",line)
                code("z.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jne'] :     # jne      Ln         Jump to Ln if a != b
                code("cmp r1,r2",line)
                code("nz.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jge'] :     # jge      Ln         Jump to Ln if b >= a 
                code("cmp r2,r1",line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jgr'] :     # jgr      Ln         Jump to Ln if b > a [ ie a < b ] 
                code("cmp r1,r2",line)
                code("mi.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jgr0'] :     # jgr0      Ln       Jump to Ln if a > 0  [ie if 0 < a]
                code("cmp r0,r1",line)
                code("mi.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jle'] :     # jle      Ln         Jump to Ln if b <= a [ie a >= b]
                code("cmp r1,r2",line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jls'] :     # jls      Ln         Jump to Ln if b < a 
                code("cmp r2,r1",line)
                code("mi.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jeq0'] :     # jeq0      Ln         Jump to Ln if a == 0
                code("cmp r1,r0",line)
                code("z.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jge0'] :     # jge0      Ln         Jump to Ln if a >= 0
                code("cmp r1,r0",line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jls0'] :     # jls0      Ln         Jump to Ln if a < 0
                code("cmp r1,r0",line)
                code("mi.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jle0'] :     # jle0      Ln         Jump to Ln if a <= 0 [or 0>=a]
                code("cmp r0,r1",line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jne0'] :     # jne0      Ln         Jump to Ln if a != 0
                code("cmp r1,r0",line)
                code("nz.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_ip'] :      # ip        Pn           a := P!n + a; P!n := a
                code("ld r4,r11,%d" % getnum(fields[1]) ,line)
                code("add r1,r4")
                code("sto r1,r11,%d" % getnum(fields[1]))
            elif opcode == sialop['f_ig'] :      # ig        Gn           a := G!n + a; G!n := a
                code("ld r4,r12,%d" % getnum(fields[1]) ,line)
                code("add r1,r4")
                code("sto r1,r12,%d" % getnum(fields[1]))
            elif opcode == sialop['f_il'] :      # il        Ln           a := !Ln + a; !Ln := a
                code("ld r4,r0,%d" % getnum(fields[1]) ,line)
                code("add r1,r4")
                code("sto r1,r0,%d" % getnum(fields[1]))
            elif opcode == sialop['f_ikp'] :      #  ikp       Kk Pn      a := P!n + k; P!n := a
                code("ld  r1,r11,%d" % getnum(fields[2]), line)
                code("add r1,r0,%d" % getnum(fields[1]))
                code("sto r1,r11,%d" % getnum(fields[2]))
            elif opcode == sialop['f_ikg'] :      #  ikg       Kk Gn      a := G!n + k; G!n := a
                code("ld  r1,r12,%d" % getnum(fields[2]), line)
                code("add r1,r0,%d" % getnum(fields[1]))
                code("sto r1,r12,%d" % getnum(fields[2]))
            elif opcode == sialop['f_k'] :        #  k         Pn         Call  a(b,...) incrementing P by n and leaving b in A             
                code("mov r3,r11,%d" % getnum( fields[1]), line)
                ## Need to ensure that B is transferred to A on entry to the routine
                code("mov r4,r1")
                code("mov r1,r2")                        
                code("jsr r13,r4")
            elif opcode == sialop['f_kpg'] :      #  kpg       Pn Gg      Call Gg(a,...) incrementing P by n
                code("mov r3,r11,%d" % getnum( fields[1]), line)
                code("ld r4,r12,%d" % getnum(fields[2]))
                code("jsr r13,r4", "** Call to global function number %s ** " % getnum(fields[2]))
            elif opcode == sialop['f_modstart'] : # modstart                       Start of module 
                code("# Module start", line)
            elif opcode == sialop['f_mul'] :     # xmul                 a := a * b
                code("jsr r13,r0,__mul", line)     # need to have signed multiplication routine here for a * b
            elif opcode == sialop['f_add'] :     # add                  a := a + b
                code("add r1,r2", line)     
            elif opcode == sialop['f_sub'] :     # sub                  a := b - a
                code("sub r1,r2", line)
                code("not r1,r1,-1")
            elif opcode == sialop['f_xsub'] :    # xsub                 a := a - b  c := ??
                code("sub r1,r2", line)
            elif opcode == sialop['f_xdiv'] :     # xdiv                 a := a / b
                code("jsr r13,r0,__div", line)     # need to have signed division routine here for a/b
            elif opcode == sialop['f_div'] :      # div                 a := b / a
                # assume need to swap a and b over here via temp r4 before and after call to sdiv
                code("mov r4,r1", line)
                code("mov r1,r2")
                code("mov r2,r4")
                code("jsr r13,r0,__div")     # need to have signed division routine here for a/b
            elif opcode == sialop['f_rem'] :      # rem                  a := b REM a
                code("jsr r13,r0,__mod", line)     
            elif opcode == sialop['f_xrem'] :      # xrem                  a := a REM b ; c := ?            
                code("jsr r13,r0,__xmod", line)
            elif opcode in ( sialop['f_eq'], sialop['f_ne'], sialop['f_eq0'], sialop['f_ne0']) :
                # f_eq     a := b = a
                # f_ne     a := b != a
                # f_eq0    a := b = 0
                # f_ne0    a := b != 0
                reference_reg = 'r0' if opcode in ( sialop['f_eq0'], sialop['f_ne0']) else 'r2'
                # Do not-equal case first
                code("not r4,r0", line)                   # r4 <- all 1s
                code("sub r1,%s" % reference_reg)         # subtract reference from r1
                code("nz.mov r1,r4")                      # If not zero then answer is all 1's (else r1 already zero)
                if opcode in (sialop['f_eq'], sialop['f_eq0']) :
                    code("not r1,r1")                     # invert answer for equal case

            elif opcode == sialop['f_ls'] :           # ls                     a := b < a  [ie !(b >= a)]
                code ("not r4,r0", line)   # assume answer will be TRUE
                code ("cmp r2,r1")         # compare b with a
                code ("pl.xor r4,r0,0xFFFF") # invert answer if b >= a
                code ("mov r1, r4")        # transfer answer to A                    
            elif opcode == sialop['f_gr'] :           # ls                     a := b > a  [ie !(a >= b)]
                code ("not r4,r0", line)   # assume answer will be TRUE
                code ("cmp r1,r2")         # compare a with b
                code ("pl.xor r4,r0,0xFFFF") # invert answer if a >= b
                code ("mov r1, r4")        # transfer answer to A                   
            elif opcode == sialop['f_le'] :           # ls                     a := b <= a  [ie !(a<b)]
                code ("not r4,r0", line)   # assume answer will be TRUE
                code ("cmp r1,r2")         # compare a with b
                code ("mi.xor r4,r0,0xFFFF") # invert answer if a < b
                code ("mov r1, r4")        # transfer answer to A                   
            elif opcode == sialop['f_ge'] :           # ge                     a := b >= a  
                code ("not r4,r0", line)   # assume answer will be TRUE
                code ("cmp r2,r1")         # compare b with a
                code ("mi.xor r4,r0,0xFFFF") # invert answer if b < a
                code ("mov r1, r4")        # transfer answer to A                               
            elif opcode in ( sialop['f_ge0'], sialop['f_ls0']) :
                # f_ge0     a := a >= 0
                # f_ls0     a := a < 0
                # Do  >=  case first
                code("mov r4,r0", line)                   # answer = r4 <- all 0s
                code("cmp r1,r0")                         # subtract reference from r1
                code("pl.mov r4,r0,0xFFFF")               # If positive then invert answer is all 1's 
                if opcode == sialop['f_ge0']:
                    code("mov r1,r4")                     # return answer for a >= 0
                else:
                    code("not r1,r4")                     # invert answer for a < 0
            elif opcode in ( sialop['f_le0'], sialop['f_gr0']) :
                # f_gr0     a := a > 0
                # f_le0     a := a <= 0 [ie 0 >= a]
                # Do  <=  case first
                code("mov r4,r0", line)                   # answer = r4 <- all 0s
                code("cmp r0,r1")                         # subtract r1 from reference 
                code("pl.mov r4,r0,0xFFFF")               # If positive then answer is all 1's 
                if opcode == sialop['f_ge0']:
                    code("mov r1,r4")                     # return answer for 0 >= a
                else:
                    code("not r1,r4")                     # invert answer fors a > 0 
                    
            elif opcode == sialop['f_rtn'] :      # procedure return
                code("ld r4,r11,1", line) # get return address
                code("ld r11,r11")        # restore P pointer
                code("mov pc,r4")          # return
            elif opcode == sialop['f_static'] :   # static    Ln Kk W1 ... Wk      Static variable or table
                code("%s: WORD %s" % (fields[1], ','.join( [("%s"%getnum(i)) for i in fields[3:]])), line)
            elif opcode == sialop['f_string'] :   # string    Ml Kn C1 ... Cn      String constant
                # Encode string constants as word strings initially and make the various byte address
                # operations match (below)
                s = getstring(fields[2:])
                code("%s:" % fields[1],line)
    #            code("WORD %d " % getnum(fields[2]))
                code("WORD %d " % len(codecs.decode(s, 'unicode_escape'))) # deal with "\010" etc chars as 1 char
                code("STRING \"%s\"" % s)
                code("WORD 0x00") # Temporary
    
            elif opcode in (sialop['f_gbyt'],sialop['f_xgbyt'],sialop['f_pbyt'],sialop['f_xpbyt']):
                # These two function pairs identical if all strings are _words_ rather than bytes
                #   gbyt                   a := b % a
                #   xgbyt                  a := a % b
                #   pbyt                   b % a := c
                #   xpbyt                  a % b := c
                code("mov r4,r1", line)
                code("add r4,r2")            
                if opcode in (sialop['f_pbyt'],sialop['f_xpbyt']):
                    code("sto r3,r4")
                else:
                    code("ld  r1,r4")
    
            elif opcode == sialop['f_swb'] :      # swb       Kn Ld K1 L1 ... Kn Ln   Binary chop switch, Ld default
                # Jump table on value of A, specific values per label ?
                num_options = getnum(fields[1])            
                default  = fields[2]
                values = [getnum(fields[i]) for i in range(3,num_options*2+3,2)]            
                labels = [fields[i] for i in range(4,num_options*2+4,2)]
    
                code("",line)
                code("mov r4,r1","Copy A into tmp register")
                for (v,l) in zip(values,labels):
                    code("cmp r4,r0,%d" % v)
                    code("z.mov pc,r0,%s" % l)            
                code("mov pc,r0,%s" % default, "default jump target")
            elif opcode == sialop['f_swl'] :      #  swl       Kn Ld L1 ... Ln
                # Jump table on value of A
                # Kn is number of options
                # Ld is default destination
                # L1 is destination for value 0
                # Ln is destination for value n-1
    
                num_options = getnum(fields[1])
                default  = fields[2]
                labels = fields[3:]
                code("",line)
                code("mov r4,r1","Copy A into tmp register")
                for l in labels[:-1]:
                    code("z.mov pc,r0,%s" % l)            
                    code("dec r4,1")
                code("z.mov pc,r0,%s" % labels[-1])
                code("z.mov pc,r0,%s" % default, "default jump target")
            elif opcode == sialop['f_global'] :   # global    Kn G1 L1 ... Gn Ln   Global initialisation data
                code("", "# Global Resources: %s" % line)
                for i in range (2,len(fields)-1,2):
                    entry=getnum(fields[i])
                    value=fields[i+1]
                    global_vector[entry]=value
                    gv_hightide = (max(gv_hightide,entry))              
            elif opcode == sialop['f_modend'] :   # End of module
                code("","Module End - %s" % functionname)
            elif opcode in (sialop['f_res'],sialop['f_ldres']):
                code("", line + " [no code for %s]" % fields[0])
            else:
                print("** Opcode Not Handled - %s # %s" % (opcode,line))
    return(global_vector, gv_hightide)


if __name__ == "__main__" :     

    sialtext = []
    filename = []
    sialhdr = "" 
    if os.path.exists(os.path.join(os.environ['BCPLHDRS'],'sial.h')):
        sialhdr = os.path.join(os.environ['BCPLHDRS'],'sial.h')

    syslib = ""
    noheader = False

    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:g:s:nh", ["filename=","sialhdr=","syslib=","noheader", "help"])
    except getopt.GetoptError:
        showUsageAndExit()
    for opt, arg in opts:
        if ( opt in ("-f", "--filename")):
            filename.append(arg)        
        elif ( opt in ("-g", "--sialhdr")):
            sialhdr = arg
        elif ( opt in ("-s", "--syslib")):
            syslib = arg
        elif ( opt in ("-n", "--noheader")):
            noheader = True
        elif ( opt in ("-h", "--help")):
            showUsageAndExit()

    if len(filename) == 0 or sialhdr=="":
        showUsageAndExit()
    for f in filename + [sialhdr] + [syslib] :
        if ( not os.path.exists(f) ):
            print("Error - cannot open file %s" %f )
            sys.exit(1)

    ## Concatenate all SIAL files in order provided into a single text, merging
    ## split lines
    text = []
    for f in filename:
        with open(f,'r') as fh:
            prev = ""
            newline = ""
            for l in fh.readlines():
                if not l.startswith("F"):
                    prev = prev.rstrip() + l                    
                else:
                    newline = l
                    if prev != "":
                        sialtext.append(prev)
                    prev = newline
            # Flush last line
            sialtext.append(prev)

    if not noheader:
        print_header()
        
    ## Process the SIAL text and create the global vector data
    (global_vector, gv_hightide) = process_sial(sialhdr, sialtext, noheader)
    ## Include the syslib assember verbatim in the output
    if syslib != "":
        process_syslib(syslib)

    ## Stick the global vector on the end to follow all assembled code
    code('__global_vector:', 'Global Vector')
    for i in range(0,gv_hightide+(4-(gv_hightide % 4)),4):
        print("%-64s %-32s" % ("        WORD %s, %s, %s, %s" %  \
                                 (global_vector[i], global_vector[i+1], global_vector[i+2], global_vector[i+3])\
                                 , "# G%d G%d G%d G%d" % ( i,i+1,i+2,i+3)))
