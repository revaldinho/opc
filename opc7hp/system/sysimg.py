#!/usr/bin/env python3
'''
sysimg.py - split an OPC7 program image for the OPC7 system (opc7hsys.v)

  sysimg.py prog.hex rom.hex ram.hex [ram_aw]

prog.hex is opc7asm.py output ($readmemh format: '@addr' sets the word address, then hex words).
Words below 0x1000 go to rom.hex (4096 words, the boot ROM); the rest to ram.hex, at their address
modulo 2**ram_aw (default 20: the whole space), as the system's RAM repeats through the space.
Fails if two words land on the same RAM word or the program doesn't fit.
'''
import sys

def main():
    if len(sys.argv) < 4:
        sys.exit(__doc__)
    src, romf, ramf = sys.argv[1:4]
    aw = int(sys.argv[4]) if len(sys.argv) > 4 else 20
    rom, ram, adr = [0] * 4096, {}, 0
    for x in open(src).read().split():
        if x[0] == '@':
            adr = int(x[1:], 16)
            continue
        w = int(x, 16) & 0xFFFFFFFF
        if adr < 0x1000:
            rom[adr] = w
        else:
            i = adr & ((1 << aw) - 1)
            if i < 0x1000:
                sys.exit('sysimg.py: word at 0x%05x lands under the ROM in a %d word RAM' % (adr, 1 << aw))
            if i in ram and ram[i] != w:
                sys.exit('sysimg.py: words at 0x%05x and another address share RAM word 0x%05x' % (adr, i))
            ram[i] = w
        adr += 1
    with open(romf, 'w') as f:
        f.write('\n'.join('%08x' % w for w in rom) + '\n')
    with open(ramf, 'w') as f:
        last = None
        for i in sorted(ram):
            if i != last:
                f.write('@%05x\n' % i)
            f.write('%08x\n' % ram[i])
            last = i + 1
    used = max(rom.index(w) for w in rom if w) if any(rom) else 0
    print('sysimg.py: ROM to 0x%03x, RAM %d words (0x%05x-0x%05x)' % (used, len(ram), min(ram, default=0), max(ram, default=0)))

main()
