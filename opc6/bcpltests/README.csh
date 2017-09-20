#!/bin/tcsh -f
#
#

# Clean up first
rm *tmp* *lst *dump *output *trace *hex 

pypy3 --version > /dev/null
if ( $status) then
    set pyexec = python3
else
    set pyexec = pypy3
endif

set testnames = ( hello  fact  monbfns invert ack pi-spigot-bcpl anseq  enig  enigma-m3 apfel queens )

echo "Updating Library"
# Update the library
cintsys -c bcpl2sial bcpllib.b to bcpllib.sial

foreach testname ( $testnames )
    echo "**************************"
    echo "Processing $testname"
    echo "**************************"    
    # Make BCPL and SIAL versions of test
    cintsys -c bcpl $testname.b to $testname
    cintsys -c bcpl2sial $testname.b to $testname.sial

    python3 ../sial2opc6.py -f $testname.sial -f bcpllib.sial -s syslib.s > tmp.s

    # A some simple 'ROM' for simulation (not needed for use on the hardware)
    cat tmp.s rom.s > ${testname}.s
    
    if ( `grep -c "Opcode Not Handled" ${testname}.s` != 0 ) then
        echo "ERROR  - some Opcodes not handled in SIAL to OPC translation"
        grep "Opcode Not Handled" ${testname}.s
    else
        if ( -e ${testname}.stdin ) then
            set stdin = ${testname}.stdin
        else
            set stdin = ""
        endif
        ${pyexec} ../opc6asm.py ${testname}.s ${testname}.hex  > ${testname}.lst
        ${pyexec} ../opc6emu.py ${testname}.hex ${testname}.dump ${stdin} | grep OUT | ../../utils/show_stdout.py | tee ${testname}.output
    endif     
end
