VPATH=..

SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc7asm.py
emulator ?= ../opc7emu.py
show_stdout ?= ../../utils/show_stdout.py

vcd_option = ""
#-D_dumpvcd=1

.NOTPARALLEL : all_sim *.exe

%.hex %.lst : %.s opc7asm.py
	python3 ${assembler} $< $@ >  $*.lst

%.emu.stdout %.dump : %.hex opc7emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} -7 >  $*.emu.stdout
	gzip -f $*.trace

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout > $@

%.sim : %.hex ../opc7tb.v ../opc7cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 ${vcd_option} ../opc7tb.v ../opc7cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi


%.sim.stdout : %.sim
	python3 ../../utils/show_stdout.py -7 -f $*.sim >  $*.sim.stdout


# -D_dumpvcd=1        

all: all_emulation all_simulation all_diff

all_simulation: all_stdout all_sim

all_emulation: opc7asm.py opc7emu.py ${DUMPS} ${HEXS}

all_sim: opc7cpu.v opc7tb.v ${SIMS}

all_diff: ${DIFFS}

all_stdout: ${STDOUTS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst
