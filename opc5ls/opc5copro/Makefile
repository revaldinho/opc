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

tuberom.hex: tuberom.s
	python ../opc5lsasm.py tuberom.s tuberom.hex

# This is for use in the FPGA
tuberom.mem: tuberom.hex
	tr " " "\n" < tuberom.hex | tail -8192 > tuberom.mem

# This is for use in PiTubeDirect
tuberom.c: tuberom.hex
	echo '#include "tuberom.h"' > tuberom.c
	echo 'uint16_t tuberom_opc5ls[0x800] = {' >> tuberom.c
	tr " " "\n" < tuberom.hex | tail -2048 | awk '{print "0x" $$1 ","}' >> tuberom.c
	echo '};' >> tuberom.c

.phony: clean

clean:
	rm -f opc5copro.bit
	rm -f opc5copro.cfi opc5copro.mcs opc5copro.prm
	rm -f tuberom.mem tuberom.hex tuberom.c
