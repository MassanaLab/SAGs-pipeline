
OUT=~/store/kaiju_Leuven_grep_C

mkdir -p ${OUT}

for SAMPLE in $(ls store/kaiju_Leuven)
do

	grep -w "C" store/kaiju_Leuven/${SAMPLE}/${SAMPLE}_kaiju_faa_names.out > ${OUT}/${SAMPLE}_kaiju_faa_names_grep_C.out

done
