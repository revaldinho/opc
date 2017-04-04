# python3 opcemu.py <filename.bin> [<filename.memdump>]
import sys, time

op=dict()
dis=dict()
instruction_count = 0
for (mnemonic,opcode) in [ ("and.i",0x8),("and",0x0),("lda.i",0x9),
    ("lda",0x1),("not.i",0xA),("not",0x2),("add.i",0xB),("add",0x3),
    ("sta",0xC),("jpc",0xD),("jpz",0xE), ("jp",0xF),("halt",0x7) ]:
        op[mnemonic]=opcode
        dis[opcode]=mnemonic

with open(sys.argv[1],"rb") as f:
    bytemem = bytearray(f.read())
f.close()

(pc, acc, c ) = (0, 0, 0) # machine state
opcode = 0
operand_data = 0
operand_adr = 0
st = time.time()

print ("PC   : Mem   : ACC C : Mnemonic Operand\n%s" % ('-'*40))
while True:
    adr = pc
    opcode = (bytemem[pc] >> 4) & 0xF
    operand_adr = (bytemem[pc] << 8 | bytemem[pc+1]) & 0x0FFF
    instruction_count += 1
    if (opcode & 0x8 == 0):
        operand_data = bytemem[operand_adr]
    else:
        operand_data = (bytemem[pc+1] & 0xFF)
    pc += 2
    if opcode in ( op["and"], op["and.i"]):
        acc = acc & operand_data & 0xFF
        c = 0
    elif opcode in ( op["not"], op["not.i"]):
        acc = ~operand_data & 0xFF
    elif opcode == op["add"] or opcode == op["add.i"] :
        res = (acc + operand_data + c ) & 0x1FF
        acc = res & 0xFF
        c = (res>>8) & 1
    elif opcode == op["lda.i"] or opcode==op["lda"]:
        acc = operand_data & 0xFF
    elif opcode == op["sta"]:
        bytemem[operand_adr] = acc
    elif opcode == op["jpc"]:
        pc = operand_adr if c else pc
    elif opcode == op["jpz"]:
        pc = operand_adr if (acc==0) else pc
    elif opcode == op["jp"]:
        pc = operand_adr
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break
    print ("%04x : %02x %02x : %02x  %d : %-8s %03x    " % ( adr, bytemem[adr], bytemem[adr+1],
        acc, c,  dis[opcode], operand_data if opcode & 0x10==1 else operand_adr) )
print ("%s\nExecuted %d instructions in %3.3f s" % ('-'*40,instruction_count, time.time()-st))
if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"wb" ) as f:
        f.write(bytemem)
    f.close()
