# The root directory of the project
ROOT       = ../../..
SERIAL     = /dev/cu.usbmodem1A124231

# The target .bit file to be generated including the monitor program
TARGET     = system

# CPU Name, for include paths
CPU_NAME   = opc7

# CPU Architecture, for tweaks in the verilog file
CPU_ARCH   = opc7

# CPU File Path, relative to the root directory
CPU_PATH   = opc7/opc7cpu.v

# Assembler File Path, relative to the root directory
ASM_PATH   = opc7/opc7asm.py

# Program Source Path, relative to the root directory
PROG_SRC   = system/firmware/monitor.s

# Extract a smaller ROM
ROMSTART   = 0000
ROMLEN     = 0E00
ROMWIDTH   = 4

# User Memory
MEM_BOT   ?= 01000
MEM_TOP   ?= FFFFFFFF
STACK     ?= FFFFFFFF

# Verilog sources
SRCS       = ../system_32.v  ../memory_controller_2_wait_states.v ../ram_3584_32.v $(ROOT)/$(CPU_PATH) ../../src/uart.v

# Common include files
include $(ROOT)/common/Makefile_ice40.inc
