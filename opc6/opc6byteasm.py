#!/usr/bin/env python3
## ============================================================================
## opc6byteasm.py - byte oriented assembler for the OPC6 CPU
##
## COPYRIGHT 2017 Richard Evans, Ed Spittles
##
## This file is part of the One Page Computing project: http://revaldinho.github.io/opc
## 
## opc6byteasm is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## opc6byteasm is distributed in the hope that it will be useful,
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

  opc6byteasm is an assembler for the OPC6 CPU

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

  python3 opc6byteasm.py -f test.s -o test.bin -g bin 
'''

header_text = '''
# ----------------------------------------------------------------------------
# O P C - 6 * A S S E M B L E R 
# ----------------------------------------------------------------------------
#
#ADDR: CODE               : SOURCE
#----:--------------------:---------------------------------------------------
'''

import sys, re, getopt, codecs
# globals
(errors,warnings,nextmnum,nextbyte)=([],[],0,0)

def usage():
    print (__doc__);
    sys.exit(1)

def check_alignment(inst,error=True):
    global nextbyte, errors
    if nextbyte%2==1:
        if error:
            errors.append("Error: found %s directive or instruction on unaligned byte ...\n        %s" % (inst, line.lstrip()))
        return False
    else:
        return True

def expand_macro(line, macro, mnum):  # recursively expand macros, passing on instances not (yet) defined
    global nextmnum
    (text,mobj)=([line],re.match("^(?P<label>\w*\:)?\s*(?P<name>\w+)\s*?\((?P<params>.*?)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr) = (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        (text, instparams,mnum,nextmnum) = (["#%s" % line], [x.strip() for x in paramstr.split(",")],nextmnum,nextmnum+1)        
        if label:
            text.append("%s%s"% (label, ":" if (label != "" and label != "None" and not (label.endswith(":"))) else ""))
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = (newline.replace(s,r) if s else newline).replace('@','%s_%s' % (instname,mnum))
            text.extend(expand_macro(newline, macro, nextmnum))
    return(text)

def assemble(filename, listingon=True):
    global errors, warnings, nextmnum, nextbyte    
    op = "mov,and,or,xor,add,adc,sto,ld,ror,jsr,sub,sbc,inc,lsr,dec,asr,halt,bswp,putpsr,getpsr,rti,not,out,in,push,pop,cmp,cmpc".split(",")
    symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
    pdict = {"1":0x00,"z":0x40,"nz":0x60,"c":0x80,"nc":0xA0,"mi":0xC0,"pl":0xE0,"":0x00} ##0x2000 reseved for non-predicated instuctions
    (bytemem,macro,macroname,newtext,bcount,reg_re,mnum)=([0x00]*128*1024,dict(),None,[],0,re.compile("(r\d*|psr|pc)"),0)
    
    for line in open(filename, "r").readlines():       # Pass 0 - macro expansion
        mobj =  re.match("\s*?MACRO\s*(?P<name>\w*)\s*?\((?P<params>.*)\)", line, re.IGNORECASE)
        if mobj:
            (macroname,macro[macroname])=(mobj.groupdict()["name"],([x.strip() for x in (mobj.groupdict()["params"]).split(",")],[]))
        elif re.match("\s*?ENDMACRO.*", line, re.IGNORECASE):
            (macroname, line) = (None, '# ' + line)
        elif macroname:
            macro[macroname][1].append(line)
        newtext.extend(expand_macro(('' if not macroname else '# ') + line, macro, mnum))
    
    for iteration in range (0,2): # Two pass assembly
        (bcount,nextbyte) = (0,0)
        for line in newtext:
            mobj = re.match('^(?:(?P<label>\w+):(?P<table>B|W)?)?\s*((?:(?P<pred>((pl)|(mi)|(nc)|(nz)|(c)|(z)|(1)?)?)\.))?(?P<inst>\w+)?\s*(?P<operands>.*)',re.sub("#.*","",line))
            (label, pred, inst,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "inst","operands")]
            (pred, opfields,words, bytes) = ("1" if pred==None else pred, [ x.strip() for x in operands.split(",")],[], [])
            if (iteration==0 and (label and label != "None") or (inst=="EQU")):
                # OPC Labels can only point at words so assume that alignment will be performed if the label is unaligned
                # PLASMA VM labels can be unaligned...
                if mobj.groupdict()["table"]=="B":
                    errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
                    exec ("%s= int(%s)" % ((label,str(nextbyte)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
                elif iteration ==0 : # all symbols defined on pass 0
                    if inst != "EQU":
                        check_alignment("word label",error=True)
                    (symbol, value) = (label,str((nextbyte+1)//2))  if inst != "EQU" else (opfields[0], opfields[1])
                    errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (symbol,line.strip())]) if symbol in symtab else errors
                    exec ("%s= %s" % (symbol,value), globals(), symtab )
            if (inst=="ALIGN"):
                if not check_alignment(inst,error=False):
                    nextbyte+=1
            elif (inst in("WORD","BYTE","UWORD","UBYTE") or inst in op) and iteration < 1:
                if inst == "UWORD":
                    nextbyte += len(opfields)*2
                elif inst == "UBYTE":
                    nextbyte += len(opfields)
                elif inst == "WORD":
                    check_alignment(inst)
                    nextbyte += len(opfields)*2
                elif inst == "BYTE":
                    check_alignment(inst)
                    nextbyte += len(opfields) + (1 if len(opfields)%2==1 else 0) # odd numbers of BYTEs are padded out to words
                else: # an instruction
                    nextbyte += 2*(len(opfields)-1)
            elif inst in op or inst in ("BYTE","WORD","UBYTE","UWORD","STRING","BSTRING","UBSTRING", "PBSTRING"):
                if  inst=="STRING":
                    check_alignment(inst)
                    strings = re.match('.*STRING\s*\"(.*?)\"(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?.*?', line.rstrip())
                    string_data = ''.join([ x for x in strings.groups() if x != None])                    
                    for c in codecs.decode(string_data, 'unicode_escape'):                    
                        bytes.extend([ord(c),0])
                elif inst in ("BSTRING", "PBSTRING", "UBSTRING"):
                    if inst!="UBSTRING":
                        check_alignment(inst)
                    strings = re.match('.*STRING\s*\"(.*?)\"(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?.*?', line.rstrip())
                    string_data = codecs.decode(''.join([ x for x in strings.groups() if x != None]),  'unicode_escape')
                    string_len = len( string_data ) & 0xFF    # limit string length to 255 for PBSTRINGS
                    if inst == "PBSTRING":
                        bytes = [string_len] + [ord(c) for c in string_data ]
                        if len(bytes)%2==1:   # pad out odd lengths of BSTRING for backward compatibility 
                            bytes.append(0)                        
                    else:
                        bytes = [ord(c) for c in string_data ]                                        
                        if inst=="BSTRING" and len(bytes)%2==1:   # pad out odd lengths of BSTRING for backward compatibility
                            bytes.append(0)
                else:
                    if ((len(opfields)==2 and not reg_re.match(opfields[1])) and inst not in ("inc","dec","WORD","BYTE","UBYTE","UWORD")):
                        warnings.append("Warning: suspected register field missing in ...\n         %s" % (line.strip()))
                    try:
                        nextword = (nextbyte+1)//2
                        exec("PC=%d+%d" % (nextword,len(opfields)-1), globals(), symtab) # calculate PC as it will be in EXEC state
                        exec("_BPC_=%d" % (nextbyte), globals(), symtab) # calculate Byte PC for VM as current position
                        words = [int(eval( f,globals(), symtab)) for f in opfields ]
                    except (ValueError, NameError, TypeError,SyntaxError):
                        (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                    if inst in op:
                        (dst,src,val,abs_src) = (words+[0])[:3] + [words[1] if words[1]>0 else -words[1]]
                        errors=(errors+["Error: short constant out of range in ...\n         %s"%(line.strip())]) if (inst in('inc','dec') and (abs_src>0xF)) else errors
                        (inst,src) = ('dec' if inst=='inc' else 'inc',(~src +1)&0xF) if inst in('inc','dec') and (src&0x8000) else (inst,src) 
                        check_alignment(inst)
                        bytes = [(src<<4)|dst]
                        bytes.append(((len(words)==3)<<4)|(pdict[pred] if ((op.index(inst)&0x10)==0) else 0x20)|((op.index(inst)&0x0F)))
                        if ( len(words)!=2):
                            bytes.extend([ val & 0xFF, (val>>8)& 0xFF])
                    elif inst in ("BYTE","UBYTE"):
                        if inst == "BYTE":
                            check_alignment(inst)
                        bytes = [w&0xFF for w in words]
                        bytes += ([0] if (inst=="BYTE" and (len(bytes)%2==1)) else []) # Pad BYTE data out with a final 0, but not UBYTE
                    elif inst in ("WORD","UWORD"):
                        if inst=="WORD":
                            check_alignment(inst)
                        for c in words:
                            bytes.extend([c&0xFF,(c>>8)&0xFF])
                if bytes == []:
                    for i in range (0, len(words),2):
                        bytes.append(words[i]&0xFF)
                        bytes.append((words[i+1]>>8)&0xFF)
                (bytemem[nextbyte:nextbyte+len(bytes)], nextbyte,bcount )  = (bytes,nextbyte+len(bytes),bcount+len(bytes))
            elif inst == "ORG":
                nextbyte = 2 * eval(operands,globals(),symtab)
            elif inst and (inst != "EQU") and iteration>0 :
                errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
            if iteration > 0 and listingon==True:
                memptr = nextbyte - len(bytes) # recalculate here in case it was realigned during processing
                print("%04x %-20s  %s"%(memptr,' '.join([("%02x" % i) for i in bytes]),line.rstrip()))

    print ("\nAssembled %d bytes of code with %d error%s and %d warning%s." % (bcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
    print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%05X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d|r\d\d|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))

    return bytemem

    
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
            size = 128*1024 - start_adr
            
        print(header_text)
        bytemem = assemble(filename, listingon)[start_adr:start_adr+size]

        if len(errors)==0 and output_filename != "":
            if output_format == "hex":
                with open(output_filename,"w" ) as f:   
                    for bytenum in range (0, len(bytemem),48):
                        words = []
                        for i in range (0,48,2):
                            if ( bytenum + i < len(bytemem)):
                                words.append(  "%04x " % (bytemem[i+bytenum] + 256*bytemem[i+1+bytenum]))
                        f.write( (''.join(words))+'\n')
            else:
                with open(output_filename,"wb" ) as f:   
                    bytesout = bytearray(bytemem)
                    f.write( bytesout)
    else:
        usage()
    sys.exit( len(errors)>0)
