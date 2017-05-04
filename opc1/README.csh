#!/bin/tcsh
foreach test (test fib)
    # Assemble the test
    python3 opcasm.py ${test}.s ${test}.hex
    # Run the emulator
    python3 opcemu.py ${test}.hex ${test}.dump
    # Test bench expects the hex file to be called 'test.hex'
    cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench
    iverilog opctb.v opccpu.v
    # Execute the test bench
    ./a.out
    # Save the results
    mv dump.vcd ${test}.vcd
end
