'''
   python3.6 6to7.py [-8] -f input_file

'''

import sys
import re
import getopt


to7=True
filename = ""

try:
    opts, args = getopt.getopt( sys.argv[1:], "f:8h", ["file=","opc8","help"])
except getopt.GetoptError:    
    print( __doc__) 
    sys.exit()

for opt, arg in opts:
    if opt in ( "-f", "--file" ) :
        filename = arg
    elif opt in ( "-8", "--opc8" ) :            
        to7 = False
    elif opt in ( "-h","--help" ) :            
        print( __doc__) 
        sys.exit()
    
if ( filename=="" ) :
    print( __doc__) 
    sys.exit()



jsr_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(jsr)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
mov_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(mov)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
sto_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(sto)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
ld_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(ld)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
inout_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(out|in)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
incdec_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(inc|dec)\s*(r\d*|pc)\s*,(.*)")
pushpop_re=re.compile("((?:\w*\:?)\s*)(push|pop)\s*(r\d*|pc)\s*,\s*(.*?)((?:#|$).*)") 

with open(filename, "r") as fh:
    for l in fh:
        matched = False
        mobj = incdec_re.match(l)
        if ( mobj ):            
            op = "add" if re.search("inc",mobj.group(3)) else "sub"
            pred_op = "%s%s" % ("" if mobj.group(2)==None else mobj.group(2), op )
            print( "%s%-7s %s,r0,%s" % ((mobj.group(1),pred_op,mobj.group(4),mobj.group(5))))
            matched = True

        mobj = pushpop_re.match(l)
        if ( mobj ):            
            op = "PUSH" if re.search("push",mobj.group(2)) else "POP"
            print( "%s%s (%s,%s) %s" % (mobj.group(1),op,mobj.group(3),mobj.group(4).strip(),mobj.group(5)))
            matched = True
    
        if ( to7 ): 
            for (op, regex) in zip( ["ljsr","lmov","lsto","lld"], [jsr_re,mov_re,sto_re,ld_re]):
                 mobj = regex.match(l)
                 if ( mobj ):            
                     pred_op = "%s%s" % ("" if mobj.group(2)==None else mobj.group(2), op )
                     print( "%s%-7s %s,%s" % (mobj.group(1),pred_op,mobj.group(4).rstrip(),mobj.group(5).rstrip()))
                     matched = True
                     break
        else: 
            ## For OPC8 remap all IO to 0xFF<IO_PORT>
            mobj = inout_re.match(l)
            if ( mobj ):            
                op = "sto" if re.search("out",mobj.group(3)) else "ld"
                pred_op = "%s%s" % ("" if mobj.group(2)==None else mobj.group(2), op )
                print( "%s%-7s %s,r0,%s" % ((mobj.group(1),pred_op,mobj.group(4),"0x%06x" %(0xFF0000 | int(mobj.group(5),0)))))
                matched = True
    
        if not matched : 
            print(l.rstrip())

fh.close()
        
