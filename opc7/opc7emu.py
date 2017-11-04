import sys, re, functools
mnemonics="mov movt xor and or not cmp sub add bperm ror lsr jsr asr rol s0F halt rti putpsr getpsr s13 s15 s16 s17 out in sto ld ljsr lmov lsto lld".split()
op = dict([(opcode,mnemonics.index(opcode)) for opcode in mnemonics])
dis = dict([(mnemonics.index(opcode),opcode) for opcode in mnemonics])
pred_dict = {0:"",1:"0.",2:"z.",3:"nz.",4:"c.",5:"nc.",6:"mi.",7:"pl."}
def print_memory_access( type, address, data):
    ch = '%s' % chr(data) if ( 0x1F < data < 0x7F) else ' '
    print( "%6s :  Address : 0x%05x (%6d)       :        Data : 0x%08x (%10d) %s" % (type,address&(0xFFFFF if type not in ("IN","OUT") else 0xFFFF),address&(0xFFFFF if type not in ("IN","OUT") else 0xFFFF),data,data,ch))

if len(sys.argv) > 3:
    with open(sys.argv[3],"r") as f:
        input_text = iter(''.join(f.readlines()))
else:
    input_text = iter([chr(0)]*100000)

with open(sys.argv[1],"r") as f:
    wordmem = [ (int(x,16) & 0xFFFFFFFF) for x in f.read().split() ]
(regfile, acc, c, z, pcreg, c_save, s, ei, swiid, interrupt, iomem) = ([0]*16,0,0,0,15,0,0,0,0,0, [0]*65536)
print ("PC     : Mem      : Instruction            : SWI I S C Z : %s\n%s" % (''.join(["  r%2d    " % d for d in range(0,16)]), '-'*202))
while True:
    (pc_save,flag_save,regfile[0]) = (regfile[pcreg],(swiid,ei,s,c,z),0)    # always overwrite r0 and then dont care about assignments
    instr_word = wordmem[regfile[pcreg] & 0xFFFFF] &  0xFFFFFFFF
    (p0, p1, p2) = ( (instr_word >> 31) & 1, (instr_word >> 30) & 1, (instr_word >> 29 ) & 1)
    (opcode, dest, source) = (((instr_word >> 24) & 0x1F), (instr_word>>20)&0xF , (instr_word>>16) & 0xF)
    (operand, source) = (instr_word & 0xFFFFF, 0x0) if (0x1C<=opcode<=0x1F) else ( instr_word & 0xFFFF, source)

    # sign extend operand !
    if (0x1C<=opcode<=0x1F):
        operand = (operand | 0xFFF00000)  if (operand & 0x80000 != 0) else operand
    else:
        operand = (operand | 0xFFFF0000)  if (operand & 0x8000 != 0) else operand

    instr_str = "%s%s r%d,r%d,0x%05X" % ((pred_dict[p0<<2 | p1<<1 | p2] if (p0,p1,p2)!=(0,0,1) else ""),dis[opcode],dest,source,(operand & 0xFFFFF))
    instr_str = re.sub("r0","psr",instr_str,1) if (opcode in (op["putpsr"],op["getpsr"])) else instr_str

    regfile[pcreg] += 1
    if ( opcode==op["bperm"]):
        ea_ed = eff_addr = regfile[source]
    else:
        eff_addr = (regfile[source] + operand)&0xFFFFFFFF  # EA_ED must be computed after PC is brought up to date
        ea_ed = wordmem[eff_addr & 0xFFFFF] if (opcode in(op["ld"],op["lld"])) else iomem[eff_addr&0xFFFF] if (opcode in(op["ld"],op["in"],op["lld"])) else eff_addr

    if opcode == op["in"]:
        try:
            ea_ed = ord(input_text.__next__())
        except:
            ea_ed = 0
    if interrupt : # software interrupts dont care about EI bit
        (interrupt, regfile[pcreg], pc_int, psr_int , ei) = (0, 0x00000002, pc_save, (swiid,ei,s,c,z), 0)
    else:
        print ("%06x : %08X : %-22s :  %1X  %d %d %d %d : " % (pc_save, instr_word, instr_str, swiid ,ei, s, c, z), end='')
        print (' '.join(["%08X" % r for r in regfile ]))
        if (bool(p2) ^ (bool(s if p0==1 else z) if p1==1 else bool(c if p0==1 else 1))):
            if opcode == (op["halt"]):
                print("Stopped on halt instruction at %08x with halt number 0x%04x" % (regfile[pcreg], operand) )
                break
            elif opcode == op["rti"]:
                (regfile[pcreg], flag_save) = (pc_int, (0,psr_int[1],psr_int[2],psr_int[3],psr_int[4]) )
            elif opcode ==op["and"]:
                regfile[dest] = (regfile[dest] & ea_ed) & 0xFFFFFFFF
            elif opcode == op["or"]:
                regfile[dest] = (regfile[dest] | ea_ed) & 0xFFFFFFFF
            elif opcode == op["xor"]:
                regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFFFFFF
            elif opcode in (op["ror"],op["asr"],op["lsr"]):
                (c, regfile[dest]) = (ea_ed & 0x1, ( ((c<<31) if opcode==op["ror"] else (ea_ed&0x80000000 if opcode==op["asr"] else 0)) | ((ea_ed&0xFFFFFFFF) >> 1)))
            elif opcode == op["rol"]:
                (c, regfile[dest]) = ( (ea_ed>>31)&1, ((ea_ed<<1)&0xFFFFFFFE) | c)
            elif opcode == op["add"] :
                res = (regfile[dest] + ea_ed & 0x1FFFFFFFF)
                (c, regfile[dest])  = ( (res>>32) & 1, res & 0xFFFFFFFF)
            elif opcode == op["not"]:
                regfile[dest] = (~ea_ed) & 0xFFFFFFFF
            elif opcode == op["movt"]:
                regfile[dest] = ((ea_ed<<16) & 0xFFFF0000) | (regfile[dest]&0x0FFFF)
            elif opcode in (op["mov"], op["lmov"], op["ld"], op["in"], op["lld"]):
                regfile[dest] = ea_ed & 0xFFFFFFFF
                if opcode in (op["ld"],op["in"],op["lld"]):
                    print_memory_access( "IN" if opcode==op["in"] else "LOAD" , eff_addr, ea_ed)
            elif opcode in (op["sub"], op["cmp"]) :
                res = (regfile[dest] + ((~ea_ed)&0xFFFFFFFF) + 1) & 0x1FFFFFFFF
                dest = 0 if opcode==op["cmp"] else dest #  update dest reg to be r0 for correct flag setting later if PC was compared
                (c, regfile[dest])  = ( (res>>32) & 1, res & 0xFFFFFFFF)
            elif opcode in (op["jsr"], op["ljsr"]):
                (preserve_flag,regfile[dest],regfile[pcreg]) = (True,regfile[pcreg],ea_ed)
            elif opcode == op["bperm"]:
                n = [ (operand>>i)&0xF for i in range(0,16,4) ]
                bytes = [ 0 if (8>i>3) else ((ea_ed>>(n[i]*8))&0xFF) for i in range(0,5)]
                regfile[dest] = functools.reduce( lambda x,y: x|y, [ y<<x for (y,x) in zip(bytes,range(0,32,8))])
            elif opcode == op["putpsr"]:
                (flag_save, interrupt) = (((ea_ed&0xF0)>>4,(ea_ed&0x8)>>3,(ea_ed&0x4)>>2,(ea_ed&0x2)>>1,(ea_ed)&1), (ea_ed&0xF0)!=0)
            elif opcode == op["getpsr"]:
                regfile[dest] = ((swiid&0xF)<<4) | (ei<<3) | (s<<2) | (c<<1) | z
            elif opcode in (op["sto"],op["lsto"]):
                wordmem[ea_ed&0xFFFFF] = regfile[dest]
                print_memory_access("STORE",ea_ed,regfile[dest])
            elif opcode == op["out"]:
                iomem[ea_ed&0xFFFF] = regfile[dest]
                print_memory_access("OUT",ea_ed,regfile[dest])
            if  (dest==pcreg) or opcode in (op["sto"],op["in"],op["lsto"],op["putpsr"], op["rti"]):
                (swiid,ei,s,c,z) = flag_save
            else:
                (swiid,ei,s,c,z) = (swiid,ei,(regfile[dest]>>31) & 1, c, 1 if (regfile[dest]==0) else 0)
if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        f.write( '\n'.join([''.join("%08x " % d for d in wordmem[j:j+12]) for j in [i for i in range(0,len(wordmem),12)]]))
