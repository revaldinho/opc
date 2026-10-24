VPATH=..:../../bcpl

ROOT= ../..

# Default to using sial2opc optimizations
#OPT ?= -o
ARCH ?= opc7
assembler ?= ../${ARCH}asm.py
emulator ?= ../${ARCH}emu.py
# if cemulator is defined then this will be used in preference to the python
cemulator ?=

TESTSRCS   ?= $(shell ls -1 *b | egrep -v '(bcpllib|beeblib|empty|bombe|sudoku16|sphere)'  )

# include common BCPL routines for different CPUs
include $(ROOT)/bcpl/Makefile_bcpl.inc

