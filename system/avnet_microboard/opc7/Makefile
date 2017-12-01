# The root directory of the project
ROOT       = ../../..

# The project .bit file produced by the Xilinx .xise project
PROJECT    = wrapper

# The target .bit file to be generated including the monitor program
TARGET     = system

# Xilinx cable specific - the prom type
PROM    = N25Q128

# CPU Name, for include paths
CPU_NAME = opc7

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH = opc7

# CPU File Path, relative to the root directory
CPU_PATH   = opc7/opc7cpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc7/opc7asm.py

# Program Source Path, relative to the root directory
PROG_SRC   = system/firmware/monitor.s

# Extract a smaller ROM
ROMSTART   = 0000
ROMLEN     = 1000
ROMWIDTH   = 4

# User Memory
MEM_BOT   ?= 0800
MEM_TOP   ?= 1FFF
STACK     ?= 1FFF

# Common include files
include $(ROOT)/common/Makefile.inc
include $(ROOT)/common/Makefile_xilinx_cable_spi.inc
