#!/bin/bash
# int_check.sh [cpu] - hardware interrupt check. Runs tests/haz_int.hex on an opc7h
# CPU (default opc7hpcpu) with opc7htb.v -DINT_TEST: once with no interrupts, then
# with random ones for every interrupt period in PERIODS and seed in SEEDS. The handler
# only counts in r14 and reads into r11, so each STORE/OUT sequence must match the uninterrupted one.
# Each run is stopped after TIMEOUT seconds (default 120); work files go in build/. TBDEFS and
# SIMARGS as for check.sh.
cpu=${1:-opc7hpcpu}
d=$(cd "$(dirname "$0")" && pwd)
src=$d/$cpu.v; [ -e "$src" ] || src=$cpu && cpu=$(basename "$cpu" .v)
w=$d/build/$cpu.ints${WORKTAG:+.$WORKTAG}; mkdir -p $w; cp $d/tests/haz_int.hex $w/test.hex; cd $w
pipe=; grep -q tb_retire "$src" && pipe=-DTB_PIPE
iverilog -DINT_TEST $TBDEFS -DCPU=$cpu $pipe -o sim $d/opc7htb.v "$src" || exit 2
run() { timeout ${TIMEOUT:-120} vvp -n sim +intp=$1 +intseed=$2 $SIMARGS | grep -a -E ' OUT | STORE |^INTS|terminated' | head -2000000 > s.$1.$2; }
run 0 1
grep -aq terminated s.0.1 || { echo "FAIL: no halt without interrupts"; exit 1; }
grep -a -E ' OUT | STORE ' s.0.1 > ref
runs=0; total=0; fails=0
for p in ${PERIODS:-3 4 5 6 7 8 9 11 13 16 19 23 29 37 51}; do
  for s in ${SEEDS:-1 2 3 4}; do
    run $p $s
    n=$(awk '/^INTS/{print $2}' s.$p.$s)
    if [ -z "$n" ]; then echo "FAIL period $p seed $s: no halt"; fails=$((fails+1))
    elif ! cmp -s ref <(grep -a -E ' OUT | STORE ' s.$p.$s); then echo "FAIL period $p seed $s: STORE/OUT differ after $n interrupts: diff $w/ref $w/s.$p.$s"; fails=$((fails+1))
    else total=$((total+n)); rm -f s.$p.$s; fi
    runs=$((runs+1))
  done
done
rm -f test.dump
base=$(awk '/^INTS/{print $2}' s.0.1)
[ $fails = 0 ] && echo "PASS ints: $cpu, $runs runs, $total interrupts or software interrupts ($base per run without hardware ones), STORE/OUT identical" || { echo "FAIL ints: $cpu, $fails of $runs runs"; exit 1; }
