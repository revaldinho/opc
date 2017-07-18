#
# Unbounded spigot from Gibbons for computing pi or e.
#
# https://www.cs.ox.ac.uk/jeremy.gibbons/publications/spigot.pdf
#
# python3 pi_e.py  [ -p, --pi] [-e,--e] [-d, --digits <num of digits> ]
#

import getopt, sys


def gibbons_spigot( eorpi, maxdigits):
    if eorpi == 'e':
        (hi, lo, d, f )  = (2,1,0, lambda k: (1, k, 1))    ## setup for e
    else:
        (hi, lo, d, f)   = (3,4,0, lambda k: (k, 2*k+1, 2))## setup for pi
    
    (a,b,c,i,digits) = (1,0,1,0,0)
    
    max_ubound=0
    max_lbound=0
    max_a = 0
    max_b = 0
    max_c = 0

    digits = []
    
    while len(digits) < maxdigits:
        lbound = (a*lo +b)//c 
        ubound = (a*hi +b)//c
    
        max_lbound = max(lbound,max_lbound)
        max_ubound = max(lbound,max_ubound)
        if lbound == ubound:
            digits.append( str(lbound) )
            a = 10 * a
            b = 10 * b - 10*lbound*c
    
            max_a = max(a, max_a)
            max_b = max(b, max_b)
        else:
            i+= 1
            (n,d,s) = f(i)
            (a, b, c )  = (a * n, (a*s*d) + (b*d), c*d) 
            max_a = max(a, max_a)
            max_b = max(b, max_b)
            max_c = max(c, max_c)

    print(''.join(digits))
    print("max_lbound 0x%4X" % max_lbound)
    print("max_ubound 0x%4X" % max_ubound)
    print("max_a      0x%4X" % max_a)
    print("max_b      0x%4X" % max_b)
    print("max_c      0x%4X" % max_c)

    

if __name__ == "__main__":
    digits = 10
    formula = 'e'
    try:
        opts, args = getopt.getopt( sys.argv[1:], "d:ep", ["digits=", "e","pi"])
    except getopt.GetoptError as  err:
        print(err)

    for opt, arg in opts:
        if opt in ( "-d", "--digits" ) :
            digits = int(arg)
        elif opt in ("-p", "--pi"):
            formula = 'pi'
        elif opt in ("-e", "--e"):
            formula = 'e'

    gibbons_spigot( formula, digits)
