# Paths that will need changing

PAPILIO_LOADER=/opt/GadgetFactory/papilio-loader/programmer
XILINX=/opt/Xilinx/14.7
DATA2MEM=${XILINX}/ISE_DS/ISE/bin/lin/data2mem
IMPACT=${XILINX}/ISE_DS/ISE/bin/lin/impact

# Shouldn't need to make changes below this point

BIT_FILE=working/opc5copro.bit
BMM_FILE=opc5copro_bd.bmm

build: opc5copro.bit

deploy: opc5copro.bit
	$(IMPACT) -batch deploy.batch

program: opc5copro.bit
	$(IMPACT) -batch program.batch

opc5copro.bit: tuberom.mem $(BIT_FILE)
	$(DATA2MEM) -bm $(BMM_FILE) -bd tuberom.mem -bt $(BIT_FILE) -o b opc5copro.bit

.phony: clean

clean:
	rm -f opc5copro.bit
	rm -f opc5copro.cfi opc5copro.mcs opc5copro.prm
