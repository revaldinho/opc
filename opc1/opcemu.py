# python3 opcemu.py <filename.hex> [<filename.memdump>]
import sys
op = { "and"  :0x00, "lda":0x01,"not"  :0x02,"add":0x03, "and.i":0x10, "lda.i":0x11, "not.i":0x12,
       "add.i":0x13, "lda.p":0x09,"sta":0x18, "sta.p":0x08, "jpc"  :0x19, "jpz"  :0x1a,
       "jp"   :0x1b, "jsr":0x1c,"rts"  :0x1d,"lxa":0x1e, "halt" :0x1f, "BYTE":0x100 }

dis = dict( [ (op[k],k) for k in op])

with open(sys.argv[1],"r") as f:
    bytemem = bytearray( [ int(x,16) for x in f.read().split() ])

(pc, acc, link) = (0x100,0,0) # initialise machine state
print ("PC   : Mem   : ACC C LINK : Mnemonic Operand\n%s" % ('-'*40))
while True:
    opcode = (bytemem[pc] >> 3) & 0x1F
    operand_adr = ((bytemem[pc] << 8) | bytemem[pc+1]) & 0x07FF
    if (opcode & 0x10 == 0x00):
        operand_data = bytemem[operand_adr] & 0xFF
    else:
        operand_data = bytemem[pc+1] & 0xFF
    print ("%04x : %02x %02x : %02x  %d  %1x   : %-8s %03x    " % ( pc, bytemem[pc], bytemem[pc+1],
        acc, link&1,  link, dis[opcode], operand_adr)  )
    if (opcode in (op["lda.p"], op["sta.p"])):  # Second read for pointer operations
        operand_adr = operand_data
        operand_data = bytemem[operand_adr] & 0xFF

    pc += 2
    if opcode in ( op["and"], op["and.i"]):
        acc = acc & operand_data & 0xFF
        link = link & 0b110
    elif opcode in ( op["not"], op["not.i"]):
        acc = ~operand_data & 0xFF
    elif opcode in (op["add"], op["add.i"]) :
        res = (acc + operand_data + (link&1) ) & 0x1FF
        acc = res & 0xFF
        link = (link & 0b110) | ((res>>8) & 1)
    elif opcode in (op["lda.i"], op["lda"], op["lda.p"]):
        acc = operand_data & 0xFF
    elif opcode in (op["sta"], op["sta.p"]):
        bytemem[operand_adr] = acc
    elif opcode in (op["jpc"], op["jpz"], op["jp"]):
        condition = ((link&1)==1) if opcode==op["jpc"] else (acc==0) if opcode==op["jpz"] else True
        pc = operand_adr if condition else pc
    elif opcode == op["lxa"]:
        (link, acc) = (acc & 0x07, link)
    elif opcode == op["rts"]:
        pc = (link << 8) | acc
    elif opcode == op["jsr"]:
        ( pc, acc, link) = (operand_adr, pc&0xFF, (pc >> 8) & 0x07)
    elif opcode == op["halt"]:
        print("Stopped on halt instruction at %04x" % (pc-2) )
        break

if len(sys.argv) > 2:  # Dump memory for inspection if required
    with open(sys.argv[2],"w" ) as f:
        for i in range(0, len(bytemem), 24):
            f.write( '%s\n' %  ' '.join("%02x"%n for n in bytemem[i:i+24]))
