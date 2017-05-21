# compare two memory dumps from emulator and verilog
#
# python3 mdumpcheck.py <emulator_dump> <verilog_dump>


import sys, re

emumem = [0]*65536
simmem = [0]*65536

with open(sys.argv[1],"r") as f:
    emumem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]

with open(sys.argv[2],"r") as f:
    lines = [x for x in f.readlines() if not re.match("\s*?\/\/.*?", x)  ]

simmem = [ (int(x.strip(),16) & 0xFFFF) for x in lines ]

fails=0
loc = 0
for (e,s) in zip(emumem,simmem):
    if e != s:
        fails += 1
        print("Fail at location %d : emulator: %04x  simulation: %04x" % (loc,e,s))
    loc += 1

if fails ==0 :
    print("PASS - Emulation and Simulation results match")
else:
    print("FAIL - Emulation and Simulation results differ")
