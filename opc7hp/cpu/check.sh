#!/bin/bash
# check.sh test [cpu] - run an OPC7 test (opc/opc7/claude-tests/<test>.hex, or
# any .hex path) on an opc7h CPU (default opc7hpcpu) with opc7htb.v, and on
# opc7cpu.v (in ../../opc7) with opc7tb.v, and compare their STORE and OUT sequences. Prints
# the halt cycle of each (simulation time / 1000, including 4 reset cycles).
# Work files go in build/<cpu>.<test> and build/opc7.<test> (plus .$WORKTAG if set, so that
# runs with different options can share the machine); each run's output
# is capped at LIMIT lines (default 2000000) so a runaway can't fill the disk,
# and stopped after TIMEOUT seconds (default 3600; randtest takes over 10 minutes
# when several simulations share the machine). TBDEFS adds iverilog options for the opc7h CPU's
# build and SIMARGS vvp plusargs, e.g. TBDEFS=-DWAIT_TEST SIMARGS='+iwp=30 +dwp=30'.
t=$1; cpu=${2:-opc7hpcpu}
d=$(cd "$(dirname "$0")" && pwd); opc=$d/../../opc7
hex=$opc/claude-tests/$t.hex; [ -e "$t" ] && { hex=$(readlink -f "$t"); t=$(basename "$t" .hex); }
[ -e "$hex" ] || { echo "no $hex"; exit 2; }
src=$d/$cpu.v; [ -e "$src" ] || src=$opc/$cpu.v
run() {  # name tb cpu.v [defines]
  w=$d/build/$1.$t${WORKTAG:+.$WORKTAG}; mkdir -p $w; cp "$hex" $w/test.hex
  iverilog $4 -o $w/sim $2 $3 || return 1
  ( cd $w && timeout ${TIMEOUT:-3600} vvp -n sim $SIMARGS | grep -a -E ' OUT | STORE |terminated' | head -${LIMIT:-2000000} > s.out; rm -f test.dump )  # 1M-word memory dump, not needed
  echo "$1: $(grep -a terminated $w/s.out | awk '{print $NF/1000}' | grep . || echo 'no halt') cycles"
}
pipe=; grep -q tb_retire "$src" && pipe=-DTB_PIPE   # see opc7htb.v
run $cpu $d/opc7htb.v $src "-DCPU=$cpu $pipe $TBDEFS" & run opc7 $opc/opc7tb.v $opc/opc7cpu.v & wait
if cmp -s <(grep -av terminated $d/build/$cpu.$t${WORKTAG:+.$WORKTAG}/s.out) <(grep -av terminated $d/build/opc7.$t${WORKTAG:+.$WORKTAG}/s.out); then
  echo "PASS $t: $cpu STORE/OUT sequence identical to opc7cpu"
else
  echo "FAIL $t: diff $d/build/$cpu.$t${WORKTAG:+.$WORKTAG}/s.out $d/build/opc7.$t${WORKTAG:+.$WORKTAG}/s.out"; exit 1
fi
