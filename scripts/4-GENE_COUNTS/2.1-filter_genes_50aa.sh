module load seqkit

W=david_75

OUT=lustre/${W}_filter_genes_50

mkdir -p ${OUT}

for SAMPLE in $(cat data/clean/${W}.txt)
do

	seqkit seq -m 50 store/${W}_filter3_final_folders/${SAMPLE}/${SAMPLE}_filter3_genes_hdr.aa -o ${OUT}/${SAMPLE}_filter3_genes_hdr_filter_50aa.aa

done
