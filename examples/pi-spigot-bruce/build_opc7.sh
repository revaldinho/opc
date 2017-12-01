#!/bin/bash

ASM=opc7/opc7asm.py

INC_FLAGS="-I ../../include/opc7 -I ../../include"

function beeb_file {
      BIN=$1
      OUT=$2
    START=$3
      LEN=$4
     EXEC=$5

    echo $*

    dd ibs=4 skip=$((16#${START})) count=$((16#${LEN})) < ${BIN} > ${OUT}

    # Create the inf file
    echo -e "\$.`basename ${OUT}`\t${START}\t${EXEC}" > ${OUT}.inf
}

SSD=pi_opc7.ssd

MMB=../../utils/mmb_utils/beeb

rm -f ${SSD}

${MMB} blank_ssd ${SSD}

rm -rf disk_opc7
mkdir -p disk_opc7

declare -A ndmap
ndmap[A]=6
ndmap[B]=359
ndmap[C]=400
ndmap[D]=1000

len=0100

for load in "0800" "1000"
do

    for key in "${!ndmap[@]}"
    do

        name=disk_opc7/PI${load}${key}

        sed "s/#LOAD#/0x${load}/;s/#NDIGITS#/${ndmap[${key}]}/"<  main.s > tmp1.s

	     # run the pre-processor to resolve and ##includes
	     filepp $INC_FLAGS -kc '##' tmp1.s  > tmp2.s
        python ../../${ASM} -f tmp2.s -o tmp.bin -g bin
        beeb_file tmp.bin ${name} ${load} ${len} ${load}
        rm -f tmp1.s tmp2.s tmp.bin
    done
done

${MMB} putfile ${SSD} disk_opc7/*
${MMB} info ${SSD}

