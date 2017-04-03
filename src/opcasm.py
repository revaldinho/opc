# python3 opcasm.py <filename.s> [<filename.bin>]
import sys
import re

op = { "and.i": 0x10, "and": 0x00, "lda.i": 0x12, "lda": 0x02, "not.i": 0x14,
       "not":0x04,  "add.i": 0x16, "add": 0x06, "sta": 0x08, "jpc": 0x0A,
       "jpz": 0x0C, "jp": 0x0E, "halt": 0x1F }

symtab = dict();
bytemem = bytearray(4096)
line_re = re.compile( '^(\w+)?\s*(\w+(?:\.i)?)?\s*(\w+)?\s*?' )

# Read assembler file, stripping comments
with open(sys.argv[1]) as f:
    text = [ re.sub("#.*","",l) for l in f.readlines() ]
f.close()

# Pass 1
nextmem = 0
for line in text:
    gr = line_re.match(line).groups()
    if gr[0]:
        symtab[gr[0]] = nextmem
    if gr[1]:
        if gr[1] == "BYTE":
            nextmem += 1
        elif gr[1] == "ORG" and gr[2]:
            nextmem = int(gr[2],0)
        elif gr[1] in op:
            nextmem += 2
        else:
            print("Error: unrecognized instruction ", line)
            sys.exit()

# Pass 2
nextmem = 0
for line in text:
    operand = 0
    gr = line_re.match( re.sub("#.*","",line) ).groups()
    if gr[2] :
        try:
            operand = int(gr[2],0)
        except ValueError:
            if ( gr[2] not in symtab ) :
                print ("Error: undefined symbol %s in line %s" % ( gr[2], line))
            else:
                operand = symtab[gr[2]]
    if gr[1] != None :
        start = nextmem
        if gr[1] == "BYTE":
            bytes = [int(x,0) for x in gr[2:] ]
        elif gr[1] == "ORG" and gr[2]:
            nextmem = int(gr[2],0)
            bytes = []
        else:
            bytes = [ (( op[gr[1]]  << 3 ) | ((operand & 0x0F00) >> 8)), operand & 0xFF ]

        for b in bytes:
            bytemem[nextmem] =  b
            nextmem += 1
        print ("%04x  %-16s  %s" % (start, ' '.join([("%02x" % i) for i in bytes]), line.rstrip()))

print ("Symbol Table\n", symtab)

if len(sys.argv) > 2:  # Write Binary
    with open(sys.argv[2],"wb" ) as f:
        f.write(bytemem)
    f.close()
