# python3 opc3emu.py <filename.hex> [<filename.memdump>]
import sys
op = { "and"  :0x00, "lda":0x01,"not"  :0x02,"add":0x03, "and.i":0x10, "lda.i":0x11, "not.i":0x12,
       "add.i":0x13, "lda.p":0x09,"sta":0x18, "sta.p":0x08, "jpc"  :0x19, "jpz"  :0x1a,
       "jp"   :0x1b, "jsr":0x1c,"rts"  :0x1d,"bsw":0x1e, "halt" :0x1f, "BYTE":0x100 }

dis = dict( [ (op[k],k) for k in op])

with open(sys.argv[1],"r") as f:
    wordmem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]

(pc, acc, c) = (0x0,0,0) # initialise machine state
print ("PC    : Mem      : ACC   C  : Mnemonic Operand\n%s" % ('-'*48))
while True:
    opcode = (wordmem[pc] >> 11) & 0x1F
    operand_adr = wordmem[pc+1]
    if (opcode & 0x10 == 0x00):
        operand_data = wordmem[operand_adr]
    else:
        operand_data = wordmem[pc+1]
    print ("%04x : %04x %04x : %04x  %d  : %-8s %04x    " % ( pc, wordmem[pc]&0xFFFF, wordmem[pc+1]&0xFFFF,
        acc&0xFFFF, c, dis[opcode], operand_adr&0xFFFF)  )
    if (opcode in (op["lda.p"], op["sta.p"])):  # Second read for pointer operations
        operand_adr = operand_data
        operand_data = wordmem[operand_adr]
    pc += 2
    if opcode in ( op["and"], op["and.i"]):
        (c,acc) = (0, acc & operand_data & 0xFFFF)
    elif opcode in ( op["not"], op["not.i"]):
        acc = ~operand_data
    elif opcode in (op["add"], op["add.i"]) :
        res = (acc + operand_data + c ) & 0x1FFFF
        (c, acc)  = ( (res>>16) & 1, res & 0xFFFF)
    elif opcode in (op["lda.i"], op["lda"], op["lda.p"]):
        acc = operand_data
    elif opcode in (op["sta"], op["sta.p"]):
        wordmem[operand_adr] = acc
    elif opcode in (op["jpc"], op["jpz"], op["jp"]):
        condition = (c==1) if opcode==op["jpc"] else (acc==0) if opcode==op["jpz"] else True
        pc = operand_adr if condition else pc
    elif opcode == op["bsw"]: # swap upper and lower bytes
        acc = ((acc>>8) & 0x00FF) | ((acc<<8) & 0xFF00)
    elif opcode == op["rts"]:
        pc = acc
    elif opcode == op["jsr"]:
        ( pc, acc) = (operand_adr, pc )
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(wordmem), 16):
            f.write( '%s\n' %  ' '.join("%04x"%n for n in wordmem[i:i+16]))
