VPATH=..

SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
EXES  = $(patsubst %.s,%.exe,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
DYNSTATS  = $(patsubst %.s,%.dynstats,$(SRCS))
STASTATS  = $(patsubst %.s,%.stastats,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc7asm.py
emulator ?= ../opc7emu.py
show_stdout ?= ../../utils/show_stdout.py
histogram ?= ../../utils/histogram.py

vcd_option =
#vcd_option = -DPRED_IN_EAD_ONLY=1
#-D_dumpvcd=1

%.hex %.lst : %.s opc7asm.py
	python3 ${assembler} $< $*.hex >  $*.lst

%.emu.stdout %.dump : %.hex opc7emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} -7 >  $*.emu.stdout
	gzip -f $*.trace

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout > $@

%.sim : %.hex %.exe
	./$*.exe > $@

%.dynstats : %.trace.gz
	${pyexec} ${histogram} -d -f ./$*.trace.gz -w 32 > $@

%.stastats : %.lst
	${pyexec} ${histogram} -s -f ./$*.lst -w 32 > $@

%.exe : ../opc7tb.v ../opc7cpu.v
	perl -pale 's/test\.(hex|dump|vcd)/$*\.\1/g' ../opc7tb.v > $*_tb.v
	iverilog -D_simulation=1 ${vcd_option} -o $@ $*_tb.v ../opc7cpu.v 
	rm -f $*_tb.v

%.sim.stdout : %.sim
	${pyexec} ../../utils/show_stdout.py -7 -f $*.sim >  $*.sim.stdout


# -D_dumpvcd=1        

all: all_diff all_stats  all_emulation all_simulation all_exe all_sim 

all_exe: ${EXES}

all_simulation: all_stdout all_sim all_exe

all_emulation: opc7asm.py opc7emu.py ${DUMPS} ${HEXS}

all_sim: opc7cpu.v opc7tb.v ${SIMS}

all_diff: ${DIFFS}

all_stdout: ${STDOUTS}

all_stats: ${DYNSTATS} ${STASTATS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst *stats
