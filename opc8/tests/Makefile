VPATH=..

SRCS   ?= $(shell ls -1 *s | egrep -v '(macro|tmp|printdec)'  )

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc8asm.py
emulator ?= ../opc8emu.py
show_stdout ?= ../../utils/show_stdout.py

vcd_option = ""
#-D_dumpvcd=1

.NOTPARALLEL : all_sim *.exe

%.hex %.lst : %.s macro.s opc8asm.py
	cat macro.s $<  > tmp.s
	${pyexec} ${assembler} tmp.s $@ >  $*.lst
	rm tmp.s

%.emu.stdout %.dump : %.hex opc8emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} >  $*.emu.stdout

%.sim : %.hex ../opc8tb.v ../opc8cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 ${vcd_option} ../opc8tb.v ../opc8cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi

# -D_dumpvcd=1        

all: all_emulation all_simulation all_diff

all_simulation: all_stdout all_sim

all_emulation: opc8asm.py opc8emu.py ${DUMPS} ${HEXS}

all_sim: opc8cpu.v opc8tb.v ${SIMS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst
