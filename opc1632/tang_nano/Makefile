BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5

VPATH=..

all: opc1632cpu.fs

# Synthesis
opc1632cpu_synth.json: opc1632cpu.v
	yosys -s compile.scr

# Place and Route
opc1632cpu_pnr.json: opc1632cpu_synth.json
	nextpnr-gowin --json opc1632cpu_synth.json --write opc1632cpu_pnr.json --freq 45 --device ${DEVICE} --family ${FAMILY}

# Generate Bitstream
opc1632cpu.fs: opc1632cpu_pnr.json
	gowin_pack -d ${FAMILY} -o opc1632cpu.fs opc1632cpu_pnr.json

clean:
	rm -f *json *.fs *~
