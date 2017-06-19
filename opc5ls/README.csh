#!/bin/tcsh
# Remove non primary data files
rm -rf *~ `ls -1 | egrep -v '(\.v|\.csh|\.ucf|\.py|\.s|spartan|xc95)'`

foreach test ( fib robfib davefib mul32 udiv32 sqrt hello testpsr string davefib_int sqrt_int pi-spigot-bruce )
    # Assemble the test
    python3 opc5lsasm.py ${test}.s ${test}.hex >  ${test}.lst
    # Run the emulator
    python3 opc5lsemu.py ${test}.hex ${test}.dump > ${test}.trace
    # Test bench expects the hex file to be called 'test.hex'
    cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench

    foreach option ( NEGEDGE_MEMORY POSEDGE_MEMORY )
        iverilog -D_simulation=1 -D${option}=1 opc5lstb.v opc5lscpu.v
        # Execute the test bench
        ./a.out | tee ${test}_${option}.sim
        # Save the results
        mv dump.vcd ${test}_${option}.vcd
        mv test.vdump ${test}_${option}.vdump
    end
end

echo ""
echo "Comparing memory dumps between emulation and simulation"
echo "-------------------------------------------------------"
foreach test ( fib robfib davefib mul32 udiv32 sqrt hello testpsr string pi-spigot-bruce davefib_int sqrt_int  )
    foreach option ( NEGEDGE_MEMORY POSEDGE_MEMORY )
        printf "%32s :" ${test}_${option}
        if "${test}" =~ "*int" then
            python3 ../utils/mdumpcheck.py ${test}.dump  ${test}_${option}.vdump 0xF000 0x0500 0xFFFF
        else
            python3 ../utils/mdumpcheck.py ${test}.dump  ${test}_${option}.vdump
        endif
    end
end
