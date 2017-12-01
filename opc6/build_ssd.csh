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
set testlist = ( pi-spigot-rev pi-spigot-bruce e-spigot-rev bigsieve sieve nqueens )
set bcpltestlist = (  \
	Leval  \
	Xsquare  \
	ack  \
	acoding  \
	anseq  \
	apfel  \
	beebgfx  \
	enig  \
	enigma-m3  \
	evale  \
	fact  \
	fft16  \
	growth  \
	hello  \
	invert  \
	kperms  \
	modarith  \
	monbfns  \
	pi-spigot-bcpl  \
	queens  \
	shell23  )

# too many tests for 1 SSD image!
#	kext  \
#       lambda \        
# 	empty  \           
#	splay  \
#	tag  )
    

pushd disk
foreach test ( $testlist )
    set newname = `echo $test | awk '{gsub("-.*-","");print substr($0,0,7)}'`
    echo "Building test $test as $newname"
    ## dummy assembly to get a binary size
    set size = `python3 ../${ASM}  -f ../tests/${test}.s  | grep ssembled| awk '{print $2+10}'`
    echo $size "bytes"
    
    python3 ../${ASM} -g bin --start_adr 0x2000 --size $size -f ../tests/${test}.s -o ${newname} > ../tests/${test}.lst
    echo $newname | awk '{printf("\$.%s\t1000\t1000",$1)}' > ${newname}.inf
end

foreach test ( $bcpltestlist )
    set newname = `echo $test | awk '{gsub("-.*-","");gsub("-","");print substr($0,0,7)}'`
    echo "Building test $test as $newname"
    ## dummy assembly to get a binary size
    set size = `python3 ../${ASM}  -f ../bcpltests/${test}.s  | grep ssembled| awk '{print $2+10}'`
    echo $size "bytes"
    python3 ../${ASM} -g bin --start_adr 0x2000 --size $size -f ../bcpltests/${test}.s -o ${newname} > ../bcpltests/${test}.lst
    echo $newname | awk '{printf("\$.%s\t1000\t1000",$1)}' > ${newname}.inf
end
popd

# Build the SSD image
rm -f ${SSD}
${MMB} blank_ssd ${SSD}
${MMB} putfile ${SSD} disk/*
${MMB} info ${SSD}

