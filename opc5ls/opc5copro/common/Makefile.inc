COMMON      = ../../common

XILINX      ?= /opt/Xilinx/14.7
PAPILIO     ?= /opt/GadgetFactory/papilio-loader/programmer

PATH       := $(PATH):${XILINX}/ISE_DS/ISE/bin/lin:${PAPILIO}/linux32

ifeq ( $(shell uname -m), i686 )
LD_PRELOAD := "$(LD_PRELOAD):$(PWD)/$(COMMON)/libusb-driver.so"
SHELL      := env LD_PRELOAD=$(LD_PRELOAD) PATH=$(PATH) /bin/sh
else
SHELL      := env PATH=$(PATH) /bin/sh
endif

# Default name of assembler program
PROG         = tuberom

# Path of the back anotated block memory map file
BMM_FILE    = opc5copro_bd.bmm

# Path of the default CPU in the .xise file
DEFAULT_CPU = opc5lscpu.v

# Replacement path of the XP CPU, ssubstituted if "make CPU=xp"
XP_CPU      = ../opc5ls-xp/opc5lscpu.v

build: $(TARGET).bit

working/$(PROJECT).bit:
	# create a working directory if necessary
	mkdir -p working
	# generate a tmp .xise file so we can change if
	cp ../$(TARGET).xise tmp.xise
	# if the CPU param is xp, then substitute the path of the XP CPU
	if [ "$(CPU)" = "xp" ]; then sed "s@$(DEFAULT_CPU)@$(XP_CPU)@g" < ../$(TARGET).xise > tmp.xise; fi
	# use the xilinx tools to synthesise the project and generate a bitstream file
	xtclsh $(COMMON)/ise_build.tcl tmp.xise
	# clean up
	rm -f tmp.xise

$(TARGET).bit: ${PROG}.mem working/$(PROJECT).bit
	data2mem -bm $(BMM_FILE) -bd ${PROG}.mem -bt working/$(PROJECT).bit -o b $(TARGET).bit

${PROG}.hex: ../../${PROG}.s
	python ../../../opc5lsasm.py ../../${PROG}.s ${PROG}.hex

# This is for use in the FPGA
${PROG}.mem: ${PROG}.hex
	tr " " "\n" < ${PROG}.hex | tail -8192 > ${PROG}.mem

# This is for use in PiTubeDirect
${PROG}.c: ${PROG}.hex
	echo '#include "${PROG}.h"' > ${PROG}.c
	echo 'uint16_t ${PROG}_opc5ls[0x800] = {' >> ${PROG}.c
	tr " " "\n" < ${PROG}.hex | tail -2048 | awk '{print "0x" $$1 ","}' >> ${PROG}.c
	echo '};' >> ${PROG}.c

clean:
	rm -f deploy.batch program.batch tmp.xise
	rm -f ${PROG}.hex ${PROG}.mem ${PROG}.c
	rm -f $(TARGET).bit $(TARGET).cfi $(TARGET).mcs $(TARGET).prm
	rm -f _impactbatch.log

clobber: clean
	rm -rf $(BMM_FILE) working/
