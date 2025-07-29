#!/bin/bash

W=coass_juliol

OUT=~/lustre/eggnog_${W}_clean_skip4

mkdir -p ${OUT}

E=lustre/eggnog_${W}

for SAMPLE in $(ls ${E} | awk -F "_" '{print $1"_"$2"_"$3}')
do

 tail -n +5 ${E}/${SAMPLE}/${SAMPLE}_eggnog.emapper.annotations | sed 's/#//g' > ${OUT}/${SAMPLE}_eggnog.emapper.annotations_clean

done
