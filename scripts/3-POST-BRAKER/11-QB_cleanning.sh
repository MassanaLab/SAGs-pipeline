
mkdir -p lustre/qbt_leuven_filter1_ess/quast
mkdir -p lustre/qbt_leuven_filter2_ess/quast
mkdir -p lustre/qbt_leuven_filter3_ess/quast

mkdir -p lustre/qbt_leuven_filter1_ess/busco
mkdir -p lustre/qbt_leuven_filter2_ess/busco
mkdir -p lustre/qbt_leuven_filter3_ess/busco


cp -r lustre/qbt_leuven_filter1/tiara/ lustre/qbt_leuven_filter1_ess
cp -r lustre/qbt_leuven_filter2/tiara/ lustre/qbt_leuven_filter2_ess
cp -r lustre/qbt_leuven_filter3/tiara/ lustre/qbt_leuven_filter3_ess


for SAMPLE in $(cat data/clean/Leuven_SAGs_sel_74.txt)
do

	cp lustre/qbt_leuven_filter1/quast/${SAMPLE}/transposed_report.tsv lustre/qbt_leuven_filter1_ess/quast/${SAMPLE}_transposed_report.tsv
	cp lustre/qbt_leuven_filter1/busco/${SAMPLE}/short_summary.specific.eukaryota_odb10.${SAMPLE}.txt lustre/qbt_leuven_filter1_ess/busco/

	cp lustre/qbt_leuven_filter2/quast/${SAMPLE}/transposed_report.tsv lustre/qbt_leuven_filter2_ess/quast/${SAMPLE}_transposed_report.tsv
        cp lustre/qbt_leuven_filter2/busco/${SAMPLE}/short_summary.specific.eukaryota_odb10.${SAMPLE}.txt lustre/qbt_leuven_filter2_ess/busco/

	cp lustre/qbt_leuven_filter3/quast/${SAMPLE}/transposed_report.tsv lustre/qbt_leuven_filter3_ess/quast/${SAMPLE}_transposed_report.tsv
        cp lustre/qbt_leuven_filter3/busco/${SAMPLE}/short_summary.specific.eukaryota_odb10.${SAMPLE}.txt lustre/qbt_leuven_filter3_ess/busco/

done

rm -r lustre/qbt_leuven_filter1
rm -r lustre/qbt_leuven_filter2
rm -r lustre/qbt_leuven_filter3
