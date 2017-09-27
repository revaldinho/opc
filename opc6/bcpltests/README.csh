#!/bin/tcsh -f
#
#

# Clean up first
rm *tmp* *lst *dump *output *trace *hex  *trace.gz *sasm

pypy3 --version > /dev/null
if ( $status) then
    set pyexec = python3
else
    set pyexec = pypy3
endif

set testnames = ( hello fact Leval monbfns lambda modarith fft16 evale invert ack pi-spigot-bcpl anseq  enig  enigma-m3 shell23 acoding kperms  apfel queens )

echo "Updating Library"
# Update the library
cintsys -c bcpl2sial bcpllib.b to bcpllib.sial
# Optional - reprocess the SIAL into SASM to be more human readable, but SIAL is the format used for
# conversion to OPC6 later
cintsys -c sial-sasm  bcpllib.sial to bcpllib.sasm

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
        ${pyexec} ../opc6emu.py ${testname}.hex ${testname}.dump ${stdin} | tee ${testname}.trace | grep OUT | ../../utils/show_stdout.py | tee ${testname}.output
        gzip -f ${testname}.trace &
    endif     
end
wait

