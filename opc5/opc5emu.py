# python3 opc3emu.py <filename.hex> [<filename.memdump>]
import sys
op = { "nand"  :0x18, "ld":0x10,  "add":0x14, "nand.i":0x08, "ld.i":0x00, "add.i":0x04, "sto":0x0C, "halt" :0x00 }
dis = dict( [ (op[k],k) for k in op])
pred = {0:"cnz.", 1:"c.", 2:"nz.", 3:""}

with open(sys.argv[1],"r") as f:
    wordmem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]

(regfile, acc, c, z) = ([0]*16,0,0,0) # initialise machine state inc PC = reg[15]
print ("PC   : Mem       : C Z : Instruction            : %s\n%s" % (''.join([" r%2d " % d for d in range(0,16)]), '-'*130))
while True:
    regfile[0] = 0    # always overwrite regfile location 0 and then dont care about assignments
    pc = regfile[15]
    instr_word = wordmem[pc] &  0xFFFF
    pcarry = (instr_word & 0x8000) >> 15
    pnzero = (instr_word & 0x4000) >> 14
    instr_len = 2 if (instr_word & 0x2000) else 1
    rdmem = (instr_word & 0x1000)
    opcode = (instr_word & 0x1F00) >> 8
    source = (instr_word & 0xF0) >>4
    dest = instr_word & 0xF
    operand = wordmem[pc+1] if (instr_len==2) else 0

    instr_str = pred[pcarry <<1 | pnzero]
    if dis[opcode] in ("ld.i","halt"):
        if dest==source==0:
            instr_str += "%s r%d,r%d" % ("halt",dest,source)
        else:
            instr_str += "%s r%d,r%d" % ("ld.i",dest,source)
    else:
        instr_str += "%s r%d,r%d" % (dis[opcode],dest,source)
    instr_str += (",0x%04x" % operand) if instr_len==2 else ''
    mem_str = " %04x %4s " % (wordmem[pc]&0xFFFF, "%04x" % (wordmem[pc+1]&0xFFFF) if instr_len==2 else '')
    print ("%04x :%s: %d %d : %-22s : %s" % ( pc, mem_str, c, z, instr_str, ' '.join(["%04x" % i for i in regfile])))
    regfile[15] += instr_len

    ea_ed = regfile[source] + operand     # EA_ED must be computed after PC is brought up to date
    if (rdmem):
        ea_ed = wordmem[ea_ed]

    if ( (pcarry or c) and (pnzero or not z)):
        if opcode == op["halt"] and (source==dest==0):
            print("Stopped on halt instruction at %04x" % (regfile[15]-(instr_len)) )
            break
        elif opcode in ( op["nand"], op["nand.i"]):
            (c,regfile[dest]) = (0, ~(regfile[dest] & ea_ed) & 0xFFFF)
            z = 1 if (regfile[dest]==0) else 0
        elif opcode in (op["add"], op["add.i"]) :
            res = (regfile[dest] + ea_ed) & 0x1FFFF
            (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
            z = 1 if (regfile[dest]==0) else 0
        elif opcode in (op["ld.i"], op["ld"]):
            regfile[dest] = ea_ed
            z = 1 if (regfile[dest]==0) else 0
        elif opcode == op["sto"]:
            wordmem[ea_ed] = regfile[dest]

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(wordmem), 16):
            f.write( '%s\n' %  ' '.join("%04x"%n for n in wordmem[i:i+16]))
