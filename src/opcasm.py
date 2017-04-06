# python3 opcasm.py <filename.s> [<filename.bin>]
import sys, re
op = { "and.i": 0x8, "and": 0x0, "lda.i": 0x9, "lda": 0x01, "not.i": 0xA,
       "not":0x2,  "add.i": 0xB, "add": 0x3, "sta": 0xC, "jpc": 0xD,
       "jpz": 0xE, "jp": 0xF, "halt": 0x7 }

symtab = dict();
bytemem = bytearray(4096)
line_re = re.compile( '^(\w+)?\s*(\w+(?:\.i)?)?\s*(.*)' )

with open(sys.argv[1]) as f:  # Read assembler file, stripping comments
    text = [ re.sub("#.*","",l) for l in f.readlines() ]
f.close()

nextmem = 0
for line in text:  # Assembler Pass 1
    gr = line_re.match(line).groups()
    if gr[0]:
        exec ("%s= %d" % (gr[0],nextmem), globals(), symtab )
    if gr[1]:
        if gr[1] == "BYTE":
            nextmem += len(gr[2].split(","))
        elif gr[1] == "ORG" and gr[2]:
            nextmem = int(gr[2],0)
        elif gr[1] in op:
            nextmem += 2
        else:
            print("Error: unrecognized instruction ", line)
            sys.exit()

nextmem = 0
for line in text: # Assembler Pass 2
    operand = 0
    gr = line_re.match( re.sub("#.*","",line) ).groups()
    if gr[1] != None :
        start = nextmem
        if gr[1] == "BYTE":
            bytes =  [eval( x ,globals(), symtab) for x in gr[2].split(",")]
        elif gr[1] == "ORG" and gr[2]:
            nextmem = int(gr[2],0)
            bytes = []
        else:
            if gr[2]:
                try:
                    operand = eval("%s" % gr[2], globals(), symtab)
                except NameError:
                    print("Oh no - Error evaluation expression %s " % gr[2] )
            bytes =  [ op[gr[1]]<<4 | (operand>>8) & 0xF, operand & 0xFF]
        for b in bytes:
            bytemem[nextmem] =  b
            nextmem += 1
        print ("%04x  %-16s  %s" % (start, ' '.join([("%02x" % i) for i in bytes]), line.rstrip()))

print ("Symbol Table\n", symtab)

if len(sys.argv) > 2:  # Write Binary File
    with open(sys.argv[2],"wb" ) as f:
        f.write(bytemem)
    f.close()
