VPATH=..

SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
EXES  = $(patsubst %.s,%.exe,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc7asm.py
emulator ?= ../opc7emu.py
show_stdout ?= ../../utils/show_stdout.py

vcd_option = 
#-D_dumpvcd=1

%.hex %.lst : %.s opc7asm.py
	python3 ${assembler} $< $@ >  $*.lst

%.emu.stdout %.dump : %.hex opc7emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} -7 >  $*.emu.stdout
	gzip -f $*.trace

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout > $@

%.sim : %.hex %.exe
	./$*.exe > $@

%.exe : ../opc7tb.v ../opc7cpu.v
	perl -pale 's/test\.(hex|dump|vcd)/$*\.\1/g' ../opc7tb.v > $*_tb.v
	iverilog -D_simulation=1 ${vcd_option} -o $@ $*_tb.v ../opc7cpu.v 
	rm -f $*_tb.v

%.sim.stdout : %.sim
	python3 ../../utils/show_stdout.py -7 -f $*.sim >  $*.sim.stdout


# -D_dumpvcd=1        

all: all_emulation all_simulation all_diff

all_exe: ${EXES}

all_simulation: all_stdout all_sim all_exe

all_emulation: opc7asm.py opc7emu.py ${DUMPS} ${HEXS}

all_sim: opc7cpu.v opc7tb.v ${SIMS}

all_diff: ${DIFFS}

all_stdout: ${STDOUTS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst
