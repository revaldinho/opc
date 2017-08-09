import sys, re
op = "mov,and,or,xor,add,adc,sto,ld,ror,jsr,sub,sbc,inc,lsr,dec,asr,halt,bswp,putpsr,getpsr,rti,not,out,in,push,pop,cmp,cmpc".split(",")
symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
byte_symtab = dict()
pdict = {"1":0x00,"z":0x40,"nz":0x60,"c":0x80,"nc":0xA0,"mi":0xC0,"pl":0xE0,"":0x00} ##0x2000 reseved for non-predicated instuctions
(bytemem,macro,macroname,newtext,bcount,errors,warnings,reg_re,mnum,nextmnum,nextbyte)=([0x0000]*128*1024,dict(),None,[],0,[],[],re.compile("(r\d*|psr|pc)"),0,1,0)

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
        (label,instname,paramstr,nextmnum) = (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"],max(nextmnum,mnum+1))
        (text, instparams) = (["#%s" % line], [x.strip() for x in paramstr.split(",")])
        if label:
            text.append("%s%s"% (label, ":" if (label != "" and label != "None" and not (label.endswith(":"))) else ""))
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = (newline.replace(s,r) if s else newline).replace('@','%s_%s' % (instname,mnum))
            text.extend(expand_macro(newline, macro, nextmnum))
    return(text)

for line in open(sys.argv[1], "r").readlines():       # Pass 0 - macro expansion
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
                errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in byte_symtab else errors
                exec ("%s= %s" % ((label,str(nextbyte)) if label!= None else (opfields[0], opfields[1])), globals(), byte_symtab )
            else:
                check_alignment("word label",error=True)
                errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
                exec ("%s= %s" % ((label,str((nextbyte+1)//2)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
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
        elif inst in op or inst in ("BYTE","WORD","UBYTE","UWORD","STRING","BSTRING","UBSTRING"):
            if  inst=="STRING":
                check_alignment(inst)
                for c in (''.join(opfields)).strip("\""):
                    bytes.extend([ord(c),0])
            elif inst in ("BSTRING", "UBSTRING"):
                if inst=="BSTRING":
                    check_alignment(inst)
                bytes = [ord(c) for c in (''.join(opfields)).strip("\"")]
                if len(bytes)%2==1:   # pad out odd lengths of BSTRING for backward compatibility
                    bytes.append(0)
            else:
                if ((len(opfields)==2 and not reg_re.match(opfields[1])) and inst not in ("inc","dec","WORD","BYTE","UBYTE","UWORD")):
                    warnings.append("Warning: suspected register field missing in ...\n         %s" % (line.strip()))
                try:
                    nextword = (nextbyte+1)//2
                    exec("PC=%d+%d" % (nextword,len(opfields)-1), globals(), symtab) # calculate PC as it will be in EXEC state
                    words = [eval( f,globals(), symtab) for f in opfields ]
                except (ValueError, NameError, TypeError,SyntaxError):
                    (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                if inst in op:
                    (dst,src,val,abs_src) = (words+[0])[:3] + [words[1] if words[1]>0 else -words[1]]
                    errors=(errors+["Error: short constant out of range in ...\n         %s"%(line.strip())]) if (inst in('inc','dec') and (abs_src>0xF)) else errors
                    (inst,src) = ( 'dec',(~src +1)&0xF) if inst=='inc' and (src&0x8000) else (inst,src) #spot increment with negative immediate and swap to dec
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
        if iteration > 0 :
            memptr = nextbyte - len(bytes) # recalculate here in case it was realigned during processing
            print("%04x (%04x)  %-20s  %s"%(memptr,(memptr+1)//2,' '.join([("%02x" % i) for i in bytes]),line.rstrip()))

# Sanity check of symbol tables
for s in byte_symtab:
    if s in symtab:
        warnings.append("Warning: symbol %s is defined in both byte and word symbol tables" % s)


print ("\nAssembled %d bytes of code with %d error%s and %d warning%s." % (bcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
if len(byte_symtab)>0:
    print ("\nByte Symbol Table:\n\n%s\n" % ('\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(byte_symtab.items()) if not re.match("r\d*|pc|psr",k)])))
print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d*|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))

with open("/dev/null" if len(errors)>0 else sys.argv[2],"w" ) as f:   ## write to hex file only if no errors else send result to null file
    for bytenum in range (0, len(bytemem),48):
        words = []
        for i in range (0,48,2):
            if ( bytenum + i < len(bytemem)):
                words.append(  "%04x " % (bytemem[i+bytenum] + 256*bytemem[i+1+bytenum]))
        f.write( (''.join(words))+'\n')
