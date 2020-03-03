VPATH=..


SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
DYNSTATS  = $(patsubst %.s,%.dynstats,$(SRCS))
STASTATS  = $(patsubst %.s,%.stastats,$(SRCS))
SIMSTDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))
EMUSTDOUTS  = $(patsubst %.s,%.emu.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc6asm.py
emulator ?= ../opc6emu.py
show_stdout ?= ../../utils/show_stdout.py
histogram ?= ../../utils/histogram.py

vcd_option = 
#-D_dumpvcd=1

##.NOTPARALLEL : all_sim *.exe

%.hex %.lst : %.s opc6asm.py
	python3 ${assembler} $< $*.hex >  $*.lst

%.emu.stdout %.dump %.trace.gz : %.hex opc6emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} -6 >  $*.emu.stdout
	gzip -f $*.trace

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout > $@

%.sim : %.hex %.exe
	./$*.exe > $@

%.dynstats : %.trace.gz
	${pyexec} ${histogram} -d -f ./$*.trace.gz -w 16 > $@

%.stastats : %.lst
	${pyexec} ${histogram} -s -f ./$*.lst -w 16 > $@

%.exe : ../opc6tb.v ../opc6cpu.v
	perl -pale 's/test\.(hex|dump|vcd)/$*\.\1/g' ../opc6tb.v > $*_tb.v
	iverilog -D_simulation=1 ${vcd_option} -o $@ $*_tb.v ../opc6cpu.v 
	rm -f $*_tb.v

%.sim.stdout : %.sim
	${pyexec} ../../utils/show_stdout.py -6 -f $*.sim >  $*.sim.stdout

# -D_dumpvcd=1        

all: all_diff all_stats  all_emulation all_simulation all_exe all_sim 

all_exe: ${EXES}

all_simulation: all_stdout all_sim all_exe

all_emulation: opc6asm.py opc6emu.py ${DUMPS} ${HEXS}

all_sim: opc6cpu.v opc6tb.v ${SIMS}

all_diff: ${DIFFS}

all_stdout: ${SIMSTDOUTS} ${EMUSTDOUTS}

all_stats: ${DYNSTATS} ${STASTATS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst *stats
