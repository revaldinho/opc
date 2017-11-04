#!/bin/tcsh -f
# Remove non primary data files
pushd tests


if ( $#argv > 0 ) then
    if ( $argv[1] == "clean" ) then
        make clean
        exit
    endif
endif

#Check for pypy3
pypy3 --version > /dev/null
if ( $status) then
    setenv pyexec python3
else
    setenv pyexec pypy3
endif

set assembler = ../opc7asm.py
set testlist = ( bperm bigsieve  davefib davefib_int e-spigot-rev  fib hello math32  nqueens pi-spigot-rev  robfib sieve )
set numtests = 0
set fails = 0

## Make all the emulation traces

make -j 4 all_emulation

make all_simulation


foreach test ( $testlist )
    @ numtests ++ 
    echo ""    
    diff -s ${test}.*.stdout
    if ( $status != 0 ) then
        echo "FAIL - $test simulation doesn't match emulation result"
        @ fails++
    endif
end

if ( $fails == 0 ) then
    echo "P A S S  - all " $numtests " test matched between simulation and emulation"
else
    echo "F A I L - " $fails " tests out of " $numtests " had mismatches between simulation and emulation"
endif

popd
