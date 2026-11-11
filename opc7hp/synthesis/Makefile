# opc7hp/synthesis: FPGA resource and clock frequency figures for the OPC7 CPUs, with the open
# source flow (yosys, nextpnr). One directory per board holds its pin constraints, its system top
# level and its results.txt:
#   tangnano20k/  Tang Nano 20K, Gowin GW2AR-LV18QN88C8/I7: synth_gowin, nextpnr-himbaechel
#   ulx3s/        ULX3S, Lattice ECP5 LFE5U-85F-6BG381C: synth_ecp5, nextpnr-ecp5
#
#   make [BOARD=tangnano20k|ulx3s] [CPU=opc7|opc7h|opc7hp]
#                   synthesise CPU in its test top (tops/top_<cpu>.v: 4K words of block RAM and
#                   only the LEDs on pins), place and route it with each of SEEDS, and append a
#                   line to <board>/results.txt (min/median/max Fmax over the seeds)
#     CPU=opc7      the original OPC7 (../../opc7/opc7cpu.v)
#     CPU=opc7h     the reference Harvard OPC7, one instruction at a time (../cpu/opc7hcpu.v)
#     CPU=opc7hp    the pipelined OPC7 (../cpu/opc7hpcpu.v), the default
#   make SYNTHOPTS=-nowidelut ...   extra synthesis options (the build files get them in their
#                   names and the results note starts with them). On the Gowin, the default
#                   wide-LUT mapping moves a lot with small source changes; -nowidelut is stable
#                   and, for opc7hpcpu, both smaller and faster.
#   make SEEDS="1 2 ... 15" ...     more seeds: a few percent between designs needs 15
#   make NOTE="..." ...             the note at the end of the results line
#   make clean
#
# fmax_sweep.sh runs a seed sweep of one CPU file without a results line, and
# <board>/build_sys.sh builds a bitstream of the whole OPC7 system (../system) for a program.
# Fmax figures are nextpnr estimates, for comparing designs: the two toolchains' timing models
# differ, and the vendor tools would give other numbers.

BOARD ?= tangnano20k
CPU   ?= opc7hp
SEEDS ?= 1 2 3
NOTE  ?=
SYNTHOPTS ?=

SRCS_opc7   = ../../opc7/opc7cpu.v
SRCS_opc7h  = ../cpu/opc7hcpu.v
SRCS_opc7hp = ../cpu/opc7hpcpu.v
SRCS = tops/top_$(CPU).v $(SRCS_$(CPU))
B    = build/$(BOARD)/$(CPU)$(subst $(eval) ,,$(SYNTHOPTS))
RESULTS = $(BOARD)/results.txt

ifeq ($(BOARD),ulx3s)
  ECP5 = --85k --package CABGA381 --speed 6
  PINS = ulx3s/ulx3s.lpf
  FREQ = 25
else ifeq ($(BOARD),tangnano20k)
  DEVICE = GW2AR-LV18QN88C8/I7
  FAMILY = GW2A-18C
  PINS   = tangnano20k/tangnano20k.cst
  FREQ   = 27
else
  $(error BOARD must be tangnano20k or ulx3s)
endif

.PHONY: stats clean
.DEFAULT_GOAL := stats

build/$(BOARD):
	mkdir -p $@

ifeq ($(BOARD),ulx3s)
$(B).json: $(SRCS) | build/$(BOARD)
	yosys -q -l $(B).synth.log -p "read_verilog $(SRCS); synth_ecp5 $(SYNTHOPTS) -top top -json $@" > /dev/null

$(B).seed%.log: $(B).json $(PINS)
	nextpnr-ecp5 --json $< $(ECP5) --lpf $(PINS) --freq $(FREQ) --seed $* > $@ 2>&1 || (tail $@; false)
else
$(B).json: $(SRCS) | build/$(BOARD)
	yosys -q -l $(B).synth.log -p "read_verilog $(SRCS); synth_gowin -family gw2a $(SYNTHOPTS) -top top -json $@" > /dev/null

$(B).seed%.log: $(B).json $(PINS)
	nextpnr-himbaechel --json $< --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(PINS) \
	  --freq $(FREQ) --seed $* --write $(B).seed$*.pnr.json > $@ 2>&1 || (tail $@; false)
endif

stats: $(foreach s,$(SEEDS),$(B).seed$(s).log)
	python3 hwstats.py --cpu $(CPU) --synthlog $(B).synth.log --results $(RESULTS) --note "$(if $(SYNTHOPTS),[$(SYNTHOPTS)] )$(NOTE)" $(SRCS_$(CPU)) -- $^ | tee -a $(RESULTS)

clean:
	rm -rf build
