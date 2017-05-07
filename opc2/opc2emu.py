import sys
op = { "lda.i":0x8, "lda":0x9, "sta.p":0xA, "lda.p":0xC, "sta":0x6, "halt":0xF, "BYTE":0x100,
       "jpc": 0x4, "jpz":0x5, "jal":0x7, "adc":0x0, "not":0x1, "and":0x2, "axb":0x3}

dis = dict( [ (op[k],k) for k in op])

with open(sys.argv[1],"r") as f:
    bytemem = bytearray( [ int(x,16) for x in f.read().split() ])

(pc, acc,b,c) = (0x100,0,0,0) # initialise machine state
print ("PC   : Mem   : ACC B Carry : Mnemonic Operand\n%s" % ('-'*40))
while True:
    (opcode, pc_inc) = ((bytemem[pc] >> 4) & 0xF, 1)
    operand_adr = ((bytemem[pc] << 8) | bytemem[pc+1]) & 0x07FF
    if (opcode & 0xC > 0 ) : # Second fetch for two byte instructions
        if (opcode in (op["lda.p"], op["lda"],op["sta.p"])):
            operand_data = bytemem[operand_adr] & 0xFF
        else:
            operand_data = bytemem[pc+1] & 0xFF
        pc_inc = 2
    print ("%04x : %02x %02x : %02x  %02x   %1x  : %-8s %03x    " % ( pc, bytemem[pc], bytemem[pc+1],
        acc, b, c, dis[opcode], operand_adr)  )

    pc += pc_inc
    if (opcode in ("lda.p","sta.p")):  # Second read for pointer operations
        operand_adr = operand_data
        operand_data = bytemem[operand_adr] & 0xFF

    if opcode == op["and"]:
        (c, acc)  = (0, acc & b & 0xFF)
    elif opcode == op["not"]:
        acc = ~acc & 0xFF
    elif opcode == op["adc"]:
        res = (acc + b + c ) & 0x1FF
        (c, acc) = ( (res>>8)& 0x1, res & 0xFF)
    elif opcode in (op["lda.i"], op["lda"], op["lda.p"]):
        acc = operand_data & 0xFF
    elif opcode in (op["sta"], op["sta.p"]):
        bytemem[operand_adr] = acc
    elif opcode in (op["jpc"], op["jpz"]):
        pc = operand_adr if ( ((c==1) and opcode==op["jpc"]) or (acc==0)) else pc
    elif opcode == op["axb"]:
        (b,acc) = (acc,b)
    elif opcode == op["jal"]:
        (pc, acc, b ) = ( ((b<<8) | acc ) & 0x07FF, pc & 0xFF, (pc>>8) & 0x07)
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(bytemem), 24):
            f.write( '%s\n' %  ' '.join("%02x"%n for n in bytemem[i:i+24]))
