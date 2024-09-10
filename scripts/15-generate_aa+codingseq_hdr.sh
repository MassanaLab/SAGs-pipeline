
module load seqkit


OUT1=lustre/filter3_gene_lists_leuven

OUT2=lustre/filter3_genes_leuven
OUT3=lustre/filter3_genes_sample_hdr_leuven

mkdir -p ${OUT1}
mkdir -p ${OUT2}
mkdir -p ${OUT3}


OUT4=lustre/filter3_codingseq_leuven
OUT5=lustre/filter3_codingseq_sample_hdr_leuven

mkdir -p ${OUT4}
mkdir -p ${OUT5}


for SAMPLE in $(cat data/clean/Leuven_SAGs_sel_74.txt)
do

	awk '{print $2}' lustre/filter3_scaffold_gene_link_leuven/${SAMPLE}_filter3_scaffold_gene_link.tsv | tail -n +2 > ${OUT1}/${SAMPLE}_filter3_gene_list.txt


	seqkit grep -f ${OUT1}/${SAMPLE}_filter3_gene_list.txt store/braker_LEUVEN/aa/${SAMPLE}_augustus.hints.aa > ${OUT2}/${SAMPLE}_filter3_genes.aa

	sed "s/>\(.*\)/>${SAMPLE}_\1/g" ${OUT2}/${SAMPLE}_filter3_genes.aa > ${OUT3}/${SAMPLE}_filter3_genes_hdr.aa



	seqkit grep -f ${OUT1}/${SAMPLE}_filter3_gene_list.txt store/braker_LEUVEN/codingseq/${SAMPLE}_augustus.hints.codingseq > ${OUT4}/${SAMPLE}_filter3_genes.codingseq

	sed "s/>\(.*\)/>${SAMPLE}_\1/g" ${OUT4}/${SAMPLE}_filter3_genes.codingseq > ${OUT5}/${SAMPLE}_filter3_genes_hdr.codingseq


done

