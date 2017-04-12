#!/bin/tcsh

# Assemble the test
python3 opcasm.py test.s test.hex
# Run the emulator
python3 opcemu.py test.hex test.emu


#xxd -p -c 16 test.bin | sed 's/\(..\)/\1 /g' > test.hex

# Run icarus verilog to compile the testbench
iverilog opctb.v opccpu.v

# Execute the test bench
./a.out
