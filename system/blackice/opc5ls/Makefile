# The root directory of the project
ROOT       = ../../..

# The target .bit file to be generated including the monitor program
TARGET     = system

# CPU Name, for include paths
CPU_NAME   = opc5ls

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH   = opc5ls

# CPU File Path, relative to the root directory
CPU_PATH   = opc5ls/opc5lscpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc5ls/opc5lsasm.py

# Program Source Path, relative to the root directory
PROG_SRC   = system/firmware/monitor.s

# Extract a smaller ROM
ROMSTART   = F000
ROMLEN     = 1000

# User Memory
MEM_BOT   ?= 0100
MEM_TOP   ?= EFFF
STACK     ?= EFFF

# Verilog sources
SRCS       = ../system.v  ../ram_4k_16.v $(ROOT)/$(CPU_PATH) ../../src/uart.v

# Common include files
include $(ROOT)/common/Makefile_ice40.inc
