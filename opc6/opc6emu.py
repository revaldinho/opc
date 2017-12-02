import sys, re
mnemonics="mov,and,or,xor,add,adc,sto,ld,ror,jsr,sub,sbc,inc,lsr,dec,asr,halt,bswp,putpsr,getpsr,rti,not,out,in,push,pop,cmp,cmpc".split(",")
op = dict([(opcode,mnemonics.index(opcode)) for opcode in mnemonics])
dis = dict([(mnemonics.index(opcode),opcode) for opcode in mnemonics])
pred_dict = {0:"",1:"0.",2:"z.",3:"nz.",4:"c.",5:"nc.",6:"mi.",7:"pl."}
if len(sys.argv) > 3:
    with open(sys.argv[3],"r") as f:
        input_text = iter(''.join(f.readlines()))
else:
    input_text = iter([chr(0)]*100000)
def print_memory_access( type, address, data):
    ch = '%s' % chr(data) if ( 0x1F < data < 0x7F) else '.'
    print( "%5s:   Address : 0x%04x (%5d)         :        Data : 0x%04x (%5d) %s" % (type,address,address,data,data,ch))
with open(sys.argv[1],"r") as f: 
    wordmem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]
(regfile, acc, c, z, pcreg, c_save, s, ei, swiid, interrupt, iomem) = ([0]*16,0,0,0,15,0,0,0,0,0, [0]*65536) # initialise machine state inc PC = reg[15]
print ("PC   : Mem       : Instruction            : SWI I S C Z : %s\n%s" % (''.join([" r%2d " % d for d in range(0,16)]), '-'*130))
while True:
    (pc_save,flag_save,regfile[0],preserve_flag) = (regfile[pcreg],(swiid,ei,s,c,z),0,False)    # always overwrite regfile location 0 and then dont care about assignments
    instr_word = wordmem[regfile[pcreg] & 0xFFFF ] &  0xFFFF
    (p0, p1, p2) = ( (instr_word & 0x8000) >> 15, (instr_word & 0x4000) >> 14, (instr_word & 0x2000)>>13)
    (opcode, source, dest) = (((instr_word & 0xF00) >> 8) | (0x10 if (p0,p1,p2)==(0,0,1) else 0x00), (instr_word & 0xF0) >>4, instr_word & 0xF)
    (instr_len, rdmem, preserve_flag) = (2 if (instr_word & 0x1000) else 1, (opcode in(op["ld"],op["in"],op["pop"])), (dest==pcreg))
    operand = wordmem[regfile[pcreg]+1] if (instr_len==2) else (source if opcode in [op["dec"],op["inc"]] else ((opcode==op["pop"])-(opcode==op["push"])))
    instr_str = "%s%s r%d," % ((pred_dict[p0<<2 | p1<<1 | p2] if (p0,p1,p2)!=(0,0,1) else ""),dis[opcode],dest)
    instr_str += ("%s%d%s" % (("r" if opcode not in (op["inc"],op["dec"]) else ""),source, (",0x%04x" % operand) if instr_len==2 else ''))
    instr_str = re.sub("r0","psr",instr_str,1) if (opcode in (op["putpsr"],op["getpsr"])) else instr_str
    (mem_str, source) = (" %04x %4s " % (instr_word, "%04x" % (operand) if instr_len==2 else ''), (0 if opcode in (op["dec"],op["inc"]) else source))
    regfile[15] += instr_len
    eff_addr = (regfile[source] + operand*(opcode!=op["pop"]))&0xFFFF  # EA_ED must be computed after PC is brought up to date
    ea_ed = wordmem[eff_addr] if (opcode in(op["ld"],op["pop"])) else iomem[eff_addr] if rdmem else eff_addr
    if opcode == op["in"]:
        try:
            ea_ed = ord(input_text.__next__())
        except:
            ea_ed = 0
    if interrupt : # software interrupts dont care about EI bit
        (interrupt, regfile[pcreg], pc_int, psr_int , ei) = (0, 0x0002, pc_save, (swiid,ei,s,c,z), 0)
    else:
        print ("%04x :%s: %-22s :  %1X  %d %d %d %d : %s" % (pc_save, mem_str, instr_str, swiid ,ei, s, c, z, ' '.join(["%04x" % i for i in regfile])))
        if ( ( (p0,p1,p2)==(0,0,1) )  or  (bool(p2) ^ (bool(s if p0==1 else z) if p1==1 else bool(c if p0==1 else 1)))):
            if opcode == (op["halt"]):
                print("Stopped on halt instruction at %04x with halt number 0x%04x" % (regfile[15]-(instr_len), operand) )
                break
            elif opcode == (op["rti"]) and (dest==15):
                (regfile[pcreg], flag_save, preserve_flag ) = (pc_int, (0,psr_int[1],psr_int[2],psr_int[3],psr_int[4]), True )
            elif opcode in (op["and"], op["or"]):
                regfile[dest] = ((regfile[dest] & ea_ed) if opcode==op["and"] else (regfile[dest] | ea_ed))& 0xFFFF
            elif opcode == op["xor"]:
                regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFF
            elif opcode in (op["ror"],op["asr"],op["lsr"]):
                (c, regfile[dest]) = (ea_ed & 0x1, ( ((c<<15) if opcode==op["ror"] else (ea_ed&0x8000 if opcode==op["asr"] else 0)) | ((ea_ed&0xFFFF) >> 1)))
            elif opcode in (op["add"], op["adc"], op["inc"]) :
                res = (regfile[dest] + ea_ed + (c if opcode==op["adc"] else 0)) & 0x1FFFF
                (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
            elif opcode in (op["mov"], op["ld"], op["not"], op["in"], op["pop"]):
                (regfile[source],regfile[dest]) = (regfile[source] if opcode !=op["pop"] else ((regfile[source]+operand)&0xFFFF), (~ea_ed if opcode==op["not"] else ea_ed) & 0xFFFF)
                if opcode in (op["ld"],op["in"],op["pop"]):
                    print_memory_access( "IN" if opcode==op["in"] else "LOAD" , eff_addr, ea_ed)
            elif opcode in (op["sub"], op["sbc"], op["cmp"], op["cmpc"], op["dec"]) :
                res = (regfile[dest] + ((~ea_ed)&0xFFFF) + (c if (opcode in (op["cmpc"],op["sbc"])) else 1)) & 0x1FFFF
                dest = 0 if opcode in( op["cmp"], op["cmpc"]) else dest # retarget r0 with result of comparison
                (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
            elif opcode == op["bswp"]:
                regfile[dest] = (((ea_ed&0xFF00)>>8)|((ea_ed&0x00FF)<<8)) & 0xFFFF
            elif opcode == op["jsr"]:
                (preserve_flag,regfile[dest],regfile[pcreg]) = (True,regfile[pcreg],ea_ed)
            elif opcode == op["putpsr"]:
                (preserve_flag, flag_save, interrupt) = (True, ((ea_ed&0xF0)>>4,(ea_ed&0x8)>>3,(ea_ed&0x4)>>2,(ea_ed&0x2)>>1,(ea_ed)&1), (ea_ed&0xF0)!=0)
            elif opcode == op["getpsr"]:
                regfile[dest] = ((swiid&0xF)<<4) | (ei<<3) | (s<<2) | (c<<1) | z
            elif opcode in (op["sto"],op["push"]):
                (regfile[source],preserve_flag,wordmem[ea_ed]) = (ea_ed if opcode==op["push"] else regfile[source], True,regfile[dest])
                print_memory_access("STORE",ea_ed,regfile[dest])
            elif opcode == op["out"]:
                (preserve_flag,iomem[ea_ed], ch) = (True, regfile[dest], '%s' % chr(regfile[dest]) if ( 0x1F < regfile[dest] < 0x7F) else '.')
                print_memory_access("OUT",ea_ed,regfile[dest])           
            (swiid,ei,s,c,z) = flag_save if (preserve_flag or dest==0xF ) else (swiid,ei, (regfile[dest]>>15) & 1, c, 1 if (regfile[dest]==0) else 0)
if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        f.write( '\n'.join([''.join("%04x " % d for d in wordmem[j:j+16]) for j in [i for i in range(0,len(wordmem),16)]]))
