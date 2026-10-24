#!/usr/bin/env python3
'''
 cmp_dump.py [-n num] [-x] <dumpfile1> <dumpfile2>

Compare two memory dumps word by word, eg the emulator's <prog>.emu.dump with
the <prog>.dump written by the Verilog testbench.

Each file is whitespace separated hex words in $readmemh/$writememh style:
'@addr' sets the address of the next word and '//' starts a comment, so the
emulator dump (12 words a line), $writememh output (one word a line) and sparse
hex files are all read. Words not given in a file count as zero. A word
containing x or z (unknown in Verilog) never matches.

 -n num   show at most num differences (default 20)
 -x       skip words that are x or z in either file, eg registers that the
          Verilog CPU stored before they were ever written (the emulator's
          registers start at zero); the number skipped is reported

Exit status is 0 if the dumps match, 1 if they differ.
'''
import getopt
import sys
import re

def read_dump(filename):
    # Return {address: value}, value None for words containing x or z
    (mem, adr) = (dict(), 0)
    with open(filename) as f:
        for line in f:
            for tok in re.sub(r'//.*', '', line).split():
                if tok[0] == '@':
                    adr = int(tok[1:], 16)
                else:
                    mem[adr] = None if re.search('[xXzZ]', tok) else int(tok.replace('_', ''), 16)
                    adr += 1
    return mem

if __name__ == '__main__':
    (maxshow, skipx) = (20, False)
    try:
        opts, args = getopt.getopt(sys.argv[1:], "n:xh", ["help"])
    except getopt.GetoptError:
        print(__doc__)
        sys.exit(2)
    for opt, arg in opts:
        if opt == "-n":
            maxshow = int(arg, 0)
        elif opt == "-x":
            skipx = True
        else:
            print(__doc__)
            sys.exit(2)
    if len(args) != 2:
        print(__doc__)
        sys.exit(2)

    (a, b) = (read_dump(args[0]), read_dump(args[1]))
    (diffs, skipped) = ([], 0)
    for adr in sorted(set(a) | set(b)):
        (va, vb) = (a.get(adr, 0), b.get(adr, 0))
        if skipx and (va is None or vb is None):
            skipped += 1
        elif va is None or va != vb:
            diffs.append(adr)
    show = lambda v: 'xxxxxxxx' if v is None else '%08x' % v
    for adr in diffs[:maxshow]:
        print("0x%05x: %s %s" % (adr, show(a.get(adr, 0)), show(b.get(adr, 0))))
    if len(diffs) > maxshow:
        print("... and %d more" % (len(diffs) - maxshow))
    print("%s and %s: %s%s" % (args[0], args[1],
          "identical" if not diffs else "%d words differ" % len(diffs),
          " (%d x/z words skipped)" % skipped if skipped else ""))
    sys.exit(1 if diffs else 0)
