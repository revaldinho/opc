COMMON      ?= $(ROOT)/common

XILINX      ?= /opt/Xilinx/14.7
PAPILIO     ?= /opt/GadgetFactory/papilio-loader/programmer

#ifeq ( $(shell uname -m), x86_64 )
LD_PRELOAD := $(PWD)/$(COMMON)/libusb-driver.so
PATH       := $(PATH):${XILINX}/ISE_DS/ISE/bin/lin64:${PAPILIO}/linux64
SHELL      := env LD_PRELOAD=$(LD_PRELOAD) PATH=$(PATH) /bin/bash
#else
#PATH       := $(PATH):${XILINX}/ISE_DS/ISE/bin/lin:${PAPILIO}/linux32
#SHELL      := env PATH=$(PATH) /bin/bash
#endif

# Path of the back anotated block memory map file
BMM_FILE    ?= memory_bd.bmm

build: $(TARGET).bit

include $(COMMON)/Makefile_prog.inc

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

clean:
	rm -f deploy.batch program.batch tmp.xise
	rm -f $(PROG).s $(PROG).hex $(PROG).mem $(PROG).lst $(PROG).c
	rm -f $(TARGET).bit $(TARGET).cfi $(TARGET).mcs $(TARGET).prm
	rm -f _impactbatch.log

clobber: clean
	rm -rf $(BMM_FILE) working/
