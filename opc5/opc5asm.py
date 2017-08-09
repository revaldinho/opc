import sys, re
op = {"ld.i":0, "add.i":0x1, "and.i":0x2, "or.i":0x3, "xor.i":0x4, "ror.i":0x5, "adc.i":0x6, "ld":0x8, "sto":0x7,
    "add":0x9, "and":0xA, "or":0xB, "xor": 0xC, "ror":0xD, "adc":0xE, "halt" :0x0 }
symtab = dict( [ ("r%d"%d,d) for d in range(0,16)])
predicates = {"c":0x4000, "z":0x8000, "cz":0x0000,  "nc":0x6000,  "nz":0xA000, "":0xC000, "0":0xE000, "1":0xC000, "ncz":0x2000, "nzc":0x2000}
(wordmem,macro,macroname,newtext,errors,warnings,wcount,mnum,nextmnum)=([0x0000]*64*1024,dict(),None,[],[],[],0,0,1)
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
    (wcount,nextmem) = (0,0)
    symtab["pc"]=15  # Add Alias for pc = r15
    for line in newtext:
        (words, memptr) = ([], nextmem)
        mobj = re.match('^(?:(?P<label>\w+):)?\s*(?:(?P<pred>((ncz)|(nz)|(nc)|(cz)|(c)|(z)|(1)|(0)?)?)\.?)(?P<instr>\w+(?:\.i|\.p)?)?\s*(?P<operands>.*)',re.sub("#.*","",line))
        (label, pred, instr,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "instr","operands")]
        opfields = [ x.strip() for x in operands.split(",")]
        if label and label != "None":
            exec ("%s= %d" % (label,nextmem), globals(), symtab )
        if instr in op and iteration < 1:
            nextmem += len(opfields)-1                  # If two operands are provide instruction will be one word
        elif instr=="WORD" and iteration < 1:
            nextmem += len(opfields)
        elif instr in op or instr=="WORD":
            try:
                words = [eval( f,globals(), symtab) & 0xFFFF for f in opfields ];
            except (ValueError, NameError, TypeError,SyntaxError):
                (words,errors)=([0]*3,errors+["Error: illegal or undefined register name or expression in ...\n         %s" % line.strip() ])
            if instr in op:
                (dst,src,val) = (words+[0])[:3]
                words = [((len(words)==3)<<12)|predicates[pred]|(op[instr]<<8)|(src<<4)|dst,val][:len(words)-(len(words)==2)]
            (wordmem[nextmem:nextmem+len(words)], nextmem, wcount )  = (words, nextmem+len(words),wcount+len(words))
        elif instr == "ORG":
            nextmem = eval(operands,globals(),symtab)
        elif instr and iteration >0:
            errors.append("Error: unrecognized instruction %s" % instr)
        if iteration > 0 :
            print("%04x  %-20s  %s"%(memptr,' '.join([("%04x" % i) for i in words]),line.rstrip()))
print ("\nAssembled %d words of code with %d error%s and %d warning%s." % (wcount,len(errors),'' if len(errors)==1 else 's',len(warnings),'' if len(warnings)==1 else 's'))
print ("\nSymbol Table:\n\n%s\n\n%s\n%s" % ('\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d*|pc|psr",k)]),'\n'.join(errors),'\n'.join(warnings)))
with open("/dev/null" if len(errors)>0 else sys.argv[2],"w" ) as f:   ## write to hex file only if no errors else send result to null file
    f.write( '\n'.join([''.join("%04x " % d for d in wordmem[j:j+24]) for j in [i for i in range(0,len(wordmem),24)]]))
