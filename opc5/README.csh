#!/bin/tcsh
#rm *hex *dump *sim *trace *vcd

foreach test ( test )
    # Assemble the test
    # python3 opc3asm.py ${test}.s ${test}.hex | tee ${test}.lst
    # Run the emulator
    # python3 opc3emu.py ${test}.hex ${test}.dump | tee ${test}.trace
    # Test bench expects the hex file to be called 'test.hex'
    # cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench
    iverilog -D_simulation=1 opc5tb.v opc5cpu.v
    # Execute the test bench
    ./a.out | tee ${test}.sim
    # Save the results
    mv dump.vcd ${test}.vcd
end
