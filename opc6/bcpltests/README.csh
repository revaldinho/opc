#!/bin/tcsh -f
#
# README [OPT]


if ($1 == "OPT") then
    echo "Running with optimized SIAL"
    set opt_flag = "-o"
else
    set opt_flag = ""
endif

pypy3 --version > /dev/null
if ( $status) then
    set pyexec = python3
else
    set pyexec = pypy3
endif

set testnames = ( empty Leval ack acoding anseq apfel enig enigma-m3 evale fact fft16 growth hello invert kext kperms lambda modarith monbfns pi-spigot-bcpl queens shell23 splay tag Xsquare )
set testnames = ( enigma-m3 )
# NB cannot simulate tests needing stdin currently = enigma-m3
set simlist = ( Leval ack acoding anseq apfel enig evale fact fft16 growth hello invert kext kperms lambda modarith monbfns pi-spigot-bcpl queens shell23 splay tag Xsquare )
# Clean up first
rm *tmp* *lst *dump *output *trace *hex  *trace.gz *sasm

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

    python3 ../sial2opc6.py -f $testname.sial -f bcpllib.sial -s syslib.s -g ext_sial.h $opt_flag > tmp.s

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
        ${pyexec} ../opc6byteasm.py ${testname}.s ${testname}.hex  > ${testname}.lst
#        ${pyexec} ../opc6emu.py ${testname}.hex ${testname}.dump ${stdin} | tee ${testname}.trace | grep OUT | ../../utils/show_stdout.py | tee ${testname}.output
        ${pyexec} ../opc6emu.py ${testname}.hex ${testname}.dump ${stdin} | grep OUT | ../../utils/show_stdout.py | tee ${testname}.output
        if (-e ${testname}.trace ) gzip -f ${testname}.trace &

        # Clean up
        if -e {$testname} rm -f ${testname}
        #if -e {$testname}.sial rm -f ${testname}.sial
    endif
end
wait

simulation:

# Run some selected simulations
rm -rf *~ *sim *trace *vcd *vdump
foreach test ( $simlist )
    echo "Simulating Test $test"
    # Test bench expects the hex file to be called 'test.hex'
    cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench only if there is no stdin file
    iverilog -D_simulation=1 -DNEGEDGE_MEMORY=1 ../opc6tb.v ../opc6cpu.v
    # -D_dumpvcd=1
    # Execute the test bench
    ./a.out | tee ${test}.sim
    # Save the results
    if ( -e dump.vcd) then
        mv dump.vcd ${test}.vcd
    endif
    mv test.vdump ${test}.vdump
end


wait
