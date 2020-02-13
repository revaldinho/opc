#!/bin/bash

SRCS="../system_32.v ../ram_3584_32.v ../../../opc7/opc7cpu.v ../../src/uart.v"

rm -f a.out
iverilog -Dsimulate -Dcpu_opc7 ../system_tb.v $SRCS
rm -f dump.vcd
if [ -f a.out ]
then
    ./a.out
    if [ -f dump.vcd ]
    then
        gtkwave -g -a signals.gtkw dump.vcd
    fi
fi
