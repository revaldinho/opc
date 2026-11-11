#!/bin/bash
# fmax_sweep.sh label [cpu.v] - Fmax of a CPU over nextpnr seeds, because one build can't compare designs a few
# percent apart, on the Tang Nano 20K. The CPU (default ../cpu/opc7hpcpu.v) is synthesised with tops/top_opc7hp.v under
# each name in NAMES and placed
# with each seed in SEEDS. File names changed the mapping up to stage 4 (cpu_notes.txt, 03/11/2026), but since stage 5
# every name gives the same results, so extra names add no samples: use seeds. SYNTHOPTS=-nowidelut for that mapping,
# TOP=<file> for another top level (default tops/top_opc7hp.v).
# Prints the median, range and raw LUT4 count per name, and the overall median. Work files: build/sweep.<label>.
label=$1
d=$(cd "$(dirname "$0")" && pwd); cpu=${2:-$d/../cpu/opc7hpcpu.v}; src=$(readlink -f "$cpu"); w=$d/build/sweep.$label
NAMES=${NAMES:-aa}; SEEDS=${SEEDS:-1 2 3 4 5 6 7 8 9 10 11 12 13 14 15}; JOBS=${JOBS:-4}; OPTS=${SYNTHOPTS:-}
rm -rf $w; mkdir -p $w; cd $w
for n in $NAMES; do
  cp "$src" ${n}_cpu.v; cp ${TOP:-$d/tops/top_opc7hp.v} ${n}_top.v
  ( yosys -q -l $n.synth.log -p "read_verilog ${n}_top.v ${n}_cpu.v; synth_gowin -family gw2a $OPTS -top top -json $n.json" > /dev/null 2>&1 ) &
done; wait
for n in $NAMES; do for s in $SEEDS; do
  echo "$n $s"
done; done | xargs -P $JOBS -L 1 bash -c 'nextpnr-himbaechel --json $0.json --device GW2AR-LV18QN88C8/I7 --vopt family=GW2A-18C --vopt cst='$d'/tangnano20k/tangnano20k.cst --freq 27 --seed $1 > $0.$1.log 2>&1'
med() { sort -n | awk '{a[NR]=$1} END{printf "%.1f (%.1f-%.1f, %d runs)", a[int((NR+1)/2)], a[1], a[NR], NR}'; }
for n in $NAMES; do
  f=$(for l in $n.*.log; do grep 'Max frequency' $l | tail -1 | awk '{print $7}'; done)
  lut=$(grep -E 'Info:[[:space:]]+LUT4:' $n.1.log | tail -1 | awk '{split($3,u,"/"); print u[1]}')
  echo "$label $n: $(echo "$f" | med) MHz, raw LUT4 $lut"
done
echo "$label all: $(for l in *.[0-9]*.log; do grep 'Max frequency' $l | tail -1 | awk '{print $7}'; done | med) MHz"
