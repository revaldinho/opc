#!/bin/bash
# sysall.sh - run every claude-tests and bcpltests program on the system simulation (sysrun.sh), JOBS at
# a time (default 10), and print one line each and a summary. Left out: flt (floating point, which
# sial2opc rejects), jge0m_mlab_nop (a SIAL fragment for sial-check, not a program) and the big sorts
# (heapqsort, heapsort, nqsort, pesort), which run for hours in simulation.
d=$(cd "$(dirname "$0")" && pwd); cd $d; mkdir -p build
SKIP=" bcpllib sial-check flt jge0m_mlab_nop heapqsort heapsort nqsort pesort "
T=$(for f in ../../opc7/claude-tests/*.sial ../../opc7/bcpltests/*.sial; do b=$(basename $f .sial); [[ "$SKIP" == *" $b "* ]] || echo $b; done | sort -u)
echo $T | tr ' ' '\n' | xargs -P ${JOBS:-10} -I{} sh -c './sysrun.sh {} > build/{}.run 2>&1; tail -1 build/{}.run' > build/all.txt
n=$(echo $T | wc -w); p=$(grep -c '^PASS' build/all.txt)
grep -v '^PASS' build/all.txt
echo "sysall: $p of $n programs pass"; [ $p = $n ]
