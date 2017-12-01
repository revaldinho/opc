# The root directory of the project
ROOT       = ../../..

# The project .bit file produced by the Xilinx .xise project
PROJECT    = system

# The target .bit file to be generated including the monitor program
TARGET     = system

# Papilio cable specific - location of programmer bscan file
BSCAN   = ../../../common/bscan_spi_xc3s500e.bit

# CPU Name, for include paths
CPU_NAME = opc6

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH = opc6

# CPU File Path, relative to the root directory
CPU_PATH   = opc6/opc6cpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc6/opc6asm.py

# Program Source Path, relative to the root directory
PROG_SRC   = system/firmware/monitor.s

# User Memory
MEM_BOT   ?= 0100
MEM_TOP   ?= 37FF
STACK     ?= 37FF

# Common include files
include $(ROOT)/common/Makefile.inc
include $(ROOT)/common/Makefile_papilio_cable.inc
