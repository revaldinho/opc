#!/bin/tcsh
rm *hex *dump *sim *trace *vcd

foreach test (ptrtest fib test)
    # Assemble the test
    python3 opc3asm.py ${test}.s ${test}.hex | tee ${test}.lst
    # Run the emulator
    python3 opc3emu.py ${test}.hex ${test}.dump | tee ${test}.trace
    # Test bench expects the hex file to be called 'test.hex'
    cp ${test}.hex test.hex
    # Run icarus verilog to compile the testbench
    iverilog opc3tb.v opc3cpu.v
    # Execute the test bench
    ./a.out | tee ${test}.sim
    # Save the results
    mv dump.vcd ${test}.vcd
    mv test.vdump ${test}.vdump

    python3 ../utils/mdumpcheck.py ${test}.dump  ${test}.vdump
end
