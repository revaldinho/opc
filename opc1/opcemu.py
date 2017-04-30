# python3 opcemu.py <filename.hex> [<filename.memdump>]
import sys
op = { "and": 0x0, "lda": 0x01, "not":0x2, "add": 0x3,
       "and.i": 0x8, "lda.i": 0x9, "not.i": 0xA,"add.i": 0xB,
       "rts":0xC, "halt": 0xE, "lxa":0xD,
       "sta": 0x4, "jpc": 0x5, "jpz": 0x6, "jp": 0x7, "jsr":0xF,
       "BYTE":0x100 }

dis = dict( [ (op[k],k) for k in op])

with open(sys.argv[1],"r") as f:
    bytemem = bytearray( [ int(x,16) for x in f.read().split() ])

(pc, acc, c) = (0,0,0) # initialise machine state
print ("PC   : Mem   : ACC C : Mnemonic Operand\n%s" % ('-'*40))
while True:
    opcode = (bytemem[pc] >> 4) & 0xF
    operand_adr = (bytemem[pc] << 8 | bytemem[pc+1]) & 0x0FFF
    if (opcode & 0x8 == 0):
        operand_data = bytemem[operand_adr]
    else:
        operand_data = (bytemem[pc+1] & 0xFF)
    print ("%04x : %02x %02x : %02x  %d : %-8s %03x    " % ( pc, bytemem[pc], bytemem[pc+1],
        acc, c,  dis[opcode], operand_data if opcode & 0x10==1 else operand_adr) )
    pc += 2
    if opcode in ( op["and"], op["and.i"]):
        acc = acc & operand_data & 0xFF
        c = 0
    elif opcode in ( op["not"], op["not.i"]):
        acc = ~operand_data & 0xFF
    elif opcode in (op["add"], op["add.i"]) :
        res = (acc + operand_data + c ) & 0x1FF
        acc = res & 0xFF
        c = (res>>8) & 1
    elif opcode in (op["lda.i"], op["lda"]):
        acc = operand_data & 0xFF
    elif opcode == op["sta"]:
        bytemem[operand_adr] = acc
    elif opcode in (op["jpc"], op["jpz"], op["jp"]):
        condition = (c==1) if opcode==op["jpc"] else (acc==0) if opcode==op["jpz"] else True
        pc = operand_adr if condition else pc
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(bytemem), 24):
            f.write( '%s\n' %  ' '.join("%02x"%n for n in bytemem[i:i+24]))
