#!/bin/tcsh -f
#
# README [NOOPT]
if ($1 == "NOOPT") then
    echo "Running with non-optimized SIAL"
    unsetenv OPT
else
    setenv OPT -o
endif

pypy3 --version > /dev/null
if ( $status) then
    set pyexec = python3
else
    set pyexec = pypy3
endif

# NB cannot simulate tests needing stdin currently = enigma-m3
set simlist = ( Leval ack acoding anseq apfel enig evale fact fft16 growth hello invert kext kperms lambda modarith monbfns pi-spigot-bcpl queens shell23 splay tag Xsquare )

## Make all BCPL -> SIAL -> ASM
make all_asm -j 4
make all_emulation -j 4 -s

foreach testname ( `ls -1 *s | egrep -v '(rom|syslib)' ` )
    if ( `grep -c "Opcode Not Handled" ${testname}` != 0 ) then
        echo "ERROR  - some Opcodes not handled in SIAL to OPC translation"
        grep "Opcode Not Handled" ${testname}.s
    endif
end


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
