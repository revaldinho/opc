# Default region to extract from the assembler output into the ROM
ROMSTART    ?= C000
ROMLEN      ?= 4000
ROMWIDTH    ?= 2

INC_FLAGS   ?= -I $(ROOT)/include/$(CPU_NAME) -I $(ROOT)/include

# Default name of assembler program
PROG        ?= $(basename $(notdir $(PROG_SRC)))

$(PROG).hex: $(ROOT)/$(PROG_SRC)
	# run the pre-processor to resolve and ##includes
	filepp $(INC_FLAGS) -D_BASE_=0x$(ROMSTART) -D_MEM_BOT_=0x$(MEM_BOT) -D_MEM_TOP_=0x$(MEM_TOP) -D_STACK_=0x$(STACK) -kc '##' $(ROOT)/$(PROG_SRC) > $(PROG).s.tmp
	mv $(PROG).s.tmp $(PROG).s
	# run the assember
	python $(ROOT)/$(ASM_PATH) $(PROG).s $(PROG).hex | tee ${PROG}.lst
	# clean up
	rm -f $(PROG).s

# This is for use in the FPGA
$(PROG).mem: $(PROG).hex
	xxd -r -p < $(PROG).hex | dd ibs=$(ROMWIDTH) skip=$$((16#$(ROMSTART))) count=$$((16#$(ROMLEN))) | xxd -p -c$(ROMWIDTH) > $(PROG).mem.tmp
	mv $(PROG).mem.tmp $(PROG).mem

# This is for use in PiTubeDirect (this is specific to copro)


$(PROG).c: $(PROG).hex
	echo '#include "$(PROG).h"' > $(PROG).c.tmp
ifeq ($(CPU_NAME), opc7)
	echo 'uint32_t $(PROG)_$(CPU_NAME)[0x800] = {' >> $(PROG).c.tmp
	xxd -r -p < $(PROG).hex | dd ibs=$(ROMWIDTH) count=$$((16#0800)) | xxd -p -c$(ROMWIDTH) | awk '{print "0x" $$1 ","}' >> $(PROG).c.tmp
else ifeq ($(CPU_NAME), opc6)
	echo 'uint16_t $(PROG)_$(CPU_NAME)[0x800] = {' >> $(PROG).c.tmp
	xxd -r -p < $(PROG).hex | dd ibs=$(ROMWIDTH) skip=$$((16#F800)) count=$$((16#0800)) | xxd -p -c$(ROMWIDTH) | awk '{print "0x" $$1 ","}' >> $(PROG).c.tmp
else
	echo 'uint16_t $(PROG)_$(CPU_NAME)[0x1000] = {' >> $(PROG).c.tmp
	xxd -r -p < $(PROG).hex | dd ibs=$(ROMWIDTH) skip=$$((16#F000)) count=$$((16#1000)) | xxd -p -c$(ROMWIDTH) | awk '{print "0x" $$1 ","}' >> $(PROG).c.tmp
endif
	echo '};' >> $(PROG).c.tmp
	mv $(PROG).c.tmp $(PROG).c
