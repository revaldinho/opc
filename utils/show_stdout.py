import re
import sys

stdout_re = re.compile("\s*?OUT:.*?Data : 0x.*? \(\s*?(\d*)\).*?")

with open(sys.argv[1], "r") as f:
    lines = f.readlines()
    for l in lines:
        mobj = stdout_re.match(l)
        if mobj:
            ch = chr( int(mobj.group(1)) )
            print(ch, end="")
    

