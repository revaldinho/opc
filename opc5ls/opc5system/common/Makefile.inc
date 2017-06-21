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

# Path of the back anotated block memory map file
BMM_FILE    = opc5system_bd.bmm

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

$(TARGET).bit: monitor.mem working/$(PROJECT).bit
	data2mem -bm $(BMM_FILE) -bd monitor.mem -bt working/$(PROJECT).bit -o b $(TARGET).bit

monitor.mem : ../../../monitor.s
	python ../../../opc5lsasm.py ../../../monitor.s monitor.hex
	tr " " "\n" <monitor.hex | head -16384 > monitor.mem

clean:
	rm -f deploy.batch program.batch tmp.xise
	rm -f monitor.mem monitor.hex
	rm -f $(TARGET).bit $(TARGET).cfi $(TARGET).mcs $(TARGET).prm
	rm -f _impactbatch.log

clobber: clean
	rm -rf $(BMM_FILE) working/
