COMMON      ?= $(ROOT)/common

INC_FLAGS   ?= -I $(ROOT)/include/$(CPU_NAME) -I $(ROOT)/include

XILINX      ?= /opt/Xilinx/14.7
PAPILIO     ?= /opt/GadgetFactory/papilio-loader/programmer

PATH       := $(PATH):${XILINX}/ISE_DS/ISE/bin/lin:${PAPILIO}/linux32
SHELL      := env PATH=$(PATH) /bin/sh

# Default name of assembler program
PROG        ?= $(basename $(notdir $(PROG_SRC)))

# Path of the back anotated block memory map file
BMM_FILE    ?= memory_bd.bmm

build: $(TARGET).bit

working/$(PROJECT).bit:
	# create a working directory if necessary
	mkdir -p working
	# generate a tmp .xise file so we can change if
	cp ../$(TARGET).xise tmp.xise
	# substitute the path of the CPU
	sed -e "s@#CPU_PATH#@$(CPU_PATH)@g" -e "s@#CPU_ARCH#@$(CPU_ARCH)@g" < ../$(TARGET).xise > tmp.xise
	# use the xilinx tools to synthesise the project and generate a bitstream file
	xtclsh $(COMMON)/ise_build.tcl tmp.xise
	# clean up
	rm -f tmp.xise

$(TARGET).bit: $(PROG).mem working/$(PROJECT).bit
	data2mem -bm $(BMM_FILE) -bd $(PROG).mem -bt working/$(PROJECT).bit -o b $(TARGET).bit

$(PROG).hex: $(ROOT)/$(PROG_SRC)
	# run the pre-processor to resolve and ##includes
	filepp $(INC_FLAGS) -kc '##' $(ROOT)/$(PROG_SRC) > $(PROG).s
	# run the assember
	python $(ROOT)/$(ASM_PATH) $(PROG).s $(PROG).hex

# This is for use in the FPGA
$(PROG).mem: $(PROG).hex
	tr " " "\n" < $(PROG).hex | tail -8192 > $(PROG).mem

# This is for use in PiTubeDirect
$(PROG).c: $(PROG).hex
	echo '#include "$(PROG).h"' > $(PROG).c
	echo 'uint16_t $(PROG)[0x800] = {' >> $(PROG).c
	tr " " "\n" < $(PROG).hex | tail -2048 | awk '{print "0x" $$1 ","}' >> $(PROG).c
	echo '};' >> $(PROG).c

clean:
	rm -f deploy.batch program.batch tmp.xise
	rm -f $(PROG).s $(PROG).hex $(PROG).mem $(PROG).c
	rm -f $(TARGET).bit $(TARGET).cfi $(TARGET).mcs $(TARGET).prm
	rm -f _impactbatch.log

clobber: clean
	rm -rf $(BMM_FILE) working/
