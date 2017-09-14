#!/bin/tcsh -f

# Clean up first
rm *tmp* *lst *dump *output *trace *hex 


set testnames = ( pi-spigot-bcpl fact monbfns anseq  enig  enigma-m3 apfel queens )

set testnames = ( pi-spigot-bcpl )

# Update the library
cintsys -c bcpl2sial bcpllib.b to bcpllib.sial

foreach testname ( $testnames ) 
    # Make BCPL and SIAL versions of test
    cintsys -c bcpl $testname.b to $testname
    cintsys -c bcpl2sial $testname.b to $testname.sial


    pypy3 --version >& /dev/null
    if ( $status == 0 ) then
        set pyexe = pypy3
    else
        set pyexe = python3
    endif
        
    
    perl -0777 -pale 's/ L(\d*)/ L$1_blib/g' bcpllib.sial |\
    perl -0777 -pale 's/ M(\d\d\d\d)/ M$1_blib/g'  > tmplib.sial
    python3 ../sial2opc6.py  tmplib.sial sial.h noheader > bcpllib.s
    
    cat ${testname}.sial tmplib.sial > tmp.sial
    python3 ../sial2opc6.py  tmp.sial  sial.h  > tmp.s
    
    cat macro.s tmp.s syslib.s global_vector.s rom.s > ${testname}.s
    
    if ( `grep -c "Opcode Not Handled" ${testname}.s` != 0 ) then
        echo "ERROR  - some Opcodes not handled in SIAL to OPC translation"
        grep "Opcode Not Handled" ${testname}.s
    else
        if ( -e ${testname}.stdin ) then
            set stdin = ${testname}.stdin
        else
            set stdin = ""
        endif
        python3 ../opc6asm.py ${testname}.s ${testname}.hex  | tee ${testname}.lst
        ${pyexe} ../opc6emu.py ${testname}.hex ${testname}.dump ${stdin} | tee ${testname}.trace | grep OUT | tee ${testname}.tmp
        python3 ../../utils/show_stdout.py ${testname}.tmp > ${testname}.output
    endif
        
end


