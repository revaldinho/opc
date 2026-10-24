VPATH=..

SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
EXES  = $(patsubst %.s,%.exe,$(SRCS))
EMUSTDOUTS = $(patsubst %.s,%.emu.stdout,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
DUMPDIFFS = $(patsubst %.s,%.dumpdiff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
DYNSTATS  = $(patsubst %.s,%.dynstats,$(SRCS))
STASTATS  = $(patsubst %.s,%.stastats,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))


pyexec ?= python3
assembler ?= ../opc7asm.py
emulator ?= ../opc7emu.py
show_stdout ?= ../../utils/show_stdout.py
histogram ?= ../../utils/histogram.py

# use    DUMP =1
# for more debugging options (Trace is needed for dynamic and static stats generation)
EMUFLAGS ?=
EMUTRACE  = tee $*.trace |
EMUDUMP = $(if $(filter opc7,$(ARCH)),$(if $(DUMP),$*.emu.dump,-),$*.dump)


vcd_option =
#vcd_option = -DPRED_IN_EAD_ONLY=1
#-D_dumpvcd=1

# -g sparse: only the non-zero blocks of memory, in $readmemh '@addr' format
%.hex %.lst : %.s opc7asm.py
	python3 ${assembler} -g sparse $< $*.hex >  $*.lst

# The emulator's memory dump is only written with DUMP=1, eg 'make DUMP=1 fib.emu.stdout',
# as <prog>.emu.dump so it doesn't clash with the <prog>.dump the Verilog testbench writes
EMUDUMP = $(if $(DUMP),$*.emu.dump,-)

%.emu.stdout %.trace.gz : %.hex opc7emu.py
	${pyexec} ${emulator} ${EMUFLAGS} $< $(EMUDUMP) | ${EMUTRACE} grep OUT | ${pyexec} ${show_stdout} -7 >  $*.emu.stdout
	gzip -f $*.trace


%.diff: %.sim.stdout %.emu.stdout
	diff -a -s $*.emu.stdout $*.sim.stdout > $@

# Optional: compare the final memory of the emulator (<prog>.emu.dump) with
# the Verilog testbench's (<prog>.dump, written by the simulation), eg
#   make fib.dumpdiff      or      make all_dumpdiff
%.dumpdiff: %.sim %.hex opc7emu.py
	${pyexec} ${emulator} -q $*.hex $*.emu.dump > /dev/null
	${pyexec} ../../utils/cmp_dump.py -x $*.emu.dump $*.dump > $@ ; st=$$? ; cat $@ ; exit $$st

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

all: all_diff all_stats all_emulation all_simulation all_exe all_sim 

all_exe: ${EXES}

all_simulation: all_stdout all_sim all_exe

all_emulation: opc7asm.py opc7emu.py ${EMUSTDOUTS} ${HEXS}

all_sim: opc7cpu.v opc7tb.v ${SIMS}

all_diff: ${DIFFS}

all_dumpdiff: ${DUMPDIFFS}

all_stdout: ${STDOUTS}

all_stats: ${DYNSTATS} ${STASTATS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst *stats
