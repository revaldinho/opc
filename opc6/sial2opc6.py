import sys, re, codecs

## Get the tokens from the sial.h file directly passed as an argument (in case they change again)
with open(sys.argv[2],"r") as f:
    for l in f.readlines() :
        line = re.sub("//.*", "", l)
        if not re.match(".*({|}|MANIFEST).*", line):
            exec(line.strip(), globals(), locals() )

def getstring( s_list):
    # Convert string in format[ "K<len>", "C<char>" ...] into string
    str = []
    for i in range (1, len(s_list)):
        c = int(s_list[i][1:]) & 0xFF
        if c < 32:
            c = '\\%03o' % c
        else:
            c = chr(c)
        str.append(c)
    return ''.join(str)

def getnum( str ):
    # Convert literal of form K<n> to number
    num = int(str[1:])
    return num

def code ( codestring, source=""):
    words = codestring.split()

    if len(words) > 0 and words[0].endswith(':'):
        leading = ""
        trailing = " "*8
    else :
        leading = " "*8
        trailing = ""
    print( "%s%-32s%s # %s" % (leading,codestring,trailing,source))


def print_header():
    print('''

        ## --------------------------------------------------------------
        ##
        ## OPC to SIAL resource mapping
        ##
        ## r1  == A
        ## r2  == B
        ## r3  == C
        ## r11 == P (local ptr)
        ## r12 == G (global vector ptr)
        ## r15 == PC
        ##
        ## System register usage
        ##
        ## r4,5,6 == tmp registers, not persistent across instructions
        ## r9     == stack pointer on entry to BCPL (used for sys abort)
        ## r10    == Global memory wavefront
        ## r13    == link reg  
        ## r14    == stack ptr          
        ## --------------------------------------------------------------
        ## Cut off this section for running via the monitor on hardware
        ORG 0x0000 
        mov   r14,r0,0x0FFE           # Set stack to grow down from here for monitor
        mov   pc,r0,0x1000            # Program start at 0x1000 for use with monitor/copro
        ## --------------------------------------------------------------

        ORG 0x1000
        PUSHALL ()
        mov r9,r14                          # Snapshot stack pointer in case need of abort
        mov r12,r0,__global_vector          # Global vector and variable space
        mov r11,r0,__global_vector+0x1000   # Rest of space for local variables

        mov r10,r12,0x1000                  # initial free vector memory pointer to 0xEFFF and grows downwards
        mov r3,r11                          # duplicate r11 in r3 because standard subroutine entry will copy r3->r11
        mov r4,r0,__start                   # similar for r4 which will stack the subroutine entry point on entry
        jsr r13,r4                          # Call to main BCPL code
    
__sys_exit:
        halt r0,r0,0x999   # Signal simulator to stop
        POPALL ()
        mov pc, r13        # return to monitor using return address on stack 

        ## BCPL generated code follows
''')

text = []
with open(sys.argv[1],'r') as f:
    line = f.readline()
    while (line):
        newline = f.readline()
        if ( newline and not newline.startswith("F") ):
            line += newline.rstrip()
        else:
            text.append(line)
            line = newline.rstrip()
    if ( line and not line.startswith("F") ):
        line+= newline
    text.append(line)

if len(sys.argv) > 3 and sys.argv[3] == "noheader":
    pass
else:
    print_header()
    
sectionname = ""
modulename = "" 
firstlabel = False
localcounter = 0
global_vector = ["__abort"] * 0x1000
global_vector[3] = "__sys" # will be defined in syslib.s
gv_hightide = 0


for i in text:
    line = i.strip()
    fields = i.split()
    if i.startswith("F"):
        opcode = int(fields[0][1:])
        if opcode == f_section:    # section   Kn C1 ... Cn         Name of section
            sectionname = getstring(fields[1:])
            code("","Section - %s" % sectionname)            
        elif opcode == f_lp:       # lp        Pn         a := P!n 
            code("ld r1,r11,%d" % getnum(fields[1]), line)
        elif opcode == f_lg:       # lg        Gn         a := G!n 
            code("ld r1,r12,%d" % getnum(fields[1]), line)
        elif opcode == f_ll:       # ll        Ln         a := !Ln
            code("ld r1,r0,%s" % fields[1], line)            
        elif opcode == f_llp:      # llp       Pn         a := @ P!n
            code("mov r1, r11, %d" % getnum(fields[1]), line)
        elif opcode == f_llg:      # llg       Gn         a := @ G!n
            code("mov r1, r12, %d" % getnum(fields[1]), line)
        elif opcode == f_lll:      # lll       Ln         a := @ !Ln [ie address of label Ln]
            code("mov r1, r0, %s" % fields[1], line)
        elif opcode in (f_lf,f_lw):# lf or lw   Ln        a := byte or word address of Ln [using word address for both]
            code("mov r1,r0,%s" % fields[1],  line)
        elif opcode == f_l:        # l         Kn         a := n
            code("mov r1,r0,%d" % getnum(fields[1]), line)            
        elif opcode == f_lm:       # lm        Kn         a := - n 
            code("mov r1,r0,%d" % -getnum(fields[1]), line)
        elif opcode == f_sp:       # sp        Pn         P!n := a
            code("sto r1,r11,%d" % getnum(fields[1]), line)
        elif opcode == f_sg:       # sg        Gn         G!n := a
            code("sto r1,r12,%d" % getnum(fields[1]), line)
        elif opcode == f_sl:       # sl        Ln         !Ln := a
            code("sto r1,r0,%s" % fields[1], line)
        elif opcode == f_ap:       # ap        Pn         a := a + P!n
            code("ld r4,r11,%d" % getnum(fields[1]), line)   
            code("add r1,r4")
        elif opcode == f_ag:       # ag        Gn         a := a + G!n
            code("ld r4,r12,%d" % getnum(fields[1]), line)   
            code("add r1,r4")
        elif opcode == f_a:        # a         Kn         a := a + n
            code("add r1,r0,%d" % getnum(fields[1]), line)   
        elif opcode == f_s:        # s         Kn         a := a - n
            code("sub r1,r0,%d" % getnum(fields[1]), line)   
        elif opcode == f_lkp:      # lkp       Kk Pn      a := P!n!k
            code("ld r4,r11,%d" % getnum(fields[2]), line)
            code("ld r1,r4,%d" % getnum(fields[1]))
        elif opcode == f_lkg:      # lkg       Kk Gn      a := G!n!k
            code("ld r4,r12,%d" % getnum(fields[2]), line)
            code("ld r1,r4,%d" % getnum(fields[1]))
        elif opcode == f_st:       # !a := b
            code("sto r2,r1", line)
        elif opcode == f_stp:      # stp       Pn           P!n!a := b
            code("ld r4,r11,%d" % getnum(fields[1]), line)
            code("add r4,r1")
            code("sto r2,r4")
        elif opcode == f_stk:      # stk       Kn           a!n := b
            code("ld r4,r1,%d" % getnum(fields[1]), line)
            code("sto r2,r4")
        elif opcode == f_stkp:     # stkp      Kk Pn        P!n!k := a
            code("ld r4,r11,%d" % getnum(fields[2]), line)
            code("sto r1,r4,%d" % getnum(fields[1]))
        elif opcode == f_skg:      # skg       Kk Gn        G!n!k := a
            code("ld r4,r12,%d" % getnum(fields[2]), line)
            code("sto r1,r4,%d" % getnum(fields[1]))
        elif opcode == f_xst:      # xst                  !b := a
            code("sto r1,r2", line)
        elif opcode == f_rv:       # rv                   a := !a
            code("ld r1,r1", line)
        elif opcode == f_rvp:      # rvp       Pn         a := P!n!a
            code("ld r4,r11,%d" % getnum(fields[1]), line)
            code("add r4,r1")
            code("ld r1,r4")
        elif opcode == f_rvk:      # rvk       Kn         a := a!k
            code("ld r1,r1,%d" % getnum(fields[1]), line)
        elif opcode == f_atb:      # atb                  b := a
            code("mov r2, r1", line)
        elif opcode == f_atc:      # atc                  c := a
            code("mov r3, r1", line)
        elif opcode == f_bta:      # bta                  a := b
            code("mov r1, r2", line)
        elif opcode == f_btc:      # btc                  c := b
            code("mov r3, r2", line)
        elif opcode == f_xch:      # xch                  swap a and b
            code("mov r4, r1", line)
            code("mov r1, r2")
            code("mov r2, r4")
        elif opcode == f_and:      # and                  a := b & a
            code("and r1,r2", line)            
        elif opcode == f_or:       # or                   a := b | a
            code("or r1,r2", line)            
        elif opcode == f_xor:      # xor                  a := b ^ a
            code("xor r1,r2", line)            
        elif opcode == f_eqv:      # eqv                  a := !(b ^ a)
            code("xor r1,r2", line)            
            code("not r1,r1")
        elif opcode == f_neg:      # neg                  a := -a
            code("not r1,r1,-1", line)            
        elif opcode == f_not:      # not                  a := ~ a
            code("not r1,r1", line)            
        elif opcode == f_abs:      # abs                  a := ABS a
            code("not r1,r1,-1", line)   # 2's complement A
            code("mi.not r1,r1-1")       # if negative then 2's complement it back
        elif opcode in (f_lsh,f_rsh):
            # lsh                  a := b << a            
            # rsh                  a := b >> a
            codestring = "add r1,r1" if opcode==f_lsh else "asr r1,r1"            
            code("mov r4,r1",line) # Get the number of places to shift in r4 + 1
            code("mov r1,r2")      # r2 preserved so shift in r1
            code("cmp r4,r0")      # is r4 ==0 (ie shift dist==0)?
            code("z.inc pc,__L%04d - PC" % (localcounter+1))
            code("__L%04d:" % localcounter)
            code(codestring)
            code("dec r4,1")
            code("nz.inc pc,__L%04d - PC" % localcounter) # PC op preserves Z flag from dec r4
            code("__L%04d:" % (localcounter+1))
            localcounter += 2
        elif opcode == f_atbl:     # atbl      Kk         b := a; a := k
            code("mov r2,r1", line)            
            code("mov r1,r0,%d" % getnum(fields[1]))
        elif opcode == f_atblp:    # atblp     Pn         b := a; a := P!n            
            code("mov r2,r1", line)
            code("ld r1,r11,%d" % getnum(fields[1]))                        
        elif opcode == f_atblg:    # atblg     Gn         b := a; a := G!n            
            code("mov r2,r1")
            code("ld r1,r12,%d" % getnum(fields[1]), line)                        
        elif opcode == f_lab:      # lab       Lm         Program label
            code("%s:" % fields[1])
            if firstlabel:
                ## Got here with an OPC jsr 
                code("sto r11,r3")   # C!0 := P
                code("mov r11,r3")   # P   := C
                code("sto r13,r11,1")# P!1 = return address
                code("sto r4,r11,2") # P!2 = entry address
                code("sto r1,r11,3") # P!3 = first argument                
                firstlabel=False
        elif opcode == f_lstr:     # lstr      Mn                   a := Mn   (pointer to string)
            code("mov r1,r0,%s" % fields[1], line)
        elif opcode == f_entry:    # entry     Kn C1 ... Cn         Start of a function
            modulename = getstring(fields[1:])
            code("","Module Entry - %s" % modulename)
            print("__%s:" % modulename)
            firstlabel = True
        elif opcode == f_j:       # j        Ln         Jump to Ln 
            code("mov pc,r0,%s" % fields[1])
        elif opcode == f_jeq:     # jeq      Ln         Jump to Ln if a == b
            code("cmp r1,r2",line)
            code("z.mov pc,r0,%s" % fields[1])
        elif opcode == f_jne:     # jne      Ln         Jump to Ln if a != b
            code("cmp r1,r2",line)
            code("nz.mov pc,r0,%s" % fields[1])
        elif opcode == f_jge:     # jge      Ln         Jump to Ln if b >= a 
            code("cmp r2,r1",line)
            code("pl.mov pc,r0,%s" % fields[1])
        elif opcode == f_jgr:     # jgr      Ln         Jump to Ln if b > a [ ie a < b ] 
            code("cmp r1,r2",line)
            code("mi.mov pc,r0,%s" % fields[1])
        elif opcode == f_jgr0:     # jgr0      Ln       Jump to Ln if a > 0  [ie if 0 < a]
            code("cmp r0,r1",line)
            code("mi.mov pc,r0,%s" % fields[1])
        elif opcode == f_jle:     # jle      Ln         Jump to Ln if b <= a [ie a >= b]
            code("cmp r1,r2",line)
            code("pl.mov pc,r0,%s" % fields[1])
        elif opcode == f_jls:     # jls      Ln         Jump to Ln if b < a 
            code("cmp r2,r1",line)
            code("mi.mov pc,r0,%s" % fields[1])
        elif opcode == f_jeq0:     # jeq0      Ln         Jump to Ln if a == 0
            code("cmp r1,r0",line)
            code("z.mov pc,r0,%s" % fields[1])
        elif opcode == f_jge0:     # jge0      Ln         Jump to Ln if a >= 0
            code("cmp r1,r0",line)
            code("pl.mov pc,r0,%s" % fields[1])
        elif opcode == f_jls0:     # jls0      Ln         Jump to Ln if a < 0
            code("cmp r1,r0",line)
            code("mi.mov pc,r0,%s" % fields[1])
        elif opcode == f_jle0:     # jle0      Ln         Jump to Ln if a <= 0 [or 0>=a]
            code("cmp r0,r1",line)
            code("pl.mov pc,r0,%s" % fields[1])
        elif opcode == f_jne0:     # jne0      Ln         Jump to Ln if a != 0
            code("cmp r1,r0",line)
            code("nz.mov pc,r0,%s" % fields[1])
        elif opcode == f_ip:      # ip        Pn           a := P!n + a; P!n := a
            code("ld r4,r11,%d" % getnum(fields[1]) ,line)
            code("add r1,r4")
            code("sto r1,r11,%d" % getnum(fields[1]))
        elif opcode == f_ig:      # ig        Gn           a := G!n + a; G!n := a
            code("ld r4,r12,%d" % getnum(fields[1]) ,line)
            code("add r1,r4")
            code("sto r1,r12,%d" % getnum(fields[1]))
        elif opcode == f_il:      # il        Ln           a := !Ln + a; !Ln := a
            code("ld r4,r0,%d" % getnum(fields[1]) ,line)
            code("add r1,r4")
            code("sto r1,r0,%d" % getnum(fields[1]))
        elif opcode == f_ikp:      #  ikp       Kk Pn      a := P!n + k; P!n := a
            code("ld  r1,r11,%d" % getnum(fields[2]), line)
            code("add r1,r0,%d" % getnum(fields[1]))
            code("sto r1,r11,%d" % getnum(fields[2]))
        elif opcode == f_ikg:      #  ikg       Kk Gn      a := G!n + k; G!n := a
            code("ld  r1,r12,%d" % getnum(fields[2]), line)
            code("add r1,r0,%d" % getnum(fields[1]))
            code("sto r1,r12,%d" % getnum(fields[2]))
        elif opcode == f_k:        #  k         Pn         Call  a(b,...) incrementing P by n and leaving b in A             
            code("mov r3,r11,%d" % getnum( fields[1]), line)
            ## Need to ensure that B is transferred to A on entry to the routine
            code("mov r4,r1")
            code("mov r1,r2")                        
            code("jsr r13,r4")
        elif opcode == f_kpg:      #  kpg       Pn Gg      Call Gg(a,...) incrementing P by n
            code("mov r3,r11,%d" % getnum( fields[1]), line)
            code("ld r4,r12,%d" % getnum(fields[2]))
            code("jsr r13,r4", "** Call to global function number %s ** " % getnum(fields[2]))
        elif opcode == f_modstart: # modstart                       Start of module 
            code("# Module start", line)
        elif opcode == f_mul :     # xmul                 a := a * b
            code("jsr r13,r0,__mul", line)     # need to have signed multiplication routine here for a * b
        elif opcode == f_add :     # add                  a := a + b
            code("add r1,r2", line)     
        elif opcode == f_sub :     # sub                  a := b - a
            code("sub r1,r2", line)
            code("not r1,r1,-1")
        elif opcode == f_xsub :    # xsub                 a := a - b  c := ??
            code("sub r1,r2", line)
        elif opcode == f_xdiv:     # xdiv                 a := a / b
            code("jsr r13,r0,__div", line)     # need to have signed division routine here for a/b
        elif opcode == f_div:      # div                 a := b / a
            # assume need to swap a and b over here via temp r4 before and after call to sdiv
            code("mov r4,r1", line)
            code("mov r1,r2")
            code("mov r2,r4")
            code("jsr r13,r0,__div")     # need to have signed division routine here for a/b
        elif opcode == f_rem:      # rem                  a := b REM a
            code("jsr r13,r0,__mod", line)     
        elif opcode == f_xrem:      # xrem                  a := a REM b ; c := ?            
            code("jsr r13,r0,__xmod", line)     
        elif opcode == f_eq:           # eq                     a := b = a
            code ("mov r4,r0", line)   # assume answer will be FALSE
            code ("cmp r1,r2")         # compare a with b
            code ("z.xor r4,r0,0xFFFF")# invert answer if zero
            code ("mov r1, r4")        # transfer answer to A                    
        elif opcode == f_ne:           # ne                     a := b ~= a
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r1,r2")         # compare a with b
            code ("z.xor r4,r0,0xFFFF")# invert answer if zero
            code ("mov r1, r4")        # transfer answer to A                    
        elif opcode == f_ls:           # ls                     a := b < a  [ie !(b >= a)]
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r2,r1")         # compare b with a
            code ("pl.xor r4,r0,0xFFFF") # invert answer if b >= a
            code ("mov r1, r4")        # transfer answer to A                    
        elif opcode == f_gr:           # ls                     a := b > a  [ie !(a >= b)]
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r1,r2")         # compare a with b
            code ("pl.xor r4,r0,0xFFFF") # invert answer if a >= b
            code ("mov r1, r4")        # transfer answer to A                   
        elif opcode == f_le:           # ls                     a := b <= a  [ie !(a<b)]
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r1,r2")         # compare a with b
            code ("mi.xor r4,r0,0xFFFF") # invert answer if a < b
            code ("mov r1, r4")        # transfer answer to A                   
        elif opcode == f_ge:           # ge                     a := b >= a  
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r2,r1")         # compare b with a
            code ("mi.xor r4,r0,0xFFFF") # invert answer if b < a
            code ("mov r1, r4")        # transfer answer to A                               

        elif opcode == f_eq0:          # eq0                    a := a = 0
            code ("mov r4,r0", line)   # assume answer will be FALSE
            code ("cmp r1,r0")         # compare with 0
            code ("z.xor r4,r0,0xFFFF") # invert answer if a == 0
            code ("mov r1, r4")        # transfer answer to A                    
        elif opcode == f_ne0:          # ne0                    a := a ~= 0
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r1,r0")         # compare with 0
            code ("z.xor r4,r0,0xFFFF") # invert answer if a == 0
            code ("mov r1, r4")        # transfer answer to A                    
        elif opcode == f_ls0:          # ls0                    a := a < 0
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r1,r0")         # compare with 0
            code ("pl.xor r4,r0,0xFFFF") # invert answer if a >= 0
            code ("mov r1, r4")        # transfer answer to A        
        elif opcode == f_gr0:          #gr0                    a := a > 0 [ie !(0>=A)]
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r0,r1")         
            code ("pl.xor r4,r0,0xFFFF")
            code ("mov r1, r4")        
        elif opcode == f_le0:          #le0                    a := a <= 0 [ie !(0<A)]
            code ("not r4,r0", line)   # assume answer will be TRUE
            code ("cmp r0,r1")         
            code ("mi.xor r4,r0,0xFFFF") 
            code ("mov r1, r4")        
        elif opcode == f_ge0:          # ge0                    a := a >= 0
             code ("mov r4,r0", line)   # assume answer will be FALSE
             code ("cmp r1,r0")         # compare with 0
             code ("pl.xor r4,r0,0xFFFF")# invert answer if a >=0
             code ("mov r1, r4")        # transfer answer to A
 
            
        elif opcode == f_rtn:      # procedure return
            code("ld r4,r11,1", line) # get return address
            code("ld r11,r11")        # restore P pointer
            code("mov pc,r4")          # return
        elif opcode == f_static:   # static    Ln Kk W1 ... Wk      Static variable or table
            code("%s: WORD %s" % (fields[1], ','.join( [("%s"%getnum(i)) for i in fields[3:]])), line)
        elif opcode == f_string:   # string    Ml Kn C1 ... Cn      String constant
            # Encode string constants as word strings initially and make the various byte address
            # operations match (below)
            s = getstring(fields[2:])
            code("%s:" % fields[1],line)
#            code("WORD %d " % getnum(fields[2]))
            code("WORD %d " % len(codecs.decode(s, 'unicode_escape'))) # deal with "\010" etc chars as 1 char
            code("STRING \"%s\"" % s)
            code("WORD 0x00") # Temporary

        elif opcode in (f_gbyt,f_xgbyt,f_pbyt,f_xpbyt):
            # These two function pairs identical if all strings are _words_ rather than bytes
            #   gbyt                   a := b % a
            #   xgbyt                  a := a % b
            #   pbyt                   b % a := c
            #   xpbyt                  a % b := c
            code("mov r4,r1", line)
            code("add r4,r2")            
            if opcode in (f_pbyt,f_xpbyt):
                code("sto r3,r4")
            else:
                code("ld  r1,r4")

        elif opcode == f_swb:      # swb       Kn Ld K1 L1 ... Kn Ln   Binary chop switch, Ld default
            # Jump table on value of A, specific values per label ?
            num_options = getnum(fields[1])            
            default  = fields[2]
            values = [getnum(fields[i]) for i in range(3,num_options*2+3,2)]            
            labels = [fields[i] for i in range(4,num_options*2+4,2)]

            code("",line)
            code("mov r4,r1","Copy A into tmp register")
            for (v,l) in zip(values,labels):
                code("cmp r4,r0,%d" % v)
                code("z.mov pc,r0,%s" % l)            
            code("mov pc,r0,%s" % default, "default jump target")
        elif opcode == f_swl:      #  swl       Kn Ld L1 ... Ln
            # Jump table on value of A
            # Kn is number of options
            # Ld is default destination
            # L1 is destination for value 0
            # Ln is destination for value n-1

            num_options = getnum(fields[1])
            default  = fields[2]
            labels = fields[3:]
            code("",line)
            code("mov r4,r1","Copy A into tmp register")
            for l in labels[:-1]:
                code("z.mov pc,r0,%s" % l)            
                code("dec r4,1")
            code("z.mov pc,r0,%s" % labels[-1])
            code("z.mov pc,r0,%s" % default, "default jump target")
        elif opcode == f_global:   # global    Kn G1 L1 ... Gn Ln   Global initialisation data
            code("", "# Global Resources: %s" % line)
            for i in range (2,len(fields)-1,2):
                entry=getnum(fields[i])
                value=fields[i+1]
                global_vector[entry]=value
                gv_hightide = (max(gv_hightide,entry))              
        elif opcode == f_modend:   # End of module
            code("","Module End - %s" % modulename)
        elif opcode in (f_res,f_ldres):
            code("", line + " [no code for %s]" % fields[0])
        else:
            print("** Opcode Not Handled - %s # %s" % (opcode,line))

            

        # Write global vector at the end of the process
with open("global_vector.s","w") as f:        
    f.write("__global_vector:\n")
    for i in range(0,gv_hightide+(4-(gv_hightide % 4)),4):
        f.write("%-64s %-32s\n" % ("        WORD %s, %s, %s, %s" %  (global_vector[i], global_vector[i+1], global_vector[i+2], global_vector[i+3]) , "# G%d G%d G%d G%d" % ( i,i+1,i+2,i+3)))



