import sys, re
op = "mov,and,or,xor,add,adc,sto,ld,ror,jsr,sub,sbc,inc,lsr,dec,asr,halt,bswp,putpsr,getpsr,rti,not,out,in,push,pop,cmp,cmpc".split(",")
symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
pdict = {"1":0x0000,"z":0x4000,"nz":0x6000,"c":0x8000,"nc":0xA000,"mi":0xC000,"pl":0xE000,"":0x0000} ##0x2000 reseved for non-predicated instuctions
(bytemem,macro,macroname,newtext,bcount,errors,warnings,reg_re,mnum,nextmnum)=([0x0000]*128*1024,dict(),None,[],0,[],[],re.compile("(r\d*|psr|pc)"),0,1)
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
    (bcount,nextword,nextbyte) = (0,0,0)
    for line in newtext:
        mobj = re.match('^(?:(?P<label>\w+):)?\s*((?:(?P<pred>((pl)|(mi)|(nc)|(nz)|(c)|(z)|(1)?)?)\.))?(?P<inst>\w+)?\s*(?P<operands>.*)',re.sub("#.*","",line))
        (label, pred, inst,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "inst","operands")]
        (pred, opfields,words, memptr, bytes) = ("1" if pred==None else pred, [ x.strip() for x in operands.split(",")],[], nextword, [])
        if (iteration==0 and (label and label != "None") or (inst=="EQU")):
            errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
            exec ("%s= %s" % ((label,str(nextword)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
        if (inst in("WORD","BYTE") or inst in op) and iteration < 1:
            nextword += (len(opfields) if inst=="WORD" else ((len(opfields)+1)//2) if inst=="BYTE" else len(opfields)-1) # If two operands are provide instuction will be one word
            nextbyte = nextword * 2
        elif inst in op or inst in ("BYTE","WORD","STRING","BSTRING"):
            if  inst=="STRING" or inst=="BSTRING":
                (step, wordstr) =  ( 2 if inst=="BSTRING" else 1, (''.join(opfields)).strip('"')+chr(0))
            else:
                if ((len(opfields)==2 and not reg_re.match(opfields[1])) and inst not in ("inc","dec","WORD","BYTE")):
                    warnings.append("Warning: suspected register field missing in ...\n         %s" % (line.strip()))
                try:
                    exec("PC=%d+%d" % (nextword,len(opfields)-1), globals(), symtab) # calculate PC as it will be in EXEC state
                    words = [eval( f,globals(), symtab) for f in opfields ] + ([0] if inst=="BYTE" else []) # pad out BYTE lines wih a single zero
                    words = ([(words[i+1]&0xFF)<<8|(words[i]&0xFF) for i in range(0,len(words)-1,2)]) if inst=="BYTE" else words # pack bytes 2 to a word
                except (ValueError, NameError, TypeError,SyntaxError):
                    (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                if inst in op:
                    (dst,src,val,abs_src) = (words+[0])[:3] + [words[1] if words[1]>0 else -words[1]]
                    errors=(errors+["Error: short constant out of range in ...\n         %s"%(line.strip())]) if (inst in('inc','dec') and (abs_src>0xF)) else errors
                    (inst,src) = ( 'dec',(~src +1)&0xF) if inst=='inc' and (src&0x8000) else (inst,src) #spot increment with negative immediate and swap to dec
                    words=[((len(words)==3)<<12)|(pdict[pred] if ((op.index(inst)&0x10)==0) else 0x2000)|((op.index(inst)&0x0F)<<8)|(src<<4)|dst,val&0xFFFF][:len(words)-(len(words)==2)]
            for w in words:
                bytes.append(w&0xFF)
                bytes.append((w>>8)&0xFF)
            (bytemem[nextbyte:nextbyte+len(bytes)], nextword, nextbyte,bcount )  = (bytes, nextword + len(bytes)//2, nextbyte+len(bytes),bcount+len(bytes))
        elif inst == "ORG":
            nextword = eval(operands,globals(),symtab)
            nextbyte = nextword * 2
        elif inst and (inst != "EQU") and iteration>0 :
            errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
        if iteration > 0 :
            print("%04x  %-20s  %s"%(memptr,' '.join([("%04x" % i) for i in words]),line.rstrip()))
print ("\nAssembled %d bytes of code with %d error%s and %d warning%s." % (bcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d*|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))
with open("/dev/null" if len(errors)>0 else sys.argv[2],"w" ) as f:   ## write to hex file only if no errors else send result to null file
    for bytenum in range (0, len(bytemem),48):
        words = []
        for i in range (0,48,2):
            if ( bytenum + i < len(bytemem)):
                words.append(  "%04x " % (bytemem[i+bytenum] + 256*bytemem[i+1+bytenum]))
        f.write( (''.join(words))+'\n')
#            f.write( '\n'.join([''.join("%04x " % d for d in bytemem[j:j+24]) for j in [i for i in range(0,len(bytemem),24)]]))
