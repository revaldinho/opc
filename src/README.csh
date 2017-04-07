#!/bin/tcsh

# Assemble the test
python3 opcasm.py test.s test.bin
# Run the emulator
python3 opcemu.py test.bin test.emu

# Convert the binary to hex (tempoary step)
python2.7 ~/Documents/Development/sockets/trunk/rombo/hex2bin.py -i bin -o hex -f test.bin -g test.hex -d 4096

# Run icarus verilog to compile the testbench
iverilog opctb.v opccpu.v

# Execute the test bench
./a.out
