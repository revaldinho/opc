# python3 opc3emu.py <filename.hex> [<filename.memdump>]
import sys, re
op = {"ld.i":0, "add.i":0x1, "and.i":0x2, "or.i":0x3, "xor.i":0x4, "ror.i":0x5, "adc.i":0x6, "ld":0x8, "sto":0x7,
    "add":0x9, "and":0xA, "or":0xB, "xor": 0xC, "ror":0xD, "adc":0xE, "halt" :0x0 }
dis = dict( [ (op[k],k) for k in [ x for x in op if x != "halt" ]])
pred_dict = {6:"", 5:"nz.", 3:"nc.", 0:"cz.", 4:"z.", 2:"c.", 7:"0.", 1:"ncz"}
with open(sys.argv[1],"r") as f:
    wordmem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]

(regfile, acc, c, z, pcreg) = ([0]*16,0,0,0,15) # initialise machine state inc PC = reg[15]
stdout=""
print ("PC   : Mem       : C Z : Instruction            : %s\n%s" % (''.join([" r%2d " % d for d in range(0,16)]), '-'*130))
while True:
    regfile[0] = 0    # always overwrite regfile location 0 and then dont care about assignments
    instr_word = wordmem[regfile[pcreg]] &  0xFFFF
    (pcarry, pzero, pinvert) = ( (instr_word & 0x8000) >> 15, (instr_word & 0x4000) >> 14, (instr_word & 0x2000)>>13)
    (instr_len, rdmem) = (2 if (instr_word & 0x1000) else 1, (instr_word & 0x0800>0))
    (opcode, source, dest) = ((instr_word & 0xF00) >> 8, (instr_word & 0xF0) >>4, instr_word & 0xF)
    operand = wordmem[regfile[pcreg]+1] if (instr_len==2) else 0
    instr_str = "%s%s r%d,r%d" % (pred_dict[pcarry <<2 | pzero<<1 | pinvert],dis[opcode],dest,source)
    if dis[opcode] == "ld.i" and (dest==source==0):
        instr_str = re.sub("ld.i","halt",instr_str)
    instr_str += (",0x%04x" % operand) if instr_len==2 else ''
    mem_str = " %04x %4s " % (instr_word, "%04x" % (operand) if instr_len==2 else '')
    print ("%04x :%s: %d %d : %-22s : %s" % (regfile[pcreg], mem_str, c, z, instr_str, ' '.join(["%04x" % i for i in regfile])))

    regfile[15] += instr_len # EA_ED must be computed after PC is brought up to date
    ea_ed = wordmem[(regfile[source] + operand)&0xFFFF] if rdmem else (regfile[source] + operand)&0xFFFF
    if (bool(pinvert) ^ bool(((pcarry or c) and (pzero or z)))):
        if opcode == op["halt"] and (source==dest==0):
            print("Stopped on halt instruction at %04x with halt number 0x%04x" % (regfile[15]-(instr_len), operand) )
            break
        elif opcode in ( op["and"], op["and.i"]):
            regfile[dest] = (regfile[dest] & ea_ed) & 0xFFFF
        elif opcode in ( op["or"], op["or.i"]):
            regfile[dest] = (regfile[dest] | ea_ed) & 0xFFFF
        elif opcode in ( op["xor"], op["xor.i"]):
            regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFF
        elif opcode in ( op["ror"], op["ror.i"]):
            (c, regfile[dest]) = (ea_ed & 0x1, (c<<15) | ((ea_ed&0xFFFF) >> 1))
        elif opcode in (op["add"], op["add.i"], op["adc"], op["adc.i"]) :
            res = (regfile[dest] + ea_ed + (c if opcode in ( op["adc"], op["adc.i"]) else 0)) & 0x1FFFF
            (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
        elif opcode in (op["ld.i"], op["ld"]):
            regfile[dest] = ea_ed
        elif opcode == op["sto"]:
            wordmem[ea_ed] = regfile[dest]
            if ea_ed == 0xfe09:
                stdout += chr(regfile[dest])
                print (stdout)
        if opcode != op["sto"]:
            z = 1 if (regfile[dest]==0) else 0

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(wordmem), 16):
            f.write( '%s\n' %  ' '.join("%04x"%n for n in wordmem[i:i+16]))
