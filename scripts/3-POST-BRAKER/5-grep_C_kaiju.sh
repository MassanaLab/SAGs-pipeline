W=coass_juliol

OUT=~/lustre/kaiju_${W}_grep_C

rm -r ${OUT}

mkdir -p ${OUT}

for SAMPLE in $(cat data/clean/names_${W}.txt)
do

        echo "$SAMPLE"

        grep -w "C" lustre/kaiju_${W}/${SAMPLE}/${SAMPLE}_kaiju_faa_names.out > ${OUT}/${SAMPLE}_kaiju_faa_names_grep_C.out

done
