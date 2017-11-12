
   
import sys
import re

jsr_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(jsr)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
mov_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(mov)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
sto_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(sto)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
ld_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(ld)\s*(r\d*|pc)\s*,\s*(?:r0)\s*,\s*(.*)")
incdec_re=re.compile("((?:\w*\:?)\s*)(\w*\.)?(inc|dec)\s*(r\d*|pc)\s*,(.*)")
pushpop_re=re.compile("((?:\w*\:?)\s*)(push|pop)\s*(r\d*|pc)\s*,\s*(.*?)((?:#|$).*)") 

for l in sys.stdin.readlines():
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

    for (op, regex) in zip( ["ljsr","lmov","lsto","lld"], [jsr_re,mov_re,sto_re,ld_re]):
         mobj = regex.match(l)
         if ( mobj ):            
             pred_op = "%s%s" % ("" if mobj.group(2)==None else mobj.group(2), op )
             print( "%s%-7s %s,%s" % (mobj.group(1),pred_op,mobj.group(4).rstrip(),mobj.group(5).rstrip()))
             matched = True
             break

    if not matched : 
        print(l.rstrip())

        
