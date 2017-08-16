#!/bin/bash

TOP=system
NAME=system
PACKAGE=tq144:4k
SRCS="../system.v  ../ram_4k_16.v ../../../opc6/opc6cpu.v ../../src/uart.v"

yosys -q -f "verilog -Dcpu_opc6" -p "synth_ice40 -top ${TOP} -abc2 -blif ${NAME}.blif" ${SRCS}
arachne-pnr -d 8k -P ${PACKAGE} -p ../blackice.pcf ${NAME}.blif -o ${NAME}.txt
icepack ${NAME}.txt ${NAME}.bin
icetime -d hx8k -P ${PACKAGE} ${NAME}.txt

