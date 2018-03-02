# Common BCPL and simulation makefile rules

pyexec ?= python3

OPT ?= -o


ALLSRCS    ?= $(wildcard *.b)
TESTSRCS   ?= $(shell ls -1 *b | egrep -v '(bcpllib|beeb|empty|mandset)'  )
SIALS      ?= $(patsubst %.b,%.sial,$(TESTSRCS))
ASMS       ?= $(patsubst %.b,%.s,$(TESTSRCS))
HEXS       ?= $(patsubst %.b,%.hex,$(TESTSRCS))
BCPLEXECS  ?= $(patsubst %.b,%,$(TESTSRCS))
EMUSTDOUTS ?= $(patsubst %.b,%.emu.stdout,$(TESTSRCS))

SIMSRCS     ?= $(shell ls -1 *.b | egrep -v '(bcpllib|beeb|enigma|empty|mandset)'  )
SIMS        ?= $(patsubst %.b,%.sim,${SIMSRCS})
SIMSTDOUTS  ?= $(patsubst %.b,%.sim.stdout,${SIMSRCS})
DIFFS       ?= $(patsubst %.b,%.diff,${SIMSRCS})
EXES        ?= $(patsubst %.b,%_tb.exe,${SIMSRCS})


##.NOTPARALLEL : all_sim *.exe all_

%.sial : %.b
	cintsys -c bcpl $*.b to $*
	cintsys -c bcpl2sial $*.b to $*.sial

bcpllib.sial : bcpllib.b
	cintsys -c bcpl2sial ../../bcpl/bcpllib.b to bcpllib.sial


%.s : %.sial ${ARCH}_rom.s ext_sial.h ${ARCH}_syslib.s bcpllib.sial ../../bcpl/sial2opc.py ../../include/${ARCH}/macros.s
	python3 ../../bcpl/sial2opc.py --${ARCH} -f $*.sial -f bcpllib.sial -s ../../bcpl/${ARCH}_syslib.s -g ../../bcpl/ext_sial.h ${OPT}  > $*.tmp.s
	cat ../../include/${ARCH}/macros.s $*.tmp.s ../../bcpl/${ARCH}_rom.s > $*.s
	rm $*.tmp.s

%.hex %.lst : %.s ${assembler}
	${pyexec} ${assembler} $*.s $*.hex  > $*.lst

%.emu.stdout %.dump : %.hex ${emulator}
	if [ -e $*.stdin ] ; then ${pyexec} ${emulator} $*.hex $*.dump $*.stdin | grep OUT | ../../utils/show_stdout.py --${ARCH} | tee $*.emu.stdout ; \
	else ${pyexec} ${emulator} $*.hex $*.dump  | grep OUT | ../../utils/show_stdout.py --${ARCH}| tee $*.emu.stdout ; fi

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout | tee $*.diff

%.sim : %.hex %.exe
	./$*.exe > $@

%.exe : ../${ARCH}tb.v ../${ARCH}cpu.v
	perl -pale 's/test\.(hex|dump|vcd)/$*\.\1/g' ../${ARCH}tb.v > $*_tb.v
	iverilog -D_simulation=1 ${vcd_option} -o $@ $*_tb.v ../${ARCH}cpu.v
	rm -f $*_tb.v

# -D_dumpvcd=1        

%.sim.stdout : %.sim
	${pyexec} ../../utils/show_stdout.py --${ARCH} -f $*.sim >  $*.sim.stdout


all: all_sial all_asm all_emulation all_sim all_stdout all_diff

all_sial: ${ALLSRCS} ${SIALS} bcpllib.b 

all_asm:  ${SIALS} ${ASMS} bcpllib.sial

all_emulation: ${HEXS} ${EMUSTDOUTS}

all_sim: ../${ARCH}cpu.v ../${ARCH}tb.v ${EXES}


all_diff: ${SIMSTDOUTS}  ${EMUSTDOUTS} ${DIFFS}


all_stdout: ${SIMS} ${SIMSTDOUTS} ${EMUSTDOUTS} 


clean: 
	rm -rf *dump* *trace* *~ *diff *vcd* *sasm* a.out *lst ${BCPLEXECS} *_tb.v ${ASMS} ${HEXS} ${SIALS} ${SIMS} ${SIMSTDOUTS} ${EMUSTDOUTS}
