import sys, re
op = { "nand"  :0x18, "ld":0x10,  "add":0x14, "nand.i":0x08, "ld.i":0x00, "add.i":0x04, "sto":0x0C, "halt" :0x00 }
symtab = dict( [ ("r%d"%d,d) for d in range(0,16)])
predicates = {"c":0x4000, "nz":0x8000, "cnz":0x0000, "":0xC000}
def expand_macro(line, macro):  # recursively expand macros, passing on instonces not (yet) defined
    (text,mobj)=([line],re.match("^(?P<label>\w*\:)?\s*(?P<name>\w+)\s*?\((?P<params>.*)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr) = (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        instparams = [x.strip() for x in paramstr.split(",")]
        text = ["#%s" % line,"%s%s"% (label, ":" if label != "" else "")]
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = newline.replace(s,r) if s else newline
            text.extend(expand_macro(newline, macro))
    return(text)

(wordmem, macro, macroname, newtext) = ( [0x0000]*64*1024,dict(),None,[])
for line in open(sys.argv[1], "r").readlines():       # Pass 0 - macro expansion
    mobj =  re.match("\s*?MACRO\s*(?P<name>\w*)\s*?\((?P<params>.*)\)", line, re.IGNORECASE)
    if mobj:
        (macroname,macro[macroname])=(mobj.groupdict()["name"],([x.strip() for x in (mobj.groupdict()["params"]).split(",")],[]))
        newtext.append("# %s" % line)
    elif re.match("\s*?ENDMACRO.*", line, re.IGNORECASE):
        macroname = None
        newtext.append("# %s" % line)
    elif macroname:
        macro[macroname][1].append(line)
        newtext.append("# %s" % line)
    else:
        newtext.extend(expand_macro(line, macro))

for iteration in range (0,2): # Two pass assembly
    nextmem = 0
    symtab["pc"]=15  # Add Alias for pc = r15
    for line in newtext:
        (words, memptr) = ([], nextmem)
        mobj = re.match('^(?:(?P<label>\w+):)?\s*(?:(?P<pred>(nz)|(cnz)|c?)\.?)(?P<instr>\w+(?:\.i|\.p)?)?\s*(?P<operands>.*)',re.sub("#.*","",line))
        (label, pred, instr,operands) = [ mobj.groupdict()[item] for item in ("label","pred", "instr","operands")]
        opfields = [ x.strip() for x in operands.split(",")]
        if label:
            exec ("%s= %d" % (label,nextmem), globals(), symtab )
        if instr in op and iteration < 1:
            nextmem += len(opfields)-1                  # If two operands are provide instruction will be one word
        elif instr=="WORD" and iteration < 1:
            nextmem += len(opfields)
        elif instr in op or instr=="WORD":
            try:
                words = [eval( f,globals(), symtab) & 0xFFFF for f in opfields ];
            except (ValueError, NameError, TypeError,SyntaxError):
                sys.exit("Error illegal register name or expression in: %s" % line )
            if instr in op:
                (dst,src,val) = (words+[0])[:3]
                words = [((len(words)==3)<<13)|predicates[pred]|(op[instr]<<8)|(src<<4)|dst,val][:len(words)-(len(words)==2)]
            wordmem[nextmem:nextmem+len(words)] = words
            nextmem += len(words)
        elif instr == "ORG":
            nextmem = eval(operands,globals(),symtab)
        elif instr :
            sys.exit("Error: unrecognized instruction %s" % instr)
        if iteration > 0 :
            print("%04x  %-20s  %s"%(memptr,' '.join([("%04x" % i) for i in words]),line.rstrip()))

print ("\nSymbol Table:\n", dict([(x, symtab[x]) for x in symtab if not re.match("r\d*|pc",x)]))
with open(sys.argv[2],"w" ) as f:
    for i in range(0, len(wordmem), 24):
        f.write( '%s\n' %  ' '.join("%04x"%n for n in wordmem[i:i+24]))
