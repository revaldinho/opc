# python3 opcasm.py <filename.s> [<filename.bin>]
import sys, re
op = { "and.i": 0x8, "and": 0x0, "lda.i": 0x9, "lda": 0x01, "not.i": 0xA,
       "not":0x2,  "add.i": 0xB, "add": 0x3, "sta": 0xC, "jpc": 0xD,
       "jpz": 0xE, "jp": 0xF, "halt": 0x7, "BYTE":0x100 }

symtab = dict();
bytemem = bytearray(4096)
line_re = re.compile( '^(\w+)?\s*(\w+(?:\.i)?)?\s*(.*)' )

for iteration in range (0,2):     # Two pass assembly
    with open(sys.argv[1]) as f:
        nextmem = 0
        for line in f.readlines():
            bytes = []
            gr = line_re.match( re.sub("#.*","",line) ).groups()
            if gr[0]:
                exec ("%s= %d" % (gr[0],nextmem), globals(), symtab )
            if gr[1] and gr[1] == "ORG" and gr[2]:
                nextmem = int(gr[2],0)
            elif gr[1] and gr[1] in op:
                bytes=[0]
                if gr[2] and iteration==0:
                    bytes = [0]*len(gr[2].split(","))
                elif gr[2]:
                    try:
                        bytes = [eval( x ,globals(), symtab) for x in gr[2].split(",")]
                    except (ValueError, NameError):
                        sys.exit("Error evaluating expression %s" % gr[2] )
                if gr[1]=="BYTE":
                    bytes = [x & 0xFF for x in bytes]
                else:
                    bytes = [op[gr[1]]<<4 | (bytes[0]>>8) & 0xF, bytes[0] & 0xFF]
            elif gr[1]:
                sys.exit("Error: unrecognized instruction %s" % gr[1])
            if iteration > 0 :
                bytemem[nextmem:nextmem] =  bytes
                print ("%04x  %-16s  %s" % (nextmem, ' '.join([("%02x" % i) for i in bytes]), line.rstrip()))
            nextmem += len(bytes)

print ("\nSymbol Table:\n", symtab)

if len(sys.argv) > 2:  # Write Binary File
    with open(sys.argv[2],"wb" ) as f:
        f.write(bytemem)
