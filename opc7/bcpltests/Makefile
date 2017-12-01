VPATH=..:../../bcpl

ROOT= ../..

# Default to using sial2opc optimizations
#OPT ?= -o
ARCH ?= opc7
assembler ?= ../${ARCH}asm.py
emulator ?= ../${ARCH}emu.py

# include common BCPL routines for different CPUs
include $(ROOT)/bcpl/Makefile_bcpl.inc

