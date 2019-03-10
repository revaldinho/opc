import sys, re, codecs, functools
op = "halt,not,xor,or,bperm,ror,lsr,asr,rol,rti,putpsr,getpsr,bror,brol,0E,0F,mov,jsr,cmp,sub,add,and,sto,ld,lmov,ljsr,lcmp,lsub,ladd,land,lsto,lld".split(",")
long_op = "lmov,ljsr,lcmp,lsub,ladd,land,lsto,lld".split(",")
symtab = dict( [ ("r%d"%d,d) for d in range(0,16)] + [("pc",15), ("psr",0)])
pdict = {"1":0x000000,"z":0x400000,"nz":0x600000,"c":0x800000,"nc":0xA00000,"mi":0xC00000,"pl":0xE00000,"":0x000000} 
(wordmem,macro,macroname,newtext,wcount,errors,warnings,reg_re,mnum,nextmnum)=([0x000000]*256*64*1024,dict(),None,[],0,[],[],re.compile("(r\d*|psr|pc)"),0,0)
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
    (wcount,nextmem) = (0,0)
    for line in newtext:
        mobj = re.match('^(?:(?P<label>\w+):)?\s*((?:(?P<pred>((pl)|(mi)|(nc)|(nz)|(c)|(z)|(1)?)?)\.))?\.?(?P<inst>\w+)?\s*(?P<operands>.*)',re.sub("#.*","",line))
        (label, pred, inst,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "inst","operands")]
        (pred, opfields,words, memptr) = ("1" if pred==None else pred, [ x.strip() for x in operands.split(",")],[], nextmem)
        if (iteration==0 and (label and label != "None") or (inst=="EQU")):
            errors = (errors + ["Error: Symbol %16s redefined in ...\n         %s" % (label,line.strip())]) if label in symtab else errors
            exec ("%s= int(%s)" % ((label,str(nextmem)) if label!= None else (opfields[0], opfields[1])), globals(), symtab )
        if inst in("WORD","BYTE") and iteration < 1:
            nextmem += (len(opfields) if inst=="WORD" else ((len(opfields)+1)//2) if inst=="BYTE" else len(opfields)-1) 
        elif inst in op and iteration < 1:
            nextmem += 2 if inst in long_op else 1 
        elif inst in op or inst in ("BYTE","WORD","STRING","BSTRING","PBSTRING"):
            if  inst in("STRING","BSTRING","PBSTRING"):
                strings = re.match('.*STRING\s*\"(.*?)\"(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?(?:\s*?,\s*?\"(.*?)\")?.*?', line.rstrip())
                string_data = codecs.decode(''.join([ x for x in strings.groups() if x != None]),  'unicode_escape')
                string_len = chr(len( string_data ) & 0xFF) if inst=="PBSTRING" else ''    # limit string length to 255 for PBSTRINGS
                (step, wordstr) =  ( 3 if inst in("BSTRING","PBSTRING") else 1, string_len + string_data )
                wordstr += '\0' * (step-len(wordstr)%step) # need to pad out string to step size for packing
                (words) = ([(ord(wordstr[i]) | ((ord(wordstr[i+1])<<8 | (ord(wordstr[i+2])<<16)) if inst in ("BSTRING","PBSTRING") else 0)) for  i in range(0,len(wordstr),step) ])
            else:
                if ((len(opfields)==2 and not reg_re.match(opfields[1])) and inst not in ("WORD","BYTE")):
                    warnings.append("Warning: suspected register field missing in ...\n         %s" % (line.strip()))
                try:
                    exec("PC=%d+%d" % (nextmem, 2 if (inst in long_op) else 1), globals(), symtab) # calculate PC as it will be in EXEC state
                    words = [int(eval( f,globals(), symtab)) for f in opfields ] + ([0,0] if inst=="BYTE" else []) # pad out BYTE lines wih a single zero
                    words = ([(words[i+2]&0xFF)<<16|(words[i+1]&0xFF)<<8|(words[i]&0xFF) for i in range(0,len(words)-1,3)]) if inst=="BYTE" else words # pack bytes 3 to a word
                except (ValueError, NameError, TypeError,SyntaxError):
                    (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
                if (inst in op) :
                    (dst,src,val) = (words+[0])[:3]
                    if (inst not in long_op):
                        if ( (src!=0) and (~val & 0xFFFF80 !=0xFFFF80) and ( val & 0xFFFF80 != 0xFFFF80)) or ( (src==0) and not( -1 <val<0x100)):
                            errors=(errors+["Error: short constant out of range in ...\n         %s"%(line.strip())])
                        words=[pdict[pred]|((op.index(inst)&0x1F)<<16)|(dst<<12)|(src<<8)|val&0xFF][:len(words)-(len(words)==2)]                        
                    else :
                        words=[pdict[pred]|((op.index(inst)&0x1F)<<16)|(dst<<12)|(src<<8)][:len(words)-(len(words)==2)]
                        words.append( val & 0xFFFFFF);
            (wordmem[nextmem:nextmem+len(words)],nextmem,wcount )  = (words, nextmem+len(words),wcount+len(words))
        elif inst == "ORG":
            nextmem = eval(operands,globals(),symtab)
        elif inst and (inst != "EQU") and iteration>0 :
            errors.append("Error: unrecognized instruction or macro %s in ...\n         %s" % (inst,line.strip()))
        if iteration > 0 :
            print("%06x  %-20s  %s"%(memptr,' '.join([("%06x" % i) for i in words]),line.rstrip()))
wordmem = functools.reduce(lambda l, e: [e]+l if l or e else [],wordmem[::-1]) # Truncate hex output
print ("\nAssembled %d words of code with %d error%s and %d warning%s." % (wcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d|r\d\d|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))
with open("/dev/null" if len(errors)>0 else sys.argv[2],"w" ) as f:   ## write to hex file only if no errors else send result to null file
    f.write( '\n'.join([''.join("%06x " % d for d in (wordmem+24*[0])[j:j+24]) for j in [i for i in range(0,len(wordmem),24)]]))
sys.exit( len(errors)>0)
