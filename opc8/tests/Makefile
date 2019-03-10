VPATH=..

SRCS   ?= $(shell ls -1 *s | egrep -v '(macro|tmp|printdec)'  )

HEXS  = $(patsubst %.s,%.hex,$(SRCS))
DUMPS = $(patsubst %.s,%.dump.gz,$(SRCS))
DIFFS = $(patsubst %.s,%.diff,$(SRCS))
SIMS  = $(patsubst %.s,%.sim,$(SRCS))
STDOUTS  = $(patsubst %.s,%.sim.stdout,$(SRCS))

pyexec ?= python3
assembler ?= ../opc8asm.py
emulator ?= ../opc8emu.py
show_stdout ?= ../../utils/show_stdout.py

vcd_option = ""
#-D_dumpvcd=1

.NOTPARALLEL : ${SIMS} *.exe

%.hex %.lst : %.s macro.s opc8asm.py
	cat macro.s $<  > $*.tmp.s
	${pyexec} ${assembler} $*.tmp.s $@ >  $*.lst
	rm $*.tmp.s

%.emu.stdout %.dump.gz : %.hex opc8emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} >  $*.emu.stdout
	gzip -f $*.dump $*.trace	

%.sim : %.hex ../opc8tb.v ../opc8cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 ${vcd_option} ../opc8tb.v ../opc8cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi

%.hist.txt: all_emulation
	rm -rf all_listings.lst.gz all_traces.trace.gz
	cat *.lst | gzip -c > all_listings.lst.gz
	gunzip -c *.trace.gz | gzip -c > all_traces.trace.gz
	${pyexec} ../../utils/histogram.py -f all_listings.lst.gz -s -w 24 >  static.hist.txt
	${pyexec} ../../utils/histogram.py -f all_traces.trace.gz -d -w 24 >  dynamic.hist.txt

# -D_dumpvcd=1        

histogram: histogramsdynamic_histogram.txt static_histogram.txt all_emulation

all: all_emulation all_stats all_simulation all_diff

all_simulation: all_stdout all_sim

all_emulation: opc8asm.py opc8emu.py ${DUMPS} ${HEXS}

all_sim: opc8cpu.v opc8tb.v ${SIMS}

all_stats: static.hist.txt  dynamic.hist.txt

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd* a.out *lst *gz
