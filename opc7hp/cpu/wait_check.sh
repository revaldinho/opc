#!/bin/bash
# wait_check.sh [cpu] - slow memory check for opc7hpcpu: the hazard tests and the quick claude-tests
# under random iwait and dwait (opc7htb.v -DWAIT_TEST), at several rates, for each port alone and
# both together, with two seeds each. Each run's retirement trace must match opc7emu.py
# (trace_compare.py), and STORE/OUT must match opc7cpu (check.sh). Then the interrupt check
# (int_check.sh) with waits. Prints a line per run that fails and a summary.
cpu=${1:-opc7hpcpu}
d=$(cd "$(dirname "$0")" && pwd); cd $d
TESTS=${TESTS:-"tests/haz_raw.hex tests/haz_flags.hex tests/haz_jump.hex tests/haz_misc.hex tests/haz_int.hex writefmt cmptest"}
SETS=${SETS:-"+iwp=50 +dwp=50 +iwp=10_+dwp=10 +iwp=30_+dwp=30 +iwp=80_+dwp=80"}
make -s $(for t in $TESTS; do case $t in tests/*) echo $t;; esac; done) || exit 1   # build the test images first
export TBDEFS=-DWAIT_TEST WORKTAG=wait   # own work directories: this can run beside a regression
runs=0; fails=0
for set in $SETS; do for seed in 1 2; do
  export SIMARGS="${set//_/ } +waitseed=$seed"
  for t in $TESTS; do
    runs=$((runs+1))
    if ! TIMEOUT=600 timeout 900 ./trace_compare.py $t $cpu > /dev/null 2>&1; then echo "FAIL trace $t $SIMARGS"; fails=$((fails+1)); fi
  done
  for t in writefmt tests/haz_jump.hex; do
    runs=$((runs+1))
    if ! TIMEOUT=600 ./check.sh $t $cpu > /dev/null 2>&1; then echo "FAIL check $t $SIMARGS"; fails=$((fails+1)); fi
  done
done; done
export SIMARGS="+iwp=30 +dwp=30 +waitseed=3"
if ! PERIODS="3 5 7 11 19" SEEDS="1 2" ./int_check.sh $cpu > build/wait_ints.log 2>&1; then echo "FAIL ints with waits: build/wait_ints.log"; fails=$((fails+1)); fi
runs=$((runs+1))
[ $fails = 0 ] && echo "PASS waits: $cpu, $runs runs" || { echo "FAIL waits: $cpu, $fails of $runs runs"; exit 1; }
