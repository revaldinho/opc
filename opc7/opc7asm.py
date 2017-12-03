#!/usr/bin/env python3
## ============================================================================
## opc7asm.py - word oriented assembler for the OPC7 CPU
##
## COPYRIGHT 2017 Richard Evans
##
## This file is part of the One Page Computing project: http://revaldinho.github.io/opc
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## See  <http://www.gnu.org/licenses/> for a copy of the GNU Lesser General
## Public License
##
## ============================================================================
'''
USAGE:

  opc7asm is an assembler for the OPC7 CPU

REQUIRED SWITCHES ::

  -f --filename  <filename>      specify the assembler source file

OPTIONAL SWITCHES ::

  -o --output    <filename>      specify file name for assembled code

  -g --format    <bin|hex>       set the file format for the assembled code
                                 - default is hex

  -n --nolisting                 suppress the listing to stdout while the
                                 program runs

  -s, --start_adr                sets the number of the first byte to be written
                                 out (must be even)

  -z, --size                     sets the number of bytes to be written out (must
                                 be even)

  -h --help                      print this help message

  If no output filename is provided the assembler just produces the normal
  listing output to stdout.

EXAMPLES ::

  python3 opc7asm.py -f test.s -o test.bin -g bin
'''

header_text = '''
# -----------------------------------------------------------------------------
# O P C - 7 * A S S E M B L E R
# -----------------------------------------------------------------------------
#
# ADDR: CODE               : SOURCE
#-----:--------------------:---------------------------------------------------
'''

import sys, re, codecs, getopt

# globals
(errors, warnings, nextmnum) = ( [],[],0)

def usage():
    print (__doc__);
    sys.exit(1)

def expand_macro(line, macro, mnum):  # recursively expand macros, passing on instances not (yet) defined
    global nextmnum
    (text,mobj)=([line],re.match("^(?P<label>\w*\:)?\s*(?P<name>\w+)\s*?\((?P<params>.*?)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr)= (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        (text, instparams,mnum,nextmnum) = (["#%s" % line], [x.strip() for x in paramstr.split(",")],nextmnum,nextmnum+1)
        if label:
            text.append("%s%s"% (label, ":" if (label != "" and label != "None" and not (label.endswith(":"))) else ""))
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = (newline.replace(s,r) if s else newline).replace('@','%s_%s' % (instname,mnum))
            text.extend(expand_macro(newline, macro, nextmnum))
    return(text)

def preprocess( filename ) :
    # Pass 0 - read file, expand all macros and return a new text file
    global errors, warnings, nextmnum
    (newtext,macro,macroname,mnum)=([],dict(),None,0)
    for line in open(filename, "r").readlines():
        mobj =  re.match("\s*?MACRO\s*(?P<name>\w*)\s*?\((?P<params>.*)\)", line, re.IGNORECASE)
        if mobj:
            (macroname,macro[macroname])=(mobj.groupdict()["name"],([x.strip() for x in (mobj.groupdict()["params"]).split(",")],[]))
        elif re.match("\s*?ENDMACRO.*", line, re.IGNORECASE):
            (macroname, line) = (None, '# ' + line)
        elif macroname:
            macro[macroname][1].append(line)
        newtext.extend(expand_macro(('' if not macroname else '# ') + line, macro, mnum))
    return newtext

def assemble( filename, listingon=True):
    global errors, warnings, nextmnum

    op = "mov movt xor and or not cmp sub add bperm ror lsr jsr asr rol s0F halt rti putpsr getpsr s13 s15 push pop out in sto ld ljsr lmov lsto lld".split()
    symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
    pdict = {"1":0x0,"z":0x4,"nz":0x6,"c":0x8,"nc":0xA,"mi":0xC,"pl":0xE,"":0x0}
    reg_re = re.compile("(r\d*|psr|pc)")
    (wordmem,wcount)=([0x00000000]*1024*1024,0)

    newtext = preprocess(filename)

    for iteration in range (0,2): # Two pass assembly
        (wcount,nextmem) = (0,0)
        for line in newtext:
            mobj = re.match('^(?:(?P<label>\w+):)?\s*((?:(?P<pred>((pl)|(mi)|(nc)|(nz)|(c)|(z)|(1)?)?)\.))?(?P<inst>\w+)?\s*(?P<operands>.*)',re.sub("#.*","",line))
            (label, pred, inst,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "inst","operands")]
            (pred, opfields,words, memptr) = ("1" if pred==None else pred, [ x.strip() for x in operands.split(",")],[], nextmem)
            if (iteration==0 and (label and label != "None") or (inst=="EQU")):
                errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
                try:
                    exec ("%s= int(%s)" % ((label,str(nextmem)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
                except:
                    errors += [ "Syntax error on:\n  %s" % line.strip() ]
                    continue
            if (inst in("WORD","HALF","BYTE") or inst in op) and iteration < 1:
                if inst=="WORD":
                    nextmem += len(opfields)
                elif inst == "HALF":
                    nextmem += (len(opfields)+1)//2
                elif inst == "BYTE":
                    nextmem += (len(opfields)+3)//4
                else:
                    nextmem += 1
            elif inst in op or inst in ("BYTE","HALF","WORD","STRING","BSTRING","PBSTRING"):
                if  inst in("STRING","BSTRING","PBSTRING"):
                    strings = re.match('.*STRING\s*\"(.*?)\"(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?.*?', line.rstrip())
                    string_data = codecs.decode(''.join([ x for x in strings.groups() if x != None]),  'unicode_escape')
                    string_len = chr(len( string_data ) & 0xFF) if inst=="PBSTRING" else ''    # limit string length to 255 for PBSTRINGS
                    if inst in ("BSTRING","PBSTRING") :
                        wordstr =  string_len + string_data + chr(0) + chr(0) + chr(0)
                        words = [(ord(wordstr[i])|(ord(wordstr[i+1])<<8)|(ord(wordstr[i+2])<<16)|(ord(wordstr[i+3])<<24)) for  i in range(0,len(wordstr)-3,4) ]
                    else:
                        wordstr = string_len + string_data              
                        words = [ord(wordstr[i]) for  i in range(0,len(wordstr))]
                else:
                    if ((len(opfields)==2 and not reg_re.match(opfields[1])) and inst not in "ljsr lmov lsto lld WORD HALF BYTE".split()):
                        warnings.append("Warning: suspected register field missing in ...\n         %s" % (line.strip()))
                    try:
                        exec("PC=%d+1" % nextmem, globals(), symtab) # calculate PC as it will be in EXEC state
                        if inst == "BYTE":
                            words = [int(eval( f,globals(), symtab)) for f in opfields ] + [0]*3
                            words = ([(words[i+3]&0xFF)<<24|(words[i+2]&0xFF)<<16|(words[i+1]&0xFF)<<8|(words[i]&0xFF) for i in range(0,len(words)-3,4)])
                        elif inst == "HALF":
                            words = [int(eval( f,globals(), symtab)) for f in opfields ] + [0]
                            words = ([(words[i+1]&0xFFFF)<<16|(words[i]&0xFFFF) for i in range(0,len(words)-1,2)]) if inst=="HALF" else words
                        else :
                            words = [int(eval( f,globals(), symtab)) for f in opfields ]
                    except (ValueError, NameError, TypeError,SyntaxError):
                        (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                    if inst in op:
                        if len(words) < 3 and op.index(inst)>=op.index("ljsr"):
                            (dst,src,val) = (words[0],0,words[1] & 0xFFFFF)
                        else:
                            (dst,src,val) = (words + [0])[:3]
                            ##i.e. the valid range of 16-bit IMM would be 0x0000->0x7FFF and 0xFFFF8000->0xFFFFFFFF.
                            val = val & 0xFFFFFFFF
                            if ( (inst not in ("in","out", "bperm", "movt")) and (0x7FFF < val < 0x0FFFF8000)):
                                errors.append("Error: 16b constant out of range in ...\n         %s" % (line.strip()))
                            elif (inst=="lmov" and dst!=0xF and (0x7FFFF < val < 0x0FFF80000)):
                                errors.append("Error: 20b constant out of range in ...\n         %s" % (line.strip()))
                            else:
                                val = val & 0xFFFF
                        words=[ (pdict[pred]<<28)|((op.index(inst)&0x1F)<<24)|(dst<<20)|(src<<16)| val&0xFFFFF]
                (wordmem[nextmem:nextmem+len(words)], nextmem,wcount )  = (words, nextmem+len(words),wcount+len(words))
            elif inst == "ORG":
                nextmem = eval(operands,globals(),symtab)
            elif inst and (inst != "EQU") and iteration>0 :
                errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
            if iteration > 0 and listingon==True:
                print("%06x: %-36s  %s"%(memptr,' '.join([("%08x" % i) for i in words]),line.rstrip()))

    print ("\nAssembled %d words of code with %d error%s and %d warning%s." % (wcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
    print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%08X (%08d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d|r\d\d|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))

    return wordmem


if __name__ == "__main__":
    """
    Command line option parsing.
    """
    filename = ""
    hexfile = ""
    output_filename = ""
    output_format = "hex"
    listingon = True
    start_adr = 0
    size = 0
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:o:g:s:z:hn", ["filename=","output=","format=","start_adr=","size=","help","nolisting"])
    except getopt.GetoptError as  err:
        print(err)
        usage()

    if len(args)>=1:
        filename = args[0]
    if len(args)>1:
        output_filename = args[1]
        output_format = "hex"

    for opt, arg in opts:
        if opt in ( "-f", "--filename" ) :
            filename = arg
        elif opt in ( "-o", "--output" ) :
            output_filename = arg
        elif opt in ( "-s", "--start_adr" ) :
            start_adr = int(arg,0)
        elif opt in ( "-z", "--size" ) :
            size = int(arg,0)
        elif opt in ( "-g", "--format" ) :
            if (arg in ("hex", "bin")):
                output_format = arg
            else:
                usage()
        elif opt in ("-n", "--nolisting"):
            listingon = False
        elif opt in ("-h", "--help" ) :
            usage()
        else:
            sys.exit(1)

    if filename != "":

        if size==0:
            size = 1024*1024 - start_adr

        print(header_text)
        wordmem = assemble(filename, listingon)[start_adr:start_adr+size]

        if len(errors)==0 and output_filename != "":
            if output_format == "hex":
                with open(output_filename,"w" ) as f:
                    f.write( '\n'.join([''.join("%08x " % d for d in wordmem[j:j+12]) for j in [i for i in range(0,len(wordmem),12)]]))
            else:
                with open(output_filename,"wb" ) as f:
                    # Write binary in little endian order
                    for w in wordmem:
                        bytes = bytearray()
                        bytes.append( w & 0xFF)
                        bytes.append( (w>>8) & 0xFF)
                        bytes.append( (w>>16) & 0xFF)
                        bytes.append( (w>>24) & 0xFF)
                        f.write(bytes)
    else:
        usage()
    sys.exit( len(errors)>0)
