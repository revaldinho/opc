COMMON      ?= $(ROOT)/common

SHELL       := /bin/bash

build: $(TARGET).bin

include $(COMMON)/Makefile_prog.inc

$(TARGET).blif: $(SRCS)
	icebram -g $$((8*$(ROMWIDTH))) $$((16#$(ROMLEN))) > $(PROG)_syn.mem.tmp
	mv $(PROG)_syn.mem.tmp $(PROG)_syn.mem
	yosys -q -f "verilog -Dcpu_$(CPU_ARCH)" -p "synth_ice40 -top ${TARGET} -abc2 -blif ${TARGET}.blif" ${SRCS}

$(TARGET).txt1: $(TARGET).blif
	arachne-pnr -d 8k -P tq144:4k -p ../blackice.pcf ${TARGET}.blif -o ${TARGET}.txt1
	icetime -d hx8k -P tq144:4k -t ${TARGET}.txt1

$(TARGET).txt2: $(TARGET).txt1 $(PROG).mem
	icebram $(PROG)_syn.mem $(PROG).mem < $(TARGET).txt1 > $(TARGET).txt2.tmp
	mv $(TARGET).txt2.tmp $(TARGET).txt2

$(TARGET).bin: $(TARGET).txt2
	icepack ${TARGET}.txt2 ${TARGET}.bin

.PHONY: upload-mac
upload-mac:
	cat $(SERIAL) > /dev/null 2>&1 &
	stty -f $(SERIAL) raw ;\
	cat ${TARGET}.bin > $(SERIAL) ;\
	ps x | grep "cat $(SERIAL)" | head -1 | \
	       sed -e 's/\([[:digit:]]*\) .*$$/now run "kill \1"/'


clean:
	rm -f $(PROG).s $(PROG).hex $(PROG).mem $(PROG).c

clobber: clean
	rm -f $(TARGET).blif $(TARGET).txt1 $(TARGET).txt2 $(TARGET).bin $(PROG)_syn.mem 
