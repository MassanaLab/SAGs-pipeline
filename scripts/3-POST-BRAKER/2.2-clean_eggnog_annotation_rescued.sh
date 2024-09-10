#!/bin/bash

OUT=~/store/eggnog_LEUVEN_clean_skip4

mkdir -p ${OUT}

for SAMPLE in $(cat data/clean/Leuven_13_rescued.txt)
do

 tail -n +5 ~/store/eggnog_LEUVEN/${SAMPLE}/${SAMPLE}_eggnog.emapper.annotations | sed 's/#//g' > ${OUT}/${SAMPLE}_eggnog.emapper.annotations_clean

done
