#!/bin/bash

SRCS="../system.v  ../ram_4k_16.v ../../../opc6/opc6cpu.v ../../src/uart.v"

rm -f a.out
iverilog -Dsimulate -Dcpu_opc6 ../system_tb.v $SRCS
rm -f dump.vcd
if [ -f a.out ]
then
    ./a.out    
    if [ -f dump.vcd ]
    then
        gtkwave -g -a signals.gtkw dump.vcd
    fi
fi
