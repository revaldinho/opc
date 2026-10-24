# Common BCPL and simulation makefile rules

pyexec ?= python3

OPT ?= -o

# OPC7 hex files are written sparse (only non-zero blocks, in $readmemh '@addr'
# format), which opc7emu.py and opc7tb.v read; other CPUs keep the full format
ASMFLAGS ?= $(if $(filter opc7,$(ARCH)),-g sparse)

# The emulator runs under pypy3 when it is installed (several times faster than
# python3), with the per-instruction trace switched off by -q. To debug, run
# with the full trace saved in <prog>.trace, eg
#   make TRACE=1 fact.emu.stdout
# or override EMUFLAGS and/or emuexec directly.
emuexec ?= $(if $(shell command -v pypy3 2>/dev/null),PYPY_GC_NURSERY=4M pypy3,python3)

ifdef cemulator
EMULATORRUN = ${cemulator}
else
EMULATORRUN = ${emuexec} ${emulator}
endif

ifdef TRACE
EMUFLAGS ?=
EMUTRACE  = tee $*.trace |
else
EMUFLAGS ?= -q
EMUTRACE  =
endif

# The OPC7 emulator only writes its memory dump with DUMP=1, eg
#   make DUMP=1 fact.emu.stdout
# as <prog>.emu.dump so it doesn't clash with the <prog>.dump written by the
# Verilog testbench; other CPUs' emulators always write <prog>.dump
EMUDUMP = $(if $(filter opc7,$(ARCH)),$(if $(DUMP),$*.emu.dump,-),$*.dump)


ALLSRCS    ?= $(wildcard *.b)
TESTSRCS   ?= $(shell ls -1 *b | egrep -v '(bcpllib|beeb|empty|mandset|sphere)'  )
SIALS      ?= $(patsubst %.b,%.sial,$(TESTSRCS))
ASMS       ?= $(patsubst %.b,%.s,$(TESTSRCS))
HEXS       ?= $(patsubst %.b,%.hex,$(TESTSRCS))
BCPLEXECS  ?= $(patsubst %.b,%,$(TESTSRCS))
EMUSTDOUTS ?= $(patsubst %.b,%.emu.stdout,$(TESTSRCS))

SIMSRCS     ?= $(shell ls -1 *.b | egrep -v '(bcpllib|beeb|enigma|empty|mandset|sphere)'  )
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
	${pyexec} ${assembler} ${ASMFLAGS} $*.s $*.hex  > $*.lst

%.emu.stdout : %.hex ${emulator}
	if [ -e $*.stdin ] ; then ${EMULATORRUN} ${EMUFLAGS} $*.hex ${EMUDUMP} $*.stdin | ${EMUTRACE} grep OUT | ../../utils/show_stdout.py --${ARCH} | tee $*.emu.stdout ; \
	else ${EMULATORRUN} ${EMUFLAGS} $*.hex ${EMUDUMP}  | ${EMUTRACE} grep OUT | ../../utils/show_stdout.py --${ARCH}| tee $*.emu.stdout ; fi

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout | tee $*.diff

%.sim : %.hex %.exe
	./$*.exe > $@

# Optional: compare the final memory of the emulator (<prog>.emu.dump) with
# the Verilog testbench's (<prog>.dump, written by the simulation), eg
#   make fact.dumpdiff
%.dumpdiff: %.sim %.hex ${emulator}
	${EMULATORRUN} -q $*.hex $*.emu.dump $(wildcard $*.stdin) > /dev/null
	${pyexec} ../../utils/cmp_dump.py -x $*.emu.dump $*.dump > $@ ; st=$$? ; cat $@ ; exit $$st

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
	rm -rf *dump* *trace* *~ *diff *vcd* *sasm* a.out *lst ${BCPLEXECS} *_tb.v ${ASMS} ${HEXS} ${SIALS} ${SIMS} ${SIMSTDOUTS} ${EMUSTDOUTS} *exe *.sim
