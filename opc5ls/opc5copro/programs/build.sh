#!/bin/bash

function beeb_file {
      HEX=$1
      BIN=$2
    START=$3
      LEN=$4
     EXEC=$5

    echo $*

    # Work out lines to extract from hex file
    L1=$((1+16#$START))
    L2=$((16#$START + 16#$LEN))
    tr " " "\n" <${HEX} | sed -n ${L1},${L2}p > tmp.out

    # Swap the lo/hi bytes and convert to binary
    cut -c1,2 <tmp.out > tmp.hi
    cut -c3,4 <tmp.out > tmp.lo
    paste tmp.lo tmp.hi | xxd -p -r > ${BIN}

    # Create the inf file
    echo -e "\$.`basename ${BIN}`\t${START}\t${EXEC}" > ${BIN}.inf

    # tidy up
    rm -f tmp.out tmp.lo tmp.hi
}

SSD=pitest.ssd

MMB=../../../utils/mmb_utils/beeb

rm -f ${SSD}

${MMB} blank_ssd ${SSD}

rm -rf disk
mkdir -p disk

declare -A ndmap
ndmap[A]=6
ndmap[B]=359
ndmap[C]=400

len=0100

for load in "0800" "1000"
do

    for key in "${!ndmap[@]}"
    do

        name=disk/PI${load}${key}

        sed "s/#LOAD#/0x${load}/;s/#NDIGITS#/${ndmap[${key}]}/"<  pi-spigot-bruce.s > tmp.s
        python ../../opc5lsasm.py tmp.s tmp.hex
        beeb_file tmp.hex ${name} ${load} ${len} ${load}
        rm -f tmp.s tmp.hex
    done
done

${MMB} putfile ${SSD} disk/*
${MMB} info ${SSD}

