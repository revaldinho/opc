# Generate static or dynamic(runtime) stats on instruction and predicate usage from emulator trace or assembler listing files
#
import re, sys, getopt

def show_usage_and_exit():
    sys.exit("Usage:  python3 histogram.py [-d|--dynamic][-s|--static] [-f|--filename <test.trace>|<test.lst>][-v,--verbose]")

def generate_histograms(filename, type, verbose=False):
    if type == "Dynamic":
        instr_re = re.compile("[0-9a-f]{4}\s*:\s*(?P<opcode>[0-9a-f]{4})\s*?(?P<operand>[0-9a-f]{4})?\s*: ((?P<pred>(mi|pl|z|c|nz|nc))\.)?(?P<instr>\w*)\s+(?P<rd>r\d*|psr),.*")
    else:
        instr_re = re.compile("[0-9a-f]{4}\s+(?P<opcode>[0-9a-f]{4})\s*?(?P<operand>[0-9a-f]{4})?\s+(?P<label>\w+?\:\s+)?((?P<pred>(mi|pl|z|c|nz|nc))\.)?(?P<instr>[a-z]+)\s+(?P<rd>\w+)")


    one_word_instr_count = 0
    two_word_instr_count = 0    
    instr_dict = dict();
    pinstr_dict = dict();
    preds_dict  = dict();
    
    with open(filename,"r") as f:
        for line in f: 
            pobj = instr_re.match(re.sub('#.*','',(line.strip())))
            if pobj and pobj.groupdict()['instr'] != None:
                if ( pobj.groupdict()["operand"] ) == None:
                    one_word_instr_count += 1
                else:
                    two_word_instr_count += 1                    
                predicate = pobj.groupdict()["pred"]
                instr     = pobj.groupdict()["instr"]
                rd        = pobj.groupdict()["rd"]    
                if rd in ('r15','pc'):
                    instr = instr+'[dst=pc]'    
                if predicate:
                    if predicate in preds_dict:
                        preds_dict[predicate] += 1
                    else:
                        preds_dict[predicate] = 1
                    if instr in pinstr_dict:
                        pinstr_dict[instr] += 1
                    else:
                        pinstr_dict[instr] = 1             
                if instr in instr_dict:
                    instr_dict[instr] += 1
                else:
                    instr_dict[instr] = 1       
            else:
                if verbose:
                    print(line.strip())
                    
    if ( len(instr_dict)==0 ) :
        print("Error: No instructions match regular expressions - is this a valid %s file ?" % ("trace" if type=="Dynamic" else "assembler listing"))
        show_usage_and_exit()
    
    maxcount = max ( instr_dict[i] for i in instr_dict )
    maxpred = max ( preds_dict[i] for i in preds_dict )
    
    print("\n%s Instruction Usage from %s"% (type, filename))
    print("\nAll Instructions\n")
    for (i,count) in  sorted(instr_dict.items(), key=lambda x:x[1],reverse=True):
        stars = '*' * (64 * count//maxcount +1)
        print ("%14s %10d : %s" % (i,count, stars))
    
    print("\nInstructions using predication\n")
    for (i,count) in  sorted(pinstr_dict.items(), key=lambda x:x[1],reverse=True):
        stars = '*' * (64 * count//maxcount +1)
        print ("%14s %10d : %s" % (i,count, stars))
    
    print("\nPredicate usage\n")
    for (i,count) in  sorted(preds_dict.items(), key=lambda x:x[1],reverse=True):
        stars = '*' * (64 * count//maxpred +1)
        print ("%14s %10d : %s" % (i,count, stars))

    print("")

    total_instr = sum(instr_dict.values())
    total_pinstr = sum(pinstr_dict.values())
    total_jumps = sum([instr_dict[k] for k in instr_dict if k in ("add[dst=pc]","mov[dst=pc]") ])
    total_short_branches = sum(  [instr_dict[k] for k in instr_dict if k in ("inc[dst=pc]","dec[dst=pc]") ])

    print("\nInstruction Summary by Type\n")
    print("All instructions          : %10d" %total_instr)
    print("- Single word             : %10d (%3.1f%%)" % (one_word_instr_count, float(one_word_instr_count)/float(total_instr)*100))
    print("- Two word                : %10d (%3.1f%%)" % (two_word_instr_count, float(two_word_instr_count)/float(total_instr)*100))        
    print("Predicated instructions   : %10d (%3.1f%%)" % (total_pinstr,(float(total_pinstr)/float(total_instr)*100)))
    print("Jumps                     : %10d" % total_jumps)
    print("Short Branches            : %10d" % total_short_branches)

if __name__ == "__main__":
    type = "Dynamic"
    filename = ""
    verbose=False
    try:
        opts, args = getopt.getopt( sys.argv[1:], "f:dshv", ["filename=","dynamic","static","help","verbose"])
    except getopt.GetoptError:
        show_usage_and_exit()
    for opt, arg in opts:
        if opt in ( "-d", "--dynamic" ) :
            type = "Dynamic"
        elif opt in ( "-s", "--static" ) :
            type = "Static"
        elif opt in ( "-v", "--verbose" ) :
            verbose=True
        elif opt in ( "-f", "--filename" ) :            
            filename = arg
        elif opt in ( "-h","--help" ) :            
            show_usage_and_exit()
    if (filename==""):
        show_usage_and_exit()
    
    generate_histograms(filename,type,verbose)
