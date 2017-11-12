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
EMUSTDOUTS = $(patsubst %.b,%.emu.stdout,$(TESTSRCS))

SIMSRCS = $(shell ls -1 *.b | egrep -v '(bcpllib|beeb|enigma)'  )
SIMS = $(patsubst %.b,%.sim,${SIMSRCS})
SIMSTDOUTS = $(patsubst %.b,%.sim.stdout,${SIMSRCS})
DIFFS = $(patsubst %.b,%.diff,${SIMSRCS})
EXES = $(patsubst %.b,%_tb.exe,${SIMSRCS})

##.NOTPARALLEL : all_sim *.exe all_

%.sial : %.b
	cintsys -c bcpl $*.b to $*
	cintsys -c bcpl2sial $*.b to $*.sial


%.s : %.sial rom.s ext_sial.h syslib.s bcpllib.sial ../../utils/sial2opc.py
	python3 ../../utils/sial2opc.py --opc6 -f $*.sial -f bcpllib.sial -s syslib.s -g ext_sial.h ${OPT}  > $*.tmp.s
	cat $*.tmp.s rom.s > $*.s
	rm $*.tmp.s


%.hex %.lst : %.s ../opc6byteasm.py
	${pyexec} ../opc6byteasm.py $*.s $*.hex  > $*.lst

%.emu.stdout %.dump : %.hex ../opc6emu.py
	if [ -e $*.stdin ] ; then ${pyexec} ../opc6emu.py $*.hex $*.dump $*.stdin | grep OUT | ../../utils/show_stdout.py | tee $*.emu.stdout ; \
	else ${pyexec} ../opc6emu.py $*.hex $*.dump  | grep OUT | ../../utils/show_stdout.py | tee $*.emu.stdout ; fi

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout | tee $*.diff

%.sim : %.hex %.exe
	./$*.exe > $@

%.exe : ../opc6tb.v ../opc6cpu.v %_tb.v
	perl -pale 's/test\.(hex|dump|vcd)/$*\.\1/g' ../opc6tb.v > $*_tb.v
	iverilog -D_simulation=1 ${vcd_option} -o $@ $*_tb.v ../opc6cpu.v 

%.sim.stdout : %.sim
	${pyexec} ../../utils/show_stdout.py -6 -f $*.sim >  $*.sim.stdout

# -D_dumpvcd=1        

all: all_sial all_asm all_emulation all_sim all_stdout all_diff

all_sial: ${ALLSRCS}


all_asm:  ${SIALS} ${ASMS}


all_emulation: ${HEXS} ${EMUSTDOUTS}

all_sim: ../opc6cpu.v ../opc6tb.v ${EXES}


all_diff: ${SIMSTDOUTS}  ${EMUSTDOUTS} 


all_stdout: ${SIMS} ${SIMSTDOUTS} ${EMUSTDOUTS} 


clean: 
	rm -rf *dump* *trace* *~ *diff *vcd* *sasm* a.out *lst ${BCPLEXECS} *_tb.v ${ASMS} ${HEXS} ${SIALS} ${SIMS} ${SIMSTDOUTS} ${EMUSTDOUTS}
