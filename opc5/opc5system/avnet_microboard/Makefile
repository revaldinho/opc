# Paths that will need changing

PAPILIO_LOADER=/opt/GadgetFactory/papilio-loader/programmer
XILINX=/opt/Xilinx/14.7
DATA2MEM=${XILINX}/ISE_DS/ISE/bin/lin/data2mem
IMPACT=${XILINX}/ISE_DS/ISE/bin/lin/impact

# Shouldn't need to make changes below this point

BIT_FILE=working/opc5wrapper.bit
BMM_FILE=opc5system_bd.bmm

build: opc5system.bit

deploy: opc5system.bit
	$(IMPACT) -batch deploy.batch

program: opc5system.bit
	$(IMPACT) -batch program.batch

opc5system.bit: monitor.mem $(BIT_FILE)
	$(DATA2MEM) -bm $(BMM_FILE) -bd monitor.mem -bt $(BIT_FILE) -o b opc5system.bit

monitor.mem : ../../monitor.s
	python ../../opc5asm.py ../../monitor.s monitor.hex
	tr " " "\n" <monitor.hex | head -2048 > monitor.mem

.phony: clean

clean:
	rm -f opc5system.bit monitor.mem monitor.hex
	rm -f opc5system.cfi opc5system.mcs opc5system.prm
