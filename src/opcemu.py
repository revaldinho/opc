# python3 opcemu.py <filename.bin> [<filename.memdump>]
import sys

op = { "and.i": 0x10, "and": 0x00, "lda.i": 0x12, "lda": 0x02,
       "sta": 0x04, "add.i": 0x16, "add": 0x06,
       "not.i": 0x18, "not":0x08, "jpc": 0x0A, "jpz": 0x0C,
       "jp": 0x0E, "halt": 0x1F }

with open(sys.argv[1],"rb") as f:
    bytemem = bytearray(f.read())
f.close()

(pc, acc, c ) = (0, 0, 0) # machine state
opcode = 0
operand_data = 0
operand_adr = 0

print ("PC   : Mem   : Opcode Operand : Acc " )
while True:
    adr = pc
    opcode = (bytemem[pc] >> 3) & 0x1F
    operand_adr = (bytemem[pc] << 8 | bytemem[pc+1]) & 0x0FFF
    if (opcode & 0x10 == 0):
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

    print ("%04x : %02x %02x : %02x      %03x    : %02x" % ( adr, bytemem[adr], bytemem[adr+1], opcode, operand_data if opcode & 0x10==1 else operand_adr, acc))

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"wb" ) as f:
        f.write(bytemem)
    f.close()
