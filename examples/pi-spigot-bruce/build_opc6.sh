#!/bin/bash

ASM=opc6/opc6asm.py

INC_FLAGS="-I ../../include/opc6 -I ../../include"

function beeb_file {
      HEX=$1
      BIN=$2
    START=$3
      LEN=$4
     EXEC=$5

    echo $*

    xxd -r -p < ${HEX} | dd ibs=2 conv=swab skip=$((16#${START})) count=$((16#${LEN})) > ${BIN}

    # Create the inf file
    echo -e "\$.`basename ${BIN}`\t${START}\t${EXEC}" > ${BIN}.inf
}

SSD=pi_opc6.ssd

MMB=../../utils/mmb_utils/beeb

rm -f ${SSD}

${MMB} blank_ssd ${SSD}

rm -rf disk_opc6
mkdir -p disk_opc6

declare -A ndmap
ndmap[A]=6
ndmap[B]=359
ndmap[C]=400

len=0100

for load in "0800" "1000"
do

    for key in "${!ndmap[@]}"
    do

        name=disk_opc6/PI${load}${key}

        sed "s/#LOAD#/0x${load}/;s/#NDIGITS#/${ndmap[${key}]}/"<  main.s > tmp1.s

	     # run the pre-processor to resolve and ##includes
	     filepp $INC_FLAGS -kc '##' tmp1.s  > tmp2.s
        python ../../${ASM} tmp2.s tmp.hex
        beeb_file tmp.hex ${name} ${load} ${len} ${load}
        rm -f tmp1.s tmp2.s tmp.hex
    done
done

${MMB} putfile ${SSD} disk_opc6/*
${MMB} info ${SSD}

