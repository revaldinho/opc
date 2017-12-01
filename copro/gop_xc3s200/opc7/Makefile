# The root directory of the project
ROOT       = ../../..

# The project .bit file produced by the Xilinx .xise project
PROJECT    = copro

# The target .bit file to be generated including the monitor program
TARGET     = copro

# Xilinx cable specific - the prom type
PROM       = xcf01s

# CPU Name, for include paths
CPU_NAME = opc7

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH = opc7

# CPU File Path, relative to the root directory
CPU_PATH   = opc7/opc7cpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc7/opc7asm.py

# Program Source Path, relative to the root directory
PROG_SRC   = copro/firmware/tuberom.s

# Start address (in words) of the ROM (in the assembler output)
ROMSTART   = 0000

# Length address (in words) of the ROM (in the assembler output)
ROMLEN     = 0800

# Width of the ROM (in bytes)
ROMWIDTH   = 4

# User Memory
ifeq ($(PITUBEDIRECT),1)
MEM_BOT   ?= 00000800
MEM_TOP   ?= FFFFFFFF
STACK     ?= FFFFFFFF
else
MEM_BOT   ?= 00000600
MEM_TOP   ?= 00000FFF
STACK     ?= 00000FFF
endif

# Common include files
include $(ROOT)/common/Makefile.inc
include $(ROOT)/common/Makefile_xilinx_cable_serial.inc
