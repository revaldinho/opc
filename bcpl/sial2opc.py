#!/usr/bin/env python3
## ============================================================================
## sial2opc.py - Backend code converter for SIAL (BCPL) intermediate code 
##               to OPC6 or OPC7 assembler
##
## COPYRIGHT 2017,2018,2019 Richard Evans
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

  sial2opc.py translates BCPL's SIAL intermediate code to OPC6 or OPC7 assembler

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

  -o  --opt                 Specify the sial2opc process to make optimizations of the SIAL
                            source code to better match the OPC target machine. Use of this
                            option requires the provided header file ext_sial.h which defines
                            additional opcodes for the SIAL machine.
  
  -7  --opc7                Select target CPU. Default is OPC6.
  -6  --opc6 
  -5  --opc5ls  (or --opc5)

All output is sent to stdout.

EXAMPLES ::

  sial2opc.py -f file1.sial -f bcpllib.sial -g ~/src/BCPL/cintcode/g/sial.h -s syslib.s

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

addsub_re  = re.compile(r"(\w*:)?\s*(?:z\.|1\.|0\.|nz\.|c\.|nc\.|pl\.|mi\.)?(add|sub)\s*(pc|r\d*)\s*,\s*r0,\s*(\-?(?:\w*|\d.*))($|\s.*)")
jsr_re     = re.compile(r"((?:\w*\:?)\s*)(\w*\.)?(jsr)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
mov_re     = re.compile(r"((?:\w*\:?)\s*)(\w*\.)?(mov)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
sto_re     = re.compile(r"((?:\w*\:?)\s*)(\w*\.)?(sto)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
ld_re      = re.compile(r"((?:\w*\:?)\s*)(\w*\.)?(ld)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
incdec_re  = re.compile(r"((?:\w*\:?)\s*)(\w*\.)?(inc|dec)\s*(r\d*|pc)\s*,(.*)")
pushpop_re = re.compile(r"((?:\w*\:?)\s*)(push|pop)\s*(r\d*|pc)\s*,\s*(.*?)((?:#|$).*)")

sialop = dict() 
cpu_target = "opc6"

def showUsageAndExit() :
    print (__doc__)
    sys.exit(2)


def getstring( s_list):
    # Convert string in format[ "K<len>", "C<char>" ...] into string
    # Non-printing characters, '"' and '\' are written as octal escapes because the
    # assembler ends a string at the first '"' and decodes it with 'unicode_escape'
    str = []
    for i in range (1, len(s_list)):
        c = int(s_list[i][1:]) & 0xFF
        if c < 32 or c > 126 or chr(c) in '"\\':
            c = '\\%03o' % c
        else:
            c = chr(c)
        str.append(c)
    return ''.join(str)

def getnum( str, ignore_errors=False ):
    # Convert literal of form K<n> to number
    num = int(str[1:])
    if not ignore_errors:
        if cpu_target in("opc6","opc5ls") and (num & 0xFFFF0000) and num > 0:
            raise BaseException("Error - getnum - found constant larger than 16bits: 0x%08X" % num)
        elif cpu_target == "opc7" and (num < -0x8000 or 0x7FFF < num < 0x0FFFF8000):
            raise BaseException("Error - getnum - found constant in illegal range: 0x%08X (%s)" % (num,str) )
    return (num)

def getnum20( str, ignore_errors=False ):
    # Convert literal of form K<n> to number
    num = int(str[1:])
    if not ignore_errors:
        if cpu_target == "opc7" and (num < -0x80000 or 0x7FFFF < num < 0x0FFF80000):
            raise BaseException("Error - getnum20 - found constant in illegal range: 0x%08X (%s)" % (num,str) )
    return (num)

def getlongnum( str, ispositive=True ):
    # Convert literal of form K<n> into a number loaded into r8
    largeconstcode = []
    num = int(str[1:])
    if not ispositive:
        num = ( -num & 0xFFFFFFFF)
    largeconstcode.append("lmov r8,0x%08X"      % (num & 0xFFFF))
    largeconstcode.append("movt r8,r0,0x%04X"   % ((num>>16) & 0xFFFF))
    return (largeconstcode)

def addsubtoincdec( s ) :
    # Swap add, sub with r0 operand and small immediate into inc, dec operations
    rstr = s
    mobj = addsub_re.match(s)
    if ( mobj ):
        try:
            n = int(mobj.group(4),0)
            if ( 0 < n < 16) :
                c1 =  (re.sub( r",\s*r0\s*", "", s))
                c2 =  (re.sub( r"add ", "inc ", c1))
                rstr =  (re.sub( r"sub ", "dec ", c2))
            elif ( -16 < n < 0) :
                c1 =  (re.sub( r",\s*r0\s*", "", s))
                c2 =  (re.sub( r"add ", "dec ", c1))
                c3 =  (re.sub( r"sub ", "inc ", c2))
                rstr =  (re.sub( r"\-", "", c3))
        except ValueError:            
            pass
    return rstr

def opc6to7( s):
    # Simple conversion of mov/jsr/sto/ld to long forms where r0 is used as source register.
    rstr = s
    for (op, regex) in zip( ["ljsr","lmov","lsto","lld"], [jsr_re,mov_re,sto_re,ld_re]):
         mobj = regex.match(s)
         if ( mobj ):         
             try :
                 n = int(mobj.group(5),0)
                 if n < 0 or (n&0x8000):
                     nstr = "0x%08X" % ((n | 0xFFFF0000) & 0xFFFFFFFF)
                 else:
                     nstr = "0x%08X" % (n & 0xFFFFFFFF)
             except:
                 nstr = mobj.group(5)
             pred_op = "%s%s" % ("" if mobj.group(2)==None else mobj.group(2), op )
             rstr = "%s%s %s,%s" % (mobj.group(1),pred_op,mobj.group(4).rstrip(),nstr.rstrip())
             break
    return rstr


def code ( codestring, source=""):
    # Remove trailing zeros where possible
    newcodestring = re.sub(r'((?:\w*\.)?\w*)\s*(r\d*|pc|psr)\s?,\s?(r\d+|pc|psr)\s?,\s?0($|\s+)', r'\1 \2,\3', codestring)
    if cpu_target == "opc6":        
        newcodestring = addsubtoincdec(newcodestring)
    elif cpu_target == "opc7":
        newcodestring = opc6to7(newcodestring)
        
    words = newcodestring.split()

    if len(words) > 0 and words[0].endswith(':'):
        leading = ""
        trailing = " "*8
    else :
        leading = " "*8
        trailing = ""
    print( "%s%-48s%s # %s" % (leading,newcodestring,trailing,source))

def signed_ge( x, y, source=""):
    # Set the sign bit of r4, and so the S flag, iff signed x >= y. Exact for all
    # values, unlike testing the sign of x-y which is wrong when x-y overflows:
    #   x >= y (signed) == (x >= y unsigned) ^ sign(x) ^ sign(y)
    # and the unsigned result is the carry from cmp. mov and xor leave the carry
    # alone; ror rotates it into the sign bit. Uses r4,r5 as temporaries.
    code("mov r4,%s" % x, source)
    code("xor r4,%s" % y)        # sign bit of r4 = sign(x) ^ sign(y)
    code("cmp %s,%s" % (x, y))   # C set iff x >= y unsigned
    code("ror r5,r0")            # r5 = C in the sign bit, all other bits zero
    code("xor r4,r5")            # sign bit of r4 set iff x >= y signed

def signed_compare( x, y, want_ge, source=""):
    # a := TRUE if signed x >= y (want_ge) or signed x < y (not want_ge), else FALSE
    signed_ge(x, y, source)
    code("add r4,r4")            # C = sign bit of r4
    code("mov r1,r0")            # default answer FALSE (mov leaves C alone)
    code("%s.mov r1,r0,-1" % ("c" if want_ge else "nc"))

def signed_jump( x, y, want_ge, label, source=""):
    # Jump to label if signed x >= y (want_ge) or signed x < y (not want_ge)
    signed_ge(x, y, source)
    code("%s.mov pc,r0,%s" % ("mi" if want_ge else "pl", label))

def word_bits():
    return 16 if cpu_target in ("opc6","opc5ls") else 32

def shift_const( reg, n, left):
    # Shift reg by a constant n places (logical shift for right shifts); OPC only
    # shifts by one place per instruction
    for i in range(n):
        code(("add %s,%s" if left else "LSR (%s,%s)") % (reg, reg))

def and_const( reg, value):
    # reg := reg & value for any word-sized constant. OPC7 sign-extends 16 bit
    # immediates, so values that don't fit in 15 bits go via the large constant
    # register r8
    value &= (1 << word_bits()) - 1
    if word_bits() == 16 or value <= 0x7FFF:
        code("and %s,r0,0x%04X" % (reg, value))
    else:
        for s in getlongnum("K%d" % value):
            code(s)
        code("and %s,r8" % reg)

def print_wrapper():
    ## OPC6 STACK at F7FF
    ## Allow 512 words of stack = 200h
    stack_setup             = "mov r14,r0,0xF7FF" if cpu_target in("opc6","opc5ls") else "lmov r14,0xFFFFFFFF"
    ## Need to allow space for TUBE ROM at top of address map for OPC6
    ## OPC7 uses 20 bit addresses, so start at 0x000FEFFF rather than 0xFFFFEFFF: the same
    ## memory, but getvec then returns positive addresses as BCPL programs expect (eg a
    ## midpoint (l+r)/2 of two addresses rounds differently if they are negative). lmov
    ## sign extends its 20 bit operand, so the top half is set with movt.
    initial_free_memory_ptr = "mov r10,r0,0xF5FF" if cpu_target in("opc6","opc5ls") else "lmov r10,0x0EFFF\n        movt r10,r0,0x000F"
    print('''
        ## --------------------------------------------------------------
        ## OPC assembly code generated from SIAL using sial2opc.py
        ## --------------------------------------------------------------
        ##
        ## OPC to SIAL resource mapping
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
        ## r8     == large constant register (OPC7 only)
        ## r9     == stack pointer on entry to BCPL (used for sys abort)
        ## r10    == Global memory wavefront
        ## r13    == link reg  
        ## r14    == stack ptr          
        ## --------------------------------------------------------------
        ## Cut off this section for running via the monitor on hardware
        ORG 0x0000 
        %s                 # Set stack to grow down from here for monitor
        mov   pc,r0,0x1000                  # Program start at 0x1000 for use with monitor/copro
        ## --------------------------------------------------------------
        ORG 0x1000
        PUSH  (r13)                   # Save all registers for clean return to monitor
        PUSH  (r12)
        PUSH  (r11)
        PUSH  (r10)
        PUSH  (r9)
        PUSH  (r8)
        PUSH  (r7)
        PUSH  (r6)
        PUSH  (r5)
        PUSH  (r4)
        PUSH  (r3)
        PUSH  (r2)
        PUSH  (r1)                
        mov r9,r14                          # Snapshot stack pointer in case need of abort
        mov r12,r0,__global_vector          # Global vector and variable space
        mov r11,r0,__global_vector+0x1000   # Rest of space for local variables
        %s                                  # initial free vector memory pointer grows downwards        
        mov r3,r11                          # duplicate r11 in r3 because standard subroutine entry will copy r3->r11
        mov r4,r0,__start                   # similar for r4 which will stack the subroutine entry point on entry
        jsr r13,r4                          # Call to main BCPL code
    
__sys_exit:
        halt r0,r0,0x0999                   # Signal simulator to stop
        POP    (r1)                         # restore all registers before returning to monitor
        POP    (r2)
        POP    (r3)
        POP    (r4)
        POP    (r5)
        POP    (r6)
        POP    (r7)
        POP    (r8)
        POP    (r9)
        POP    (r10)
        POP    (r11)
        POP    (r12)
        POP    (r13)
        mov pc, r13                         # return to monitor using return address on stack 

        ## BCPL generated code follows
    ''' % (stack_setup,initial_free_memory_ptr) )

def process_syslib(syslib):
    # Verbatim print out of the syslib file
    with open( syslib, 'r') as f :
        print( ''.join(f.readlines()))

def read_sial_header( sialhdr): 
    global sialop
    with open(sialhdr,"r") as f:
        for l in f.readlines() :
            line = re.sub(r"//.*", "", l)
            if not re.match(r".*({|}|MANIFEST).*", line):
                exec( line.strip(), globals(), sialop )
    # Headers before the 14/01/2019 renumbering call f_mod/f_xmod f_rem/f_xrem
    for (new, old) in (('f_mod','f_rem'), ('f_xmod','f_xrem')):
        if new not in sialop and old in sialop:
            sialop[new] = sialop[old]
    return sialop

def preprocess_sial( filename):
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
                        text.append(prev)
                    prev = newline
            # Flush last line
            text.append(prev)
    return text

def optimize_sial( sialtext):
    # Keyhole optimizations of the SIAL code - assume all lines are legal, no blanks and
    # continuations have been joined together by previous stage.
    global sialop, cpu_target
    i = 1
    prev_line = sialtext[0]
    prev_fields = None
    prev_opcode = 0

    # OPT-1: Look for loading/operation to create A, transfer A to B, load new value in A
    #        Replace with loading/operation to create B, load new value in A
    for i in range (1,len(sialtext)-1):        
        line = sialtext[i]
        fields = line.split()
        if len(fields)>0 and fields[0].startswith("F"):
            opcode = int(fields[0][1:])            
            if opcode in (sialop['f_atbl'],sialop['f_atblp'],sialop['f_atblg']):
                ## Prev opcode must be non-store, non-jump supporting B dest and/or src/dest reg swap
                if (sialop['f_lp'] <= prev_opcode <=  sialop['f_lm']) or \
                   (prev_opcode in (sialop['f_lkp'], sialop['f_lkg'],sialop['f_lstr'])) or \
                   (sialop['f_and'] <= prev_opcode <= sialop['f_eqv']) or \
                   (sialop['f_add'] <= prev_opcode <= sialop['f_sub']) or \
                   (sialop['f_neg'] <= prev_opcode <= sialop['f_abs']) :
                    #print ("# OPT-1a: Found load A followed by B :=A, load A")
                    #print ("#  %s ; %s " % (prev_fields[0], fields[0]))
                    newopcode = prev_opcode+sialop['b_offset']
                    ## Fix previous load to target B (r2)
                    sialtext[i-1] = ' '.join(["F%d" % newopcode] + prev_fields[1:])
                    ## Fix current load to not affect B (r2)
                    if opcode == sialop['f_atbl']:
                        opcode = sialop['f_l']
                    elif opcode == sialop['f_atblp']:
                        opcode = sialop['f_lp']
                    elif opcode == sialop['f_atblg']:
                        opcode = sialop['f_lg']
                    sialtext[i] = ' '.join(["F%d" % opcode] + fields[1:])
            elif opcode == sialop["f_atb"]:
                ## Next Opcode muxt be load of A, Prev opcode must be non-store, non-jump supporting B dest and/or src/dest reg swap
                next_fields = sialtext[i+1].split()            
                next_opcode = int(next_fields[0][1:])
                if ( sialop['f_lp'] <= next_opcode <= sialop['f_lm'] ) or \
                   (next_opcode==sialop['f_lkp']) or \
                   (next_opcode==sialop['f_lkg']):
                    if ( sialop['f_lp'] <= prev_opcode <=  sialop['f_lm']) or \
                       (prev_opcode in (sialop['f_lkp'], sialop['f_lkg'],sialop['f_lstr'])) or \
                       (sialop['f_and'] <= prev_opcode <= sialop['f_eqv']) or \
                       (sialop['f_add'] <= prev_opcode <= sialop['f_sub']) or \
                       (sialop['f_neg'] <= prev_opcode <= sialop['f_abs']) :
                        #print ("# OPT-1b: Found A := fn() ; B :=A ; Load A")
                        #print ("#  %s ; %s ; %s" % (prev_fields[0], fields[0], next_fields[0]))
                        newopcode = prev_opcode+sialop['b_offset']
                        ## Fix previous load to target B (r2)
                        sialtext[i-1] = ' '.join(["F%d" % newopcode] + prev_fields[1:])
                        ## Mark current opcode for deletion
                        sialtext[i] = ""            
            prev_line = line
            prev_fields = fields
            prev_opcode = opcode
  
    # OPT-2: Look for loading A with constant to be used in shift of B by 'A' places
    # Builds a new list rather than inserting into sialtext while iterating over it,
    # which would leave the last lines unvisited. Lines deleted by OPT-1 are dropped here.
    newtext = []
    prev_fields = None
    prev_opcode = 0
    for line in sialtext:
        fields = line.split()
        if len(fields)>0 and fields[0].startswith("F"):
            opcode = int(fields[0][1:])
            if opcode in (sialop['f_lsh'],sialop['f_rsh']):
                shift_a = "F%d" % (sialop['f_ext_lsr_a'] if opcode==sialop["f_rsh"] else sialop['f_ext_asl_a'])
                if prev_opcode == sialop['f_atbl'] and prev_fields[1] == "K1" :
                    #print ("# OPT-2a: Found ATB; load constant A + shift by A. Constant = %d" % getnum(prev_fields[1]))
                    # Replace the ATBL K1 with a single shift of A by 1
                    newtext[-1] = shift_a
                    line = None
                elif prev_opcode == sialop['f_l'] and prev_fields[1].startswith("K") and (0<getnum(prev_fields[1])<8):
                    shift_dist =  getnum(prev_fields[1])
                    #print ("# OPT-2b: Found load constant A + shift B by A. Constant = %d" % shift_dist )
                    # First shift is A := B shift by 1, subsequent shifts are A := A shift by 1
                    newtext[-1] = "F%d" % (sialop['f_ext_lsr'] if opcode==sialop["f_rsh"] else sialop['f_ext_asl'])
                    newtext.extend([shift_a] * (shift_dist-1))
                    line = None
            elif opcode in (sialop['f_div'],sialop['f_mod']) and prev_opcode in (sialop['f_l'],sialop['f_atbl']) \
                 and prev_fields[1].startswith("K"):
                # OPT-3 (added 25/10/2026): a := b / n or b MOD n for a constant n = 2**k, done
                # inline with shifts or a mask. Up to 2**14 on OPC6 (16 bit) and 2**23 on OPC7
                n = int(prev_fields[1][1:])
                if 0 < n <= (1 << (14 if cpu_target in ("opc6","opc5ls") else 23)) and n & (n-1) == 0:
                    if prev_opcode == sialop['f_atbl']:
                        newtext[-1] = "F%d" % sialop['f_atb']   # keep atbl's b := a
                    else:
                        newtext.pop()                          # the l Kn
                    newop = sialop['f_ext_divp2'] if opcode == sialop['f_div'] else sialop['f_ext_modp2']
                    line = "F%d K%d" % (newop, n)
            prev_fields = fields
            prev_opcode = opcode
        if line:
            newtext.append(line)
    return newtext

def process_sial(sialtext):
    global sialop
    sectionname = ""
    functionname = "" 
    firstlabel = False
    localcounter = 0
    global_vector = ["BLIB_abort"] * 0x1000
    global_vector[3] = "__sys" # will be defined in syslib.s
    gv_hightide = 0
    b_offset = sialop.get('b_offset', 250) # only defined in ext_sial.h

    for i in sialtext:
        line = re.sub( r'\b(?P<label>(L|M)\d+)', r'%s_\g<label>' % sectionname, i.strip())
        fields = line.split()
        if len(fields)>0 and i.startswith("F"):
            opcode = int(fields[0][1:])

            if opcode >= b_offset:
                dest_r = "r2"
                src_r = "r1"
                unarysrc_r = "r1"
                opcode  = opcode - b_offset
            else:
                dest_r = "r1"
                unarysrc_r = "r1"                
                src_r = "r2"
                            
            if opcode == sialop['f_section'] :    # section   Kn C1 ... Cn         Name of section
                sectionname = getstring(fields[1:])
                code("","Section - %s" % sectionname)            
            elif opcode == sialop['f_lp'] :       # lp        Pn         a := P!n 
                code("ld %s,r11,%d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_lg'] :       # lg        Gn         a := G!n 
                code("ld %s,r12,%d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_ll'] :       # ll        Ln         a := !Ln
                code("ld %s,r0,%s" % (dest_r, fields[1]), line)            
            elif opcode == sialop['f_llp'] :      # llp       Pn         a := @ P!n
                code("mov %s, r11, %d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_llg'] :      # llg       Gn         a := @ G!n
                code("mov %s, r12, %d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_lll'] :      # lll       Ln         a := @ !Ln [ie address of label Ln]
                code("mov %s, r0, %s" % (dest_r, fields[1]), line)
            elif opcode == sialop['f_lf']:        # lf        Ln        a := byte address of Ln
                code("mov %s,r0,%s" % (dest_r, fields[1]),  line)
            elif opcode == sialop['f_lw']:        # lw        Ln        Load word from label ? Not in SIAL spec doc
                code("ld %s,r0,%s" % (dest_r, fields[1]),  line)
            elif opcode == sialop['f_l'] :        # l         Kn         a := n
                try:
                    n =  getnum(fields[1])
                    code("mov %s,r0,%d" % (dest_r, n), line)
                except BaseException as e:
                    if cpu_target == "opc7":
                        try:
                            n = getnum20(fields[1])
                            code("lmov %s,%d" % (dest_r, n), line)
                        except:
                            code("",line)
                            for s in getlongnum(fields[1]):
                                code(s)
                            code("mov %s,r8" % dest_r)                        
                    else:
                        raise e
            elif opcode == sialop['f_lm'] :       # lm        Kn         a := - n
                if cpu_target in("opc6","opc5ls"):
                    code("mov %s,r0,%d" % (dest_r, -getnum(fields[1])), line)
                else:
                    try:
                        code("lmov %s,%d" % (dest_r, -getnum20(fields[1])), line)
                    except BaseException as e:
                        code ("",line)
                        for s in getlongnum(fields[1], False ):
                            code(s);
                        code("mov  %s,r8" % dest_r )                        
            elif opcode == sialop['f_sp'] :       # sp        Pn         P!n := a
                code("sto %s,r11,%d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_sg'] :       # sg        Gn         G!n := a
                code("sto %s,r12,%d" % (dest_r, getnum(fields[1])), line)
            elif opcode == sialop['f_sl'] :       # sl        Ln         !Ln := a
                code("sto %s,r0,%s" % (dest_r, fields[1]), line)
            elif opcode == sialop['f_ap'] :       # ap        Pn         a := a + P!n
                code("ld r4,r11,%d" % getnum(fields[1]), line)   
                code("add r1,r4")
            elif opcode == sialop['f_ag'] :       # ag        Gn         a := a + G!n
                code("ld r4,r12,%d" % getnum(fields[1]), line)   
                code("add r1,r4")
            elif opcode in (sialop['f_a'], sialop['f_s']) :        # a         Kn         a := a + n
                operation = "add" if opcode == sialop['f_a'] else "sub"
                
                try:                                               # s         Kn         a := a - n                    
                    n = getnum(fields[1])
                    code("%s r1,r0,%d" % (operation,n), line)
                except BaseException as e:
                    if cpu_target == "opc7":
                        code ("",line)
                        for s in getlongnum(fields[1]):
                            code(s);                        
                        code("%s %s,r8" % (operation,dest_r) )
                    else:
                        raise e
            elif opcode == sialop['f_s'] :        
                n = getnum(fields[1])
                code("sub r1,r0,%d" % n, line)   
            elif opcode in (sialop['f_lkp'], sialop['f_lkg']):
                # lkp       Kk Pn      a := P!n!k
                # lkg       Kk Gn      a := G!n!k
                (k,n) =  (getnum(fields[1]),getnum(fields[2]))
                pointer_reg = 'r11' if opcode==sialop['f_lkp'] else 'r12'
                code("ld r4,%s,%d" % (pointer_reg, n), line)                    
                code("ld %s,r4,%d" % (dest_r, k))
            elif opcode == sialop['f_st'] :       # !a := b
                code("sto r2,r1", line)
            elif opcode == sialop['f_stp'] :      # stp       Pn           P!n!a := b
                n = getnum(fields[1])
                code("ld r4,r11,%d" % getnum(fields[1]), line)
                code("add r4,r1")
                code("sto r2,r4")
            elif opcode == sialop['f_stk'] :      # stk       Kn           a!n := b
                n = getnum(fields[1])
                code("sto r2,r1,%d" % n, line)                
            elif opcode in ( sialop['f_stkp'], sialop['f_skg'] )  :
                # stkp      Kk Pn        P!n!k := a
                # skg       Kk Gn        G!n!k := a                             
                (k,n) =  (getnum(fields[1]),getnum(fields[2]))
                pointer_reg = 'r11' if opcode==sialop['f_stkp'] else 'r12'
                code("ld r4,%s,%d" % (pointer_reg, n), line)                    
                code("sto r1,r4,%d" % k)
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
                code("and %s,%s" % (dest_r, src_r), line)            
            elif opcode == sialop['f_or'] :       # or                   a := b | a
                code("or %s,%s" % (dest_r, src_r), line)            
            elif opcode == sialop['f_xor'] :      # xor                  a := b ^ a
                code("xor %s,%s" % (dest_r, src_r), line)            
            elif opcode == sialop['f_eqv'] :      # eqv                  a := !(b ^ a)
                code("xor %s,%s" % (dest_r, src_r), line)            
                code("not %s,%s" % (dest_r, dest_r))
            elif opcode == sialop['f_neg'] :      # neg                  a := -a [b := -a]
                code("not %s,%s,-1" % (dest_r, unarysrc_r), line)            
            elif opcode == sialop['f_not'] :      # not                  a := ~ a [b := ~a]
                code("not %s,%s" % (dest_r, unarysrc_r), line)            
            elif opcode == sialop['f_abs'] :      # abs                  a := ABS a                
                if ( dest_r == unarysrc_r):
                    code("not r4,%s,-1" % unarysrc_r, line)   # 2's complement A                                        
                    code("pl.mov %s,r4" % dest_r)             # if positive then get the positive version
                else:   ## b := ABS a  or c := ABS a
                    code("not %s,%s,-1" % (dest_r, unarysrc_r), line)   # 2's complement A into dest
                    code("mi.mov %s,%s" % (dest_r, unarysrc_r))         # if negative then get the original instead
            elif opcode in (sialop['f_lsh'],sialop['f_rsh']):
                # lsh                  a := b << a            
                # rsh                  a := b >> a
                codestring = "add r1,r1" if opcode==sialop['f_lsh'] else "LSR (r1,r1)"
                code("mov r4,r1",line) # Get the number of places to shift in r4 + 1
                code("mov r1,r2")      # r2 preserved so shift in r1
                if cpu_target == "opc7":
                    # Changed 25/10/2026: distances of 8 or more (unsigned, so also negative
                    # ones) go to a syslib routine which shifts whole bytes with bperm and
                    # leaves 0-7 places, done by jumping into a run of 7 single shifts
                    code("cmp r4,r0,8")
                    code("c.jsr r13,r0,%s" % ("__lsh_bytes" if opcode==sialop['f_lsh'] else "__rsh_bytes"))
                    code("not r4,r4,-1")                                # r4 := -places
                    code("add pc,r4,_L%04d - PC" % localcounter)        # skip 7-places shifts
                    for n in range(7):
                        code(codestring)
                    code("_L%04d:" % localcounter)
                else:
                    code("cmp r4,r0")      # is r4 ==0 (ie shift dist==0)?
                    if cpu_target == "opc6":
                        code("z.inc pc,_L%04d - PC" % (localcounter+1))
                    else: 
                        code("z.add pc,r0,_L%04d - PC" % (localcounter+1))                   
                    code("_L%04d:" % localcounter)
                    code(codestring)
                    code("sub r4,r0,1")                
                    if cpu_target == "opc6":
                        code("nz.inc pc,_L%04d - PC" % localcounter) # PC op preserves Z flag from dec r4
                    else:
                        code("nz.add pc,r0,_L%04d - PC" % localcounter) # PC op preserves Z flag from dec r4                    
                    code("_L%04d:" % (localcounter+1))
                localcounter += 2
            elif opcode == sialop['f_ext_asl']: # f_ext_asl=      175    //  a := b << 1
                code("mov r1,r2", line)
                code("add r1,r1")
            elif opcode == sialop['f_ext_lsr']: # f_ext_asl=      175    //  a := b >> 1
                code("LSR (r1,r2)")
            elif opcode == sialop['f_ext_asl_a']: # f_ext_asl_a=      177    //  a := a << 1
                code("add r1,r1", line)
            elif opcode == sialop['f_ext_lsr_a']: # f_ext_lsr_a=      178    //  a := a >> 1
                code("LSR (r1,r1)", line)
            elif opcode == sialop['f_atbl'] :     # atbl      Kk         b := a; a := k
                if cpu_target in("opc6","opc5ls"):
                    n = getnum(fields[1])
                    code("mov r2,r1", line)
                    code("mov r1,r0,%d" % n)
                else:
                    code("mov r2,r1", line)                    
                    try:
                        n = getnum20(fields[1])
                        code("lmov r1,%d" % n)
                    except BaseException as e:
                        for s in getlongnum(fields[1]):
                            code(s);                        
                        code("mov r1,r8")                                                
            elif opcode == sialop['f_atblp'] :    # atblp     Pn         b := a; a := P!n            
                code("mov r2,r1", line)
                code("ld r1,r11,%d" % getnum(fields[1]))                        
            elif opcode == sialop['f_atblg'] :    # atblg     Gn         b := a; a := G!n            
                code("mov r2,r1")
                code("ld r1,r12,%d" % getnum(fields[1]), line)                        
            elif opcode == sialop['f_lab'] :      # lab       Lm         Program label
                code("%s:" % fields[1], line)
                if firstlabel:
                    ## Got here with an OPC jsr 
                    code("sto r11,r3")   # C!0 := P
                    code("mov r11,r3")   # P   := C
                    code("sto r13,r11,1")# P!1 = return address
                    code("sto r4,r11,2") # P!2 = entry address
                    code("sto r1,r11,3") # P!3 = first argument                
                    firstlabel=False
            elif opcode == sialop['f_lstr'] :     # lstr      Mn                   a := Mn   (pointer to string)
                code("mov %s,r0,%s" % (dest_r, fields[1]), line)
            elif opcode == sialop['f_entry'] :    # entry     Kn C1 ... Cn         Start of a function
                functionname = getstring(fields[1:])
                code("","Module Entry - %s" % functionname)
                if not functionname == "start" :
                    print("%s_%s:" % (sectionname,functionname))
                else: 
                    print("__start:")                   
                firstlabel = True
            elif opcode == sialop['f_j'] :       # j        Ln         Jump to Ln
                code("mov pc,r0,%s" % fields[1], line)
            elif opcode == sialop['f_goto'] :    # goto                 Jump to the address in a
                # Added 23/10/2026
                code("mov pc,r1", line)
            elif opcode == sialop['f_jge0m'] :   # jge0m    Mn         Jump to Mn if a >= 0
                # Added 23/10/2026
                code("cmp r1,r0", line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_mlab'] :    # mlab     Mn         Destination of jge0m
                # Added 23/10/2026
                code("%s:" % fields[1], line)
            elif opcode == sialop['f_nop'] :     # nop                  No operation
                # Added 23/10/2026
                code("", line + " [no code for nop]")
            elif opcode == sialop['f_selld'] :   # selld    Klen Ksh   a := SLCT len:sh:0 OF a
                # Added 23/10/2026
                # a := (!a >> sh) & mask with a logical shift; len=0 means all bits above sh
                (length, sh) = (getnum(fields[1]), getnum(fields[2]))
                if length + sh > word_bits():
                    raise BaseException("Error - selld field len %d sh %d does not fit in a %d bit word" % (length, sh, word_bits()))
                code("ld r1,r1", line)
                shift_const("r1", sh, False)
                if 0 < length < word_bits():
                    and_const("r1", (1 << length) - 1)
            elif opcode in (sialop['f_selst'], sialop['f_xselst']) :
                # selst    Kop Klen Ksh   SLCT len:sh:0 OF a := b
                # xselst   Kop Klen Ksh   SLCT len:sh:0 OF b := a
                # Added 23/10/2026
                # Only op = sf_none (0) is generated for standard BCPL; other ops are xbcpl's
                # op:= assignments
                (sfop, length, sh) = (getnum(fields[1]), getnum(fields[2]), getnum(fields[3]))
                if sfop != 0:
                    raise BaseException("Error - selst/xselst with op %d (xbcpl op:= assignment) is not supported" % sfop)
                if length + sh > word_bits():
                    raise BaseException("Error - selst field len %d sh %d does not fit in a %d bit word" % (length, sh, word_bits()))
                (addr_r, val_r) = ("r1", "r2") if opcode == sialop['f_selst'] else ("r2", "r1")
                allones = (1 << word_bits()) - 1
                fieldmask = (((1 << length) - 1 if length else allones) << sh) & allones
                code("mov r5,%s" % val_r, line)
                shift_const("r5", sh, True)
                and_const("r5", fieldmask)           # new field value in place
                code("ld r4,%s" % addr_r)
                and_const("r4", ~fieldmask)          # clear the old field
                code("or r4,r5")
                code("sto r4,%s" % addr_r)
            elif opcode == sialop['f_jeq'] :     # jeq      Ln         Jump to Ln if a == b
                code("cmp r1,r2",line)
                code("z.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jne'] :     # jne      Ln         Jump to Ln if a != b
                code("cmp r1,r2",line)
                code("nz.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jge'] :     # jge      Ln         Jump to Ln if b >= a
                signed_jump("r2", "r1", True, fields[1], line)
            elif opcode == sialop['f_jgr'] :     # jgr      Ln         Jump to Ln if b > a [ ie a < b ]
                signed_jump("r1", "r2", False, fields[1], line)
            elif opcode == sialop['f_jgr0'] :     # jgr0      Ln       Jump to Ln if a > 0  [ie if 0 < a]
                code("cmp r1,r0", line)
                code("mi.mov r4,r0")             # Z := 1 if a < 0, so Z is set iff a <= 0 (OPC6 cannot predicate cmp)
                code("nz.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jle'] :     # jle      Ln         Jump to Ln if b <= a [ie a >= b]
                signed_jump("r1", "r2", True, fields[1], line)
            elif opcode == sialop['f_jls'] :     # jls      Ln         Jump to Ln if b < a
                signed_jump("r2", "r1", False, fields[1], line)
            elif opcode == sialop['f_jeq0'] :     # jeq0      Ln         Jump to Ln if a == 0
                code("cmp r1,r0",line)
                code("z.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jne0'] :     # jne0      Ln         Jump to Ln if a != 0
                code("cmp r1,r0",line)
                code("nz.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jge0'] :     # jge0      Ln         Jump to Ln if a >= 0
                code("cmp r1,r0",line)
                code("pl.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jls0'] :     # jls0      Ln         Jump to Ln if a < 0
                code("cmp r1,r0",line)
                code("mi.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_jle0'] :     # jle0      Ln         Jump to Ln if a <= 0 [or 0>=a]
                code("cmp r1,r0", line)
                code("mi.mov r4,r0")             # Z := 1 if a < 0, so Z is set iff a <= 0 (OPC6 cannot predicate cmp)
                code("z.mov pc,r0,%s" % fields[1])
            elif opcode == sialop['f_ip'] :      # ip        Pn           a := P!n + a; P!n := a
                code("ld r4,r11,%d" % getnum(fields[1]) ,line)
                code("add r1,r4")
                code("sto r1,r11,%d" % getnum(fields[1]))
            elif opcode == sialop['f_ig'] :      # ig        Gn           a := G!n + a; G!n := a
                code("ld r4,r12,%d" % getnum(fields[1]) ,line)
                code("add r1,r4")
                code("sto r1,r12,%d" % getnum(fields[1]))
            elif opcode == sialop['f_il'] :      # il        Ln           a := !Ln + a; !Ln := a
                code("ld r4,r0,%s" % fields[1] ,line)
                code("add r1,r4")
                code("sto r1,r0,%s" % fields[1])
            elif opcode in (sialop['f_ikp'],sialop['f_ikg']) :
                #  ikp       Kk Pn      a := P!n + k; P!n := a
                #  ikg       Kk Gn      a := G!n + k; G!n := a
                ptr = "r11" if opcode==sialop['f_ikp'] else "r12"                
                code("ld  r1,%s,%d" % (ptr,getnum(fields[2])), line)
                if cpu_target in("opc6","opc5ls"):
                    code("add r1,r0,%d" % getnum(fields[1]))
                else:
                    try:
                        code("add r1,r0,%d" % getnum(fields[1]))
                    except BaseException as e:
                        for s in getlongnum(fields[1]):
                            code(s);
                        code("add r1,r8" )                            
                code("sto r1,%s,%d" % (ptr,getnum(fields[2])))
            elif opcode == sialop['f_ikl'] :     # ikl       Kk Ln      a := !Ln + k; !Ln := a
                # Added 23/10/2026
                code("ld r1,r0,%s" % fields[2], line)
                try:
                    code("add r1,r0,%d" % getnum(fields[1]))
                except BaseException as e:
                    if cpu_target == "opc7":
                        for s in getlongnum(fields[1]):
                            code(s)
                        code("add r1,r8")
                    else:
                        raise e
                code("sto r1,r0,%s" % fields[2])
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
                code("add %s,%s" % (dest_r, src_r), line)     
            elif opcode == sialop['f_sub'] :     # sub                  a := b - a  [b := b - a]
                if dest_r == "r1":
                     code("sub r1,r2", line)
                     code("not r1,r1,-1")
                else:
                     code("sub r2,r1", line)
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
            elif opcode in (sialop['f_ext_divp2'], sialop['f_ext_modp2']):
                # f_ext_divp2  Kn   a := b / n      n = 2**k, from OPT-3 (added 25/10/2026)
                # f_ext_modp2  Kn   a := b MOD n
                # BCPL / truncates towards zero, so a negative b gets n-1 added before an
                # arithmetic shift; b MOD n = b - (that rounded b with its low k bits clear)
                n = int(fields[1][1:])               # up to 2**23: n-1 and -n may need r8
                dest = "r1" if opcode == sialop['f_ext_divp2'] else "r4"
                code("", line)
                if n-1 > 0x7FFF:                     # OPC7 only: n-1 in the large constant register
                    for s in getlongnum("K%d" % (n-1)):
                        code(s)
                code("mov %s,r2" % dest)             # sets the S flag from b
                code("mi.add %s,%s" % (dest, "r8" if n-1 > 0x7FFF else "r0,%d" % (n-1)))
                if opcode == sialop['f_ext_divp2']:
                    for i in range(n.bit_length()-1):
                        code("asr r1,r1")
                else:
                    if n <= 0x8000:
                        code("and r4,r0,%d" % -n)    # -n as a sign extended immediate
                    else:
                        and_const("r4", -n)
                    code("mov r1,r2")
                    code("sub r1,r4")
            elif opcode == sialop['f_mod'] :      # mod                  a := b MOD a
                code("jsr r13,r0,__mod", line)
            elif opcode == sialop['f_xmod'] :      # xmod                  a := a MOD b ; c := ?
                code("jsr r13,r0,__xmod", line)
            elif opcode in ( sialop['f_eq'], sialop['f_ne'], sialop['f_eq0'], sialop['f_ne0']) :
                # f_eq     a := b = a
                # f_ne     a := b != a
                # f_eq0    a := a = 0
                # f_ne0    a := a != 0
                reference_reg = 'r0' if opcode in ( sialop['f_eq0'], sialop['f_ne0']) else 'r2'
                code("sub r1,%s" % reference_reg)         # subtract reference from r1
                code("nz.mov r1,r0,0xFFFF")               # If not zero then answer is all 1's (else r1 already zero)
                if opcode in (sialop['f_eq'], sialop['f_eq0']) :
                    code("not r1,r1")                     # invert answer for equal case

            elif opcode == sialop['f_ls'] :           # ls                     a := b < a
                signed_compare("r2", "r1", False, line)
            elif opcode == sialop['f_gr'] :           # gr                     a := b > a  [ie a < b]
                signed_compare("r1", "r2", False, line)
            elif opcode == sialop['f_le'] :           # le                     a := b <= a  [ie a >= b]
                signed_compare("r1", "r2", True, line)
            elif opcode == sialop['f_ge'] :           # ge                     a := b >= a
                signed_compare("r2", "r1", True, line)
            elif opcode == sialop['f_ge0'] :          # ge0                    a := a >= 0
                code("add r1,r1", line)      # C = sign bit of a
                code("mov r1,r0")            # default answer FALSE (mov leaves C alone)
                code("nc.mov r1,r0,-1")
            elif opcode == sialop['f_ls0'] :           # ls0                     a := a < 0  [ ie !(0 <= a) ]
                code ("cmp r1,r0", line)           
                code ("mi.mov r1,r0,0xFFFF") # If negative result set r1 all 1's
                code ("pl.mov r1,r0")        # If positive result set r1 all 0's (won't be triggered by previous condition)
            elif opcode in (sialop['f_gr0'], sialop['f_le0']):
                # gr0                    a := a > 0  [ie 0 < a]
                # le0                    a := a <= 0  [ie 0 >= a]
                code("cmp r1,r0", line)
                code("mi.mov r1,r0")         # a < 0 becomes 0, so Z is set iff a <= 0
                code("nz.mov r1,r0,-1")      # a > 0 becomes TRUE; otherwise a is now 0
                if opcode == sialop['f_le0']:
                    code("not r1,r1")
            elif opcode == sialop['f_rtn'] : # procedure return
                code("ld r4,r11,1", line)  # get return address
                code("ld r11,r11" )        # restore P pointer
                code("mov pc,r4")          # return
            elif opcode == sialop['f_static'] :   # static    Ln Kk W1 ... Wk      Static variable or table
                code("%s: WORD %s" % (fields[1], ','.join( [("%s"%getnum(i, True)) for i in fields[3:]])), line)
            elif opcode == sialop['f_string'] :   # string    Ml Kn C1 ... Cn      String constant
                s = getstring(fields[2:])
                code("%s:" % fields[1],line)
                code("PBSTRING \"%s\"" % s)
            elif opcode == sialop['f_const'] :   # const  Ml Wnnn      Long Integer Constant (double word)                
                n = getnum(fields[2], True)
                code("%s:" % fields[1],line)
                code("WORD 0x%08X" %  (n & 0xFFFFFFFF))
            elif opcode == sialop['f_gbyt']:      #   gbyt                   a := b % a
                code( "jsr r13,r0,__gbyt", line )
            elif opcode == sialop['f_xgbyt']:     #   xgbyt                  a := a % b
                code( "jsr r13,r0,__xgbyt", line )
            elif opcode == sialop['f_pbyt']:      #   pbyt                   b % a := c
                code( "jsr r13,r0,__pbyt", line )
            elif opcode == sialop['f_xpbyt']:     #   xpbyt                  a % b := c
                code( "jsr r13,r0,__xpbyt", line )

            elif opcode == sialop['f_swb'] :      # swb       Kn Ld K1 L1 ... Kn Ln   Binary chop switch, Ld default
                # Jump table on value of A, specific values per label ?
                num_options = getnum(fields[1])            
                default  = fields[2]
                value_fields = [fields[i] for i in range(3,num_options*2+3,2)]            
                labels = [fields[i] for i in range(4,num_options*2+4,2)]            
                code("",line)
                code("mov r4,r1","Copy A into tmp register")
                for (vf,l) in zip(value_fields,labels):
                    try:
                        v = getnum(vf)
                        code("cmp r4,r0,%d" % v)
                        code("z.mov pc,r0,%s" % l)
                    except BaseException as e:
                        if cpu_target == "opc7":
                            for s in getlongnum(vf):
                                code(s)
                            code("cmp r4,r8")
                            code("z.mov pc,r0,%s" % l)
                        else:
                            raise e                            
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
                    code("sub r4,r0,1")
                code("z.mov pc,r0,%s" % labels[-1])
                code("mov pc,r0,%s" % default, "default jump target")
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
                # Stop rather than emit a comment line: the assembler ignores such lines,
                # which would silently leave the operation out of the program
                names = [k for (k,v) in sialop.items() if v == opcode and k.startswith("f_")]
                name  = names[0][2:] if names else "unknown"
                note  = " (floating point is not supported)" if name.startswith(("f","jf")) else ""
                sys.stderr.write("sial2opc.py: Error - SIAL opcode %d (%s) is not supported%s\n    at: %s\n" % (opcode, name, note, line))
                sys.exit(1)
    return(global_vector, gv_hightide)


if __name__ == "__main__" :     
    sialtext = []
    filename = []
    sialhdr = "" 
    bcplhdrs = os.environ.get('BCPLHDRS', '')
    if bcplhdrs and os.path.exists(os.path.join(bcplhdrs,'sial.h')):
        sialhdr = os.path.join(bcplhdrs,'sial.h')

    syslib = ""
    optimize = False
    noheader = False

    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:g:s:no567h", ["filename=","sialhdr=","syslib=","noheader", "opt","opc5", "opc5ls","opc6","opc7","help"])
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
        elif ( opt in ("-o", "--opt")):
            optimize = True            
        elif ( opt in ("-5", "--opc5", "--opc5ls")):
            cpu_target = "opc5ls"
        elif ( opt in ("-6", "--opc6")):
            cpu_target = "opc6"
        elif ( opt in ("-7", "--opc7")):
            cpu_target = "opc7"          
        elif ( opt in ("-h", "--help")):
            showUsageAndExit()

    if len(filename) == 0 or sialhdr=="":
        showUsageAndExit()        
    for f in filename + [sialhdr] + [syslib] :
        if ( f and not os.path.exists(f) ):
            print("Error - cannot open file %s" %f )
            sys.exit(1)

    read_sial_header( sialhdr )            

    sialtext = preprocess_sial( filename )

    if optimize:
        sialtext = optimize_sial( sialtext)
        
    if not noheader:
        print_wrapper()
        
    ## Process the SIAL text and create the global vector data
    (global_vector, gv_hightide) = process_sial(sialtext)
    ## Include the syslib assember verbatim in the output
    if syslib != "":
        process_syslib(syslib)

    ## Stick the global vector on the end to follow all assembled code
    code('__global_vector:', 'Global Vector')
    for i in range(0,gv_hightide+(4-(gv_hightide % 4)),4):
        print("%-64s %-32s" % ("        WORD %s, %s, %s, %s" %  \
                                 (global_vector[i], global_vector[i+1], global_vector[i+2], global_vector[i+3])\
                                 , "# G%d G%d G%d G%d" % ( i,i+1,i+2,i+3)))
