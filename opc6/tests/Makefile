VPATH=..


SRCS = $(wildcard *.s)

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc6asm.py
emulator ?= ../opc6emu.py
show_stdout ?= ../../utils/show_stdout.py

vcd_option = ""
#-D_dumpvcd=1

.NOTPARALLEL : all_sim *.exe

%.hex %.lst : %.s opc6asm.py
	python3 ${assembler} $< $@ >  $*.lst

%.emu.stdout %.dump : %.hex opc6emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} >  $*.emu.stdout

%.sim : %.hex ../opc6tb.v ../opc6cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 ${vcd_option} ../opc6tb.v ../opc6cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi

# -D_dumpvcd=1        

all: all_emulation all_simulation all_diff

all_simulation: all_stdout all_sim

all_emulation: opc6asm.py opc6emu.py ${DUMPS} ${HEXS}

all_sim: opc6cpu.v opc6tb.v ${SIMS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst
