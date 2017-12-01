# The root directory of the project
ROOT       = ../../..

# The project .bit file produced by the Xilinx .xise project
PROJECT    = wrapper

# The target .bit file to be generated including the monitor program
TARGET     = system

# Xilinx cable specific - the prom type
PROM    = W25Q64BV

# CPU Name, for include paths
CPU_NAME = opc5ls-xp

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH = opc5ls

# CPU File Path, relative to the root directory
CPU_PATH   = opc5ls-xp/opc5lscpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc5ls/opc5lsasm.py

# Program Source Path, relative to the root directory
PROG_SRC   = system/firmware/monitor.s

# User Memory
MEM_BOT   ?= 0100
MEM_TOP   ?= 37FF
STACK     ?= 37FF

# Common include files
include $(ROOT)/common/Makefile.inc
include $(ROOT)/common/Makefile_xilinx_cable_spi.inc
