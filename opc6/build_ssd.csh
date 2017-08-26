#!/bin/tcsh -f
#
# ./build_ssd.csh
#
# Build a BBC Micro SSD image of sample programs which can be run using the BBC Tube coprocessor
# versions of OPC6 (PiTubeDirect or the Matchbox/GOP FPGA versions)
#

rm -rf disk
mkdir -p disk
set ASM = opc6byteasm.py
set MMB = ../utils/mmb_utils/beeb
set SSD = OPC6DEMO.ssd
set testlist = ( pi-spigot-rev pi-spigot-bruce e-spigot-rev bigsieve sieve )

rm -f ${SSD}

${MMB} blank_ssd ${SSD}

pushd disk
foreach test ( $testlist )
    set newname = `echo $test | awk '{gsub("-.*-","");print substr($0,0,7)}'`
    echo "Building test $test as $newname"
    python ../${ASM} -g bin --start_adr 0x2000 --size 0x200 -f ../tests/${test}.s -o ${newname} > ../tests/${test}.lst
    echo $newname | awk '{printf("$.%s\t1000\t1000",$1)}' > ${newname}.inf
end
popd

${MMB} putfile ${SSD} disk/*
${MMB} info ${SSD}

