# Paths that will need changing

PAPILIO_LOADER=/opt/GadgetFactory/papilio-loader/programmer
XILINX=/opt/Xilinx/14.7
DATA2MEM=${XILINX}/ISE_DS/ISE/bin/lin/data2mem
IMPACT=${XILINX}/ISE_DS/ISE/bin/lin/impact

# Shouldn't need to make changes below this point

BIT_FILE=working/CoProOpc5ls.bit
BMM_FILE=CoProOpc5ls_bd.bmm

build: CoProOpc5ls.bit

deploy: CoProOpc5ls.bit
	$(IMPACT) -batch deploy.batch

program: CoProOpc5ls.bit
	$(IMPACT) -batch program.batch

CoProOpc5ls.bit: tuberom.mem $(BIT_FILE)
	$(DATA2MEM) -bm $(BMM_FILE) -bd tuberom.mem -bt $(BIT_FILE) -o b CoProOpc5ls.bit

.phony: clean

clean:
	rm -f CoProOpc5ls.bit
	rm -f CoProOpc5ls.cfi CoProOpc5ls.mcs CoProOpc5ls.prm
