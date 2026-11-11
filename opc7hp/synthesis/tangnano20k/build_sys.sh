#!/bin/bash
# build_sys.sh prog [synth options] - Tang Nano 20K bitstream of the OPC7 system running prog (built
# by ../../system/sysrun.sh first, which also checks it in simulation). The image is split for the board's 16K word
# RAM. Work files: build/<prog>/ here. Prints the resources and Fmax, and the bitstream's name.
# Load it with: openFPGALoader -b tangnano20k build/<prog>/tn20k_sys.fs   (or -f to write flash)
p=$1; shift; opts="${*:--nowidelut}"
d=$(cd "$(dirname "$0")" && pwd); sys=$(cd $d/../../system && pwd); cpu=$(cd $d/../../cpu && pwd); w=$d/build/$p
[ -e $sys/build/$p/$p.hex ] || { echo "run ../../system/sysrun.sh $p first"; exit 2; }
mkdir -p $w; cd $w
python3 $sys/sysimg.py $sys/build/$p/$p.hex rom.hex ram.hex 14 || exit 1
yosys -q -l synth.log -p "read_verilog $d/tn20k_sys.v $d/tn20k_pll.v $sys/opc7hsys.v $sys/opc7_uart.v $cpu/opc7hpcpu.v; synth_gowin -family gw2a $opts -top tn20k_sys -json sys.json" > /dev/null || { tail synth.log; exit 1; }
nextpnr-himbaechel --json sys.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst=$d/tn20k_sys.cst \
  --freq 54 --write pnr.json > pnr.log 2>&1 || { tail pnr.log; exit 1; }
grep -E 'Info:\s+(LUT4|ALU|DFF|RAM16SDP4|BSRAM|rPLL|PLL)\b' pnr.log | sed 's/Info://'
grep 'Max frequency' pnr.log | tail -2
/home/parallels/Documents/claude/sial/apycula-venv/bin/gowin_pack -d GW2A-18C -o tn20k_sys.fs pnr.json || exit 1
echo "bitstream: $w/tn20k_sys.fs"
