# compare two memory dumps from emulator and verilog
#
# python3 mdumpcheck.py <emulator_dump> <verilog_dump> <ignore_above> <swi_count> <hwi_count>


import sys, re

emumem = [0]*65536
simmem = [0]*65536

ignore_above = 0xFFFF if len(sys.argv) < 4 else int(sys.argv[3],0)
swi_count = -1 if len(sys.argv) < 5 else int(sys.argv[4],0)
hwi_count = -1 if len(sys.argv) < 6 else int(sys.argv[5],0)



with open(sys.argv[1],"r") as f:
    emumem = [ (int(x,16) & 0xFFFF) for x in f.read().split() ]

with open(sys.argv[2],"r") as f:
    lines = [x for x in f.readlines() if not re.match("\s*?\/\/.*?", x)  ]

simmem = [ (int(x.strip(),16) & 0xFFFF) for x in lines ]

fails=0
loc = 0
for (e,s) in zip(emumem,simmem):
    if e != s and (0 < loc < ignore_above):
        fails += 1
        print("Fail at location %d : emulator: %04x  simulation: %04x" % (loc,e,s))
    loc += 1

if fails ==0 :
    print("PASS - Emulation and Simulation results match.", end="")
else:
    print("FAIL - Emulation and Simulation results differ", end="")

if (swi_count > 0):
    print (" Took %d Software interrupts" % simmem[swi_count], end="")
if (hwi_count > 0):
    print ("; %d hardware interrupts," % simmem[hwi_count], end="")

print("")
