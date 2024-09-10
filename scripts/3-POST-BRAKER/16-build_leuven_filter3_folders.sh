
OUT=store/LEUVEN_74_filter3_final_folders


for SAMPLE in $(cat data/clean/Leuven_SAGs_sel_74.txt)
do

	mkdir -p ${OUT}/${SAMPLE}


	cp lustre/filter3_genes_sample_hdr_leuven/${SAMPLE}_filter3_genes_hdr.aa ${OUT}/${SAMPLE}/

	cp lustre/filter3_codingseq_sample_hdr_leuven/${SAMPLE}_filter3_genes_hdr.codingseq ${OUT}/${SAMPLE}/

	cp lustre/filters_clean_leuven/filter3/${SAMPLE}_filter3_clean.fasta ${OUT}/${SAMPLE}/${SAMPLE}_filter3_clean_scaffolds.fasta

	cp store/braker_LEUVEN/gtf/${SAMPLE}_augustus.hints.gtf ${OUT}/${SAMPLE}/

	cp store/SAGS_Leuven/scaffolds/${SAMPLE}_scaffolds.fasta ${OUT}/${SAMPLE}/


done
