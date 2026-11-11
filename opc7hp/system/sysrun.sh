#!/bin/bash
# sysrun.sh prog [ram_aw] - build a BCPL program for the OPC7 system and run it on sys_tb.v.
# prog is a name in ../software, opc7/claude-tests or opc7/bcpltests, searched in that order (its
# .sial, with that directory's bcpllib.sial, or the claude-tests one if it has none). The
# program is assembled with opc7sys_rom.s in place of opc7_rom.s and split by sysimg.py: below 0x1000
# the boot ROM, the rest the RAM (ram_aw: the RAM size the image is checked against, default 20).
# Work files: build/<prog>/. The UART output is compared with <prog>.expected if there is one,
# else with <prog>.emu.stdout. TIMEOUT seconds (default 3600) stops the simulation.
p=$1; aw=${2:-20}
d=$(cd "$(dirname "$0")" && pwd); opc=$(cd $d/../.. && pwd)   # the repository root
for s in $d/../software $opc/opc7/claude-tests $opc/opc7/bcpltests; do [ -e $s/$p.sial ] && src=$s && break; done
[ -n "$src" ] || { echo "no $p.sial in software, claude-tests or bcpltests"; exit 2; }
lib=$src/bcpllib.sial; [ -e $lib ] || lib=$opc/opc7/claude-tests/bcpllib.sial
w=$d/build/$p; mkdir -p $w; cd $w
python3 $opc/bcpl/sial2opc.py --opc7 -f $src/$p.sial -f $lib -s $opc/bcpl/opc7_syslib.s -g $opc/bcpl/ext_sial.h -o > $p.tmp.s || exit 1
cat $opc/include/opc7/macros.s $p.tmp.s $d/opc7sys_rom.s > $p.s && rm $p.tmp.s
python3 $opc/opc7/opc7asm.py -g sparse $p.s $p.hex > $p.lst || { tail -3 $p.lst; exit 1; }
python3 $d/sysimg.py $p.hex rom.hex ram.hex $aw || exit 1
rm -f uart.in; [ -e $src/$p.stdin ] && cp $src/$p.stdin uart.in
iverilog -o sim $d/sys_tb.v $d/opc7hsys.v $d/opc7_uart.v $d/../cpu/opc7hpcpu.v || exit 1
timeout ${TIMEOUT:-3600} vvp -n sim > sim.log
tail -1 sim.log
exp=$src/$p.expected; [ -e $exp ] || exp=$src/$p.emu.stdout
if [ -e $exp ]; then
  if cmp -s uart.out $exp; then echo "PASS $p: UART output identical to $(basename $exp)"; else echo "FAIL $p: diff $w/uart.out $exp"; exit 1; fi
fi
