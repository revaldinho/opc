import sys, re
mnemonics = "halt,not,xor,or,bperm,ror,lsr,asr,rol,rti,putpsr,getpsr,bror,brol,0E,0F,mov,jsr,cmp,sub,add,and,sto,ld,lmov,ljsr,lcmp,lsub,ladd,land,lsto,lld".split(",")
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
    print( "%5s:   Address : 0x%06x (%10d)         :        Data : 0x%06x (%10d) %s" % (type,address,address,data,data,ch))
with open(sys.argv[1],"r") as f: 
    wordmem  = [ (int(x,16) & 0xFFFFFF) for x in f.read().split() ]
    wordmem.extend( [0]*(2**24-len(wordmem)))
(regfile, acc, c, z, pcreg, c_save, s, ei, swiid, interrupt) = ([0]*16,0,0,0,15,0,0,0,0,0) # initialise machine state inc PC = reg[15]
print ("PC     : Mem           : Instruction              : SWI I S C Z : %s\n%s" % (''.join(["  r%2d  " % d for d in range(0,16)]), '-'*176))
while True:
    (pc_save,flag_save,regfile[0],preserve_flag) = (regfile[pcreg],(swiid,ei,s,c,z),0,False) # always overwrite regfile location 0 and then dont care about assignments
    instr_word = wordmem[regfile[pcreg] & 0xFFFFFF ] &  0xFFFFFF
    (p0, p1, p2) = ( (instr_word & 0x800000) >> 23, (instr_word & 0x400000) >> 22, (instr_word & 0x200000)>>21)    
    (opcode, dest, source, simm) = (((instr_word & 0x1F0000) >> 16) , (instr_word & 0xF000) >>12, (instr_word & 0xF00)>>8, instr_word & 0xFF)
    simm = (0xFFFF00 | simm) if (source!=0 and (simm & 0x80)) else simm
    (instr_len, rdmem, preserve_flag) = (2 if (opcode&0x18==0x18) else 1, opcode==op["ld"], (dest==pcreg))
    (regfile[15],operand) = (regfile[15]+2,wordmem[regfile[pcreg]+1]) if (instr_len==2) else (regfile[15]+1,simm)
    instr_str = "%s%s r%d," % ((pred_dict[p0<<2 | p1<<1 | p2] if (p0,p1,p2)!=(0,0,1) else ""),dis[opcode],dest)
    instr_str += ("%s%d%s" % (("r" ,source, (",0x%06x" % operand) if instr_len==2 else (",%02x" % operand))))
    instr_str = re.sub("r0","psr",instr_str,1) if (opcode in (op["putpsr"],op["getpsr"])) else instr_str
    mem_str = " %06x %6s " % (instr_word, "%06x" % (operand) if instr_len==2 else '')
    opcode = (opcode - 8) if opcode >=24 else opcode # Alias long instructions to short equivalents for execution
    if ( opcode==op["bperm"]):
        ea_ed = eff_addr = regfile[source] & 0xFFFFFF
    else:
        eff_addr = (regfile[source] + operand)&0xFFFFFF  # EA_ED must be computed after PC is brought up to date
        ea_ed = wordmem[eff_addr] & 0xFFFFFF if (opcode==op["ld"]) else eff_addr 
    if interrupt : # software interrupts dont care about EI bit
        (interrupt, regfile[pcreg], pc_int, psr_int , ei) = (0, 0x0002, pc_save, (swiid,ei,s,c,z), 0)
    else:
        print ("%06x :%s: %-24s :  %1X  %d %d %d %d : %s" % (pc_save, mem_str, instr_str, swiid ,ei, s, c, z, ' '.join(["%06x" % i for i in regfile])))
        if ( ( (p0,p1,p2)==(0,0,1) )  or  (bool(p2) ^ (bool(s if p0==1 else z) if p1==1 else bool(c if p0==1 else 1)))):
            if opcode == op["halt"]:
                print("Stopped on halt instruction at %06x with halt number 0x%06x" % (regfile[15]-(instr_len), operand) )
                break
            elif opcode == op["rti"] and (dest==15):
                (regfile[pcreg], flag_save, preserve_flag ) = (pc_int, (0,psr_int[1],psr_int[2],psr_int[3],psr_int[4]), True )
            elif opcode in (op["and"], op["or"]):
                regfile[dest] = ((regfile[dest] & ea_ed) if opcode==op["and"] else (regfile[dest] | ea_ed))& 0xFFFFFF
            elif opcode == op["xor"]:
                regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFFFF
            elif opcode in (op["ror"],op["asr"],op["lsr"]):
                (c, regfile[dest]) = (ea_ed & 0x1, ( ((c<<23) if opcode==op["ror"] else (ea_ed&0x800000 if opcode==op["asr"] else 0)) | ((ea_ed&0xFFFFFF) >> 1)))
            elif opcode == op["rol"] :
                (c,regfile[dest]) = ( (ea_ed & 0x800000)>>23, (c|(ea_ed<<1))&0xFFFFFF)
            elif opcode == op["brol"]:
                (c,regfile[dest]) = ( functools.reduce( lambda x,y: x|y , [ 1 if (i&1<<j) else 0 for j in range(16,24)], ((ea_ed<<8)|(ea_ed>>16))&0xFFFFFF ))
            elif opcode == op["bror"]:
                (c,regfile[dest]) = ( functools.reduce( lambda x,y: x|y , [ 1 if (i&1<<j) else 0 for j in range(0,8)], ((ea_ed>>8)|(ea_ed<<16))&0xFFFFFF ))
            elif opcode == op["add"] :
                res = (regfile[dest] + ea_ed)  & 0x1FFFFFF
                (c, regfile[dest])  = ( (res>>24) & 1, res & 0xFFFFFF)
            elif opcode in (op["mov"], op["not"], op["ld"]):
                regfile[dest] = (~ea_ed if opcode==op["not"] else ea_ed) & 0xFFFFFF
                if opcode==op["ld"]: 
                    print_memory_access( "LOAD" , eff_addr, ea_ed)
            elif opcode in (op["sub"], op["cmp"]) :
                res = (regfile[dest] + ((~ea_ed)&0xFFFFFF) + 1) & 0x1FFFFFF
                dest = 0 if opcode == op["cmp"] else dest # retarget r0 with result of comparison
                (c, regfile[dest])  = ( (res>>24) & 1, res & 0xFFFFFF)
            elif opcode == op["jsr"]:
                (preserve_flag,regfile[dest],regfile[pcreg]) = (True,regfile[pcreg],ea_ed)
            elif opcode == op["putpsr"]:
                (preserve_flag, flag_save, interrupt) = (True, ((ea_ed&0xF0)>>4,(ea_ed&0x8)>>3,(ea_ed&0x4)>>2,(ea_ed&0x2)>>1,(ea_ed)&1), (ea_ed&0xF0)!=0)
            elif opcode == op["getpsr"]:
                regfile[dest] = ((swiid&0xF)<<4) | (ei<<3) | (s<<2) | (c<<1) | z
            elif opcode == op["sto"]:
                print (regfile[source], regfile[dest], hex(ea_ed))
                (regfile[source],preserve_flag,wordmem[ea_ed]) = (regfile[source], True,regfile[dest])
                if ea_ed == 0xfffe09:
                    print_memory_access("OUT",ea_ed,regfile[dest])
                else:
                    print_memory_access("STORE",ea_ed,regfile[dest])            
            else:
                print( "Unrecognized opcode ")
                sys.exit()
            (swiid,ei,s,c,z) = flag_save if (preserve_flag or dest==0xF ) else (swiid, ei, (regfile[dest]>>23) & 1, c, 1 if (regfile[dest]==0) else 0)
if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        f.write( '\n'.join([''.join("%06x " % d for d in wordmem[j:j+16]) for j in [i for i in range(0,len(wordmem),16)]]))
