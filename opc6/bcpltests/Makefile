../VPATH=..

pyexec ?= python3
assembler ?= ../opc6asm.py
emulator ?= ../opc6emu.py
show_stdout ?= ../../utils/show_stdout.py
OPT ?= -o

ALLSRCS = $(wildcard *.b)
TESTSRCS = $(shell ls -1 *b | egrep -v '(bcpllib|beeb)'  )
SIALS  = $(patsubst %.b,%.sial,$(ALLSRCS))
ASMS  = $(patsubst %.b,%.s,$(TESTSRCS))
HEXS  = $(patsubst %.b,%.hex,$(TESTSRCS))
BCPLEXECS = $(patsubst %.b,%,$(TESTSRCS))
STDOUTS = $(patsubst %.b,%.emu.stdout,$(TESTSRCS))

##.NOTPARALLEL : all_sim *.exe all_

%.sial : %.b
	cintsys -c bcpl $*.b to $*
	cintsys -c bcpl2sial $*.b to $*.sial

%.s : %.sial rom.s ext_sial.h syslib.s bcpllib.sial ../sial2opc6.py
	python3 ../sial2opc6.py -f $*.sial -f bcpllib.sial -s syslib.s -g ext_sial.h ${OPT} > $*.tmp.s
	cat $*.tmp.s rom.s > $*.s
	rm $*.tmp.s

%.hex %.lst : %.s ../opc6byteasm.py
	${pyexec} ../opc6byteasm.py $*.s $*.hex  > $*.lst

%.emu.stdout %.dump : %.hex ../opc6emu.py
	if [ -e $*.stdin ] ; then ${pyexec} ../opc6emu.py $*.hex $*.dump $*.stdin | grep OUT | ../../utils/show_stdout.py | tee $*.emu.stdout ; \
	else ${pyexec} ../opc6emu.py $*.hex $*.dump  | grep OUT | ../../utils/show_stdout.py | tee $*.emu.stdout ; fi

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout

%.sim : %.hex ../opc6tb.v ../opc6cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 ${vcd_option} ../opc6tb.v ../opc6cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi

%.sim.stdout : %.sim
	python3 ../../utils/show_stdout.py -6 -f $*.sim >  $*.sim.stdout


# -D_dumpvcd=1        

all: all_asm

all_sial: ${SIALS}

all_asm: ${ASMS}

all_emulation: ${HEXS} ${STDOUTS}

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst *sial ${BCPLEXECS}
