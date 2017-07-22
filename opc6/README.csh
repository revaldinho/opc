#!/bin/tcsh -f
# Remove non primary data files
rm -rf *~ *sim *trace *vcd *dump `ls -1 | egrep -v '(\.v$|\.csh|\.ucf|\.py|\.s$|spartan|xc95|opc6system|opc6copro)'`

if ( $#argv > 0 ) then 
    if ( $argv[1] == "clean" ) exit
endif

set vpath = ""

#Check for pypy3
pypy3 --version > /dev/null
if ( $status) then
    set pyexec = python3
else
    set pyexec = pypy3
endif

set testlist = ( fib robfib  hello string  davefib mul32 udiv32 sqrt davefib_int pi-spigot-rev testpsr sqrt_int pi-spigot-bruce sieve e-spigot-rev bigsieve )
foreach test ( $testlist )
    echo "Running Test $test"
    # Assemble the test
    python3 opc6asm.py ${test}.s ${test}.hex >  ${test}.lst
    # Run the emulator
    ${pyexec} opc6emu.py ${test}.hex ${test}.dump > ${test}.trace
    # Test bench expects the hex file to be called 'test.hex'
    cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench

    foreach option ( NEGEDGE_MEMORY POSEDGE_MEMORY )
        iverilog -D_simulation=1 -D${option}=1 opc6tb.v ${vpath}opc6cpu.v
        # Execute the test bench
        ./a.out | tee ${vpath}${test}_${option}.sim
        # Save the results
        mv dump.vcd ${vpath}${test}_${option}.vcd
        mv test.vdump ${vpath}${test}_${option}.vdump
    end
end

echo ""
echo "Comparing memory dumps between emulation and simulation"
echo "-------------------------------------------------------"
foreach test ( $testlist )
    foreach option ( NEGEDGE_MEMORY POSEDGE_MEMORY )
        printf "%32s :" ${test}_${option}
        if "${test}" =~ "*int" then
            python3 ../utils/mdumpcheck.py ${test}.dump  ${vpath}${test}_${option}.vdump 0xF000 0x8000 0xFFFF
        else
            python3 ../utils/mdumpcheck.py ${test}.dump  ${vpath}${test}_${option}.vdump
        endif
    end
end
