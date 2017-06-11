# python3 opc3emu.py <filename.hex> [<filename.memdump>]
import sys, re
mnemonics = "mov,and,or,xor,add,adc,sto,ld,ror,not,sub,sbc,cmp,cmpc,bswp,psr,halt".split(',') #halt aliassed to mov modulo 16
op = dict([(opcode,mnemonics.index(opcode)) for opcode in mnemonics])
dis = dict([(mnemonics.index(opcode),opcode) for opcode in mnemonics])
pred_dict = {0:"",1:"0.",2:"z.",3:"nz.",4:"c.",5:"nc.",6:"mi.",7:"pl."}
with open(sys.argv[1],"r") as f:
    wordmem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]
(regfile, acc, c, z, pcreg, c_save, s) = ([0]*16,0,0,0,15,0,0) # initialise machine state inc PC = reg[15]
stdout=""
print ("PC   : Mem       : Instruction            : S C Z : %s\n%s" % (''.join([" r%2d " % d for d in range(0,16)]), '-'*130))
while True:
    (c_save,regfile[0]) = (c,0)    # always overwrite regfile location 0 and then dont care about assignments
    instr_word = wordmem[regfile[pcreg]] &  0xFFFF
    (p0, p1, p2) = ( (instr_word & 0x8000) >> 15, (instr_word & 0x4000) >> 14, (instr_word & 0x2000)>>13)
    (opcode, source, dest) = ((instr_word & 0xF00) >> 8, (instr_word & 0xF0) >>4, instr_word & 0xF)
    (instr_len, rdmem) = (2 if (instr_word & 0x1000) else 1, (opcode==op["ld"]))
    operand = wordmem[regfile[pcreg]+1] if (instr_len==2) else 0
    instr_str = "%s%s r%d,r%d" % (pred_dict[p0<<2 | p1<<1 | p2],dis[opcode],dest,source)
    instr_str = re.sub("r0","psr",instr_str,1) if (opcode==op["psr"]) else instr_str
    if opcode == op["mov"] and (dest==source==0):
        (opcode,instr_str) = (op["halt"], re.sub("ld","halt",instr_str))
    instr_str += (",0x%04x" % operand) if instr_len==2 else ''
    mem_str = " %04x %4s " % (instr_word, "%04x" % (operand) if instr_len==2 else '')
    print ("%04x :%s: %-22s : %d %d %d : %s" % (regfile[pcreg], mem_str, instr_str, s, c, z, ' '.join(["%04x" % i for i in regfile])))
    regfile[15] += instr_len # EA_ED must be computed after PC is brought up to date
    ea_ed = wordmem[(regfile[source] + operand)&0xFFFF] if rdmem else (regfile[source] + operand)&0xFFFF
    if ( bool(p2) ^ (bool(s if p0==1 else z) if p1==1 else bool(c if p0==1 else 1))):
        if opcode == op["halt"] and (source==dest==0):
            print("Stopped on halt instruction at %04x with halt number 0x%04x" % (regfile[15]-(instr_len), operand) )
            break
        elif opcode == op["and"]:
            regfile[dest] = (regfile[dest] & ea_ed) & 0xFFFF
        elif opcode == op["or"]:
            regfile[dest] = (regfile[dest] | ea_ed) & 0xFFFF
        elif opcode == op["xor"]:
            regfile[dest] = (regfile[dest] ^ ea_ed) & 0xFFFF
        elif opcode == op["ror"]:
            (c, regfile[dest]) = (ea_ed & 0x1, (c<<15) | ((ea_ed&0xFFFF) >> 1))
        elif opcode in (op["add"], op["adc"]) :
            res = (regfile[dest] + ea_ed + (c if opcode==op["adc"] else 0)) & 0x1FFFF
            (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
        elif opcode in (op["mov"], op["ld"], op["not"]):
            regfile[dest] = (~ea_ed if opcode==op["not"] else ea_ed) & 0xFFFF
        elif opcode in (op["sub"], op["sbc"], op["cmp"], op["cmpc"]) :
            res = (regfile[dest] + ((~ea_ed)&0xFFFF) + (c if (opcode in (op["cmpc"],op["sbc"])) else 1)) & 0x1FFFF
            dest = 0 if opcode in( op["cmp"], op["cmpc"]) else dest # retarget r0 with result of comparison
            (c, regfile[dest])  = ( (res>>16) & 1, res & 0xFFFF)
        elif opcode == op["bswp"]:
            regfile[dest] = (((ea_ed&0xFF00)>>8)|((ea_ed&0x00FF)<<8)) & 0xFFFF
        elif opcode == op["psr"] and dest==0: # putpsr
            (s,c,z) = ( (regfile[source]&0x4)>>1,(regfile[source]&0x2)>>1, regfile[source]&0x1 )
        elif opcode == op["psr"] and source==0: # getpsr
            regfile[dest] = (s<<2) | (c<<1) | z
        elif opcode == op["sto"] :
            wordmem[ea_ed] = regfile[dest]
            if ea_ed == 0xfe09:
                stdout += chr(regfile[dest])
                print (stdout)
        c = c_save if dest == 0xF else c   # Preserve previous carry for instructions writing to PC
        if opcode not in (op["sto"], op["psr"])  and dest!=0xF:
            (s,z) = ((regfile[dest]>>15) & 1, 1 if (regfile[dest]==0) else 0)
if len(sys.argv) > 2:                       # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(wordmem), 16):
            f.write( '%s\n' %  ' '.join("%04x"%n for n in wordmem[i:i+16]))
