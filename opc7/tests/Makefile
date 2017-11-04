VPATH=..

pyexec ?= python3
assembler ?= ../opc7asm.py
emulator ?= ../opc7emu.py
show_stdout ?= ../../utils/show_stdout.py

.NOTPARALLEL : all_sim *.exe

%.hex %.lst : %.s opc7asm.py
	python3 ${assembler} $< $@ >  $*.lst

%.emu.stdout %.dump : %.hex opc7emu.py
	${pyexec} ${emulator} $< $*.dump | tee  $*.trace | ${pyexec} ${show_stdout} -7 >  $*.emu.stdout
	gzip $*.trace

%.diff: %.sim.stdout %.emu.stdout 
	diff -a -s $*.emu.stdout $*.sim.stdout

%.sim : %.hex ../opc7tb.v ../opc7cpu.v
	cp $*.hex test.hex
	iverilog -D_simulation=1 -D_dumpvcd=1 ../opc7tb.v ../opc7cpu.v > $*.sim 
	./a.out > $@
	mv test.vdump $*.vdump
	if [ -e dump.vcd ] ; then mv dump.vcd $*.vcd ; fi

%.sim.stdout : %.sim
	python3 ../../utils/show_stdout.py -7 -f $*.sim >  $*.sim.stdout


# -D_dumpvcd=1        

all: all_emulation all_simulation all_diff

all_simulation: all_stdout all_sim

all_emulation: opc7asm.py opc7emu.py bperm.dump  bigsieve.dump  davefib.dump davefib_int.dump e-spigot-rev.dump  fib.dump hello.dump math32.dump  nqueens.dump pi-spigot-rev.dump  robfib.dump sieve.dump

all_diff: bperm.diff  bigsieve.diff  davefib.diff davefib_int.diff e-spigot-rev.diff  fib.diff hello.diff math32.diff  nqueens.diff pi-spigot-rev.diff  robfib.diff sieve.diff

all_sim: opc7cpu.v opc7tb.v bperm.sim  bigsieve.sim  davefib.sim davefib_int.sim e-spigot-rev.sim  fib.sim hello.sim math32.sim  nqueens.sim pi-spigot-rev.sim  robfib.sim sieve.sim

all_stdout: bperm.sim.stdout  bigsieve.sim.stdout  davefib.sim.stdout davefib_int.sim.stdout e-spigot-rev.sim.stdout  fib.sim.stdout hello.sim.stdout math32.sim.stdout  nqueens.sim.stdout pi-spigot-rev.sim.stdout  robfib.sim.stdout sieve.sim.stdout

clean: 
	rm -rf *dump* *sim* *trace* *stdout* *hex *~ *diff *exe *vcd a.out
