import sys, re
op = { "and"  :0x00, "lda":0x01,  "not":0x02,"add":0x03, "and.i":0x10, "lda.i":0x11, "not.i":0x12,
       "add.i":0x13, "lda.p":0x09,"sta":0x18, "sta.p":0x08, "jpc"  :0x19, "jpz"  :0x1a,
       "jp"   :0x1b, "jsr":0x1c,  "rts":0x1d,"bsw":0x1e, "halt" :0x1f, "WORD":0x100 }

def expand_macro(line, macro):  # recursively expand macros, passing on instances not (yet) defined
    (text,mobj)=([line],re.match("^(?:(?P<label>\w*):?)?\s*(?P<name>\w+)\s*?\((?P<params>.*)\)",line))
    if mobj and mobj.groupdict()["name"] in macro:
        (label,instname,paramstr) = (mobj.groupdict()["label"],mobj.groupdict()["name"],mobj.groupdict()["params"])
        instparams = [x.strip() for x in paramstr.split(",")]
        text = ["#%s" % line,"%s%s"% (label, ":" if label != "" else "")]
        for newline in macro[instname][1]:
            for (s,r) in zip( macro[instname][0], instparams):
                newline = newline.replace(s,r) if s else newline
            text.extend(expand_macro(newline, macro))
    return(text)

(symtab, wordmem, macro, macroname, newtext,wcount) = (dict(), [0x0000]*64*1024,dict(),None,[],0)
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
    (wcount,nextmem) = (0,0)
    for line in newtext:
        (words,operandwords,gr)=([],[],re.match('^(\w+)?:?\s*(\w+(?:\.i|\.p)?)?\s*(.*)',re.sub("#.*","",line)).groups())
        if gr[0]:
            exec ("%s= %d" % (gr[0],nextmem), globals(), symtab )
        if gr[1] and gr[1] == "ORG" and gr[2]:
            nextmem = eval(gr[2],globals(),symtab)
        elif gr[1] and gr[1] in op:
            operandwords=[0]
            if gr[2] and iteration==0:
                operandwords = [0]*len(gr[2].split(","))
            elif gr[2]:
                try:
                    operandwords = [eval( x ,globals(), symtab) for x in gr[2].split(",")]
                except (ValueError, NameError):
                    sys.exit("Error evaluating expression %s" % gr[2] )
            if gr[1]=="WORD":
                words = [x & 0xFFFF for x in operandwords]
            else:
                words = [op[gr[1]]<<11, operandwords[0] & 0xFFFF]
        elif gr[1]:
            sys.exit("Error: unrecognized instruction %s" % gr[1])
        if iteration > 0 :
            for ptr in range(0,len(words)):
                wordmem[ptr+nextmem] =  words[ptr]
            print("%04x  %-20s  %s"%(nextmem,' '.join([("%04x" % i) for i in words]),line.rstrip()))
        (nextmem,wcount) = (nextmem + len(words), wcount + len(words))
print ("\nAssembled %d words of code.\n\nSymbol Table:\n\n%s\n" % (wcount, '\n'.join(["%-32s 0x%04X (%06d)" % (k,v,v) for k,v in sorted(symtab.items()) if not re.match("r\d*|pc|psr",k)])))
with open(sys.argv[2],"w" ) as f:
    f.write( '\n'.join([''.join("%04x " % d for d in wordmem[j:j+24]) for j in [i for i in range(0,len(wordmem),24)]]))
