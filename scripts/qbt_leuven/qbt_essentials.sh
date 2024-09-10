mkdir -p ~/lustre/qbt_essentials/busco/

cp ~/lustre/qbt/busco/*/short_summary.specific.eukaryota_odb10.*.txt ~/lustre/qbt_essentials/busco/

#rm -r ~/lustre/qbt/busco/


mkdir -p ~/lustre/qbt_essentials/quast/

for s in $(cat data/clean/samples_file_67.txt)
do

cp ~/lustre/qbt/quast/${s}/transposed_report.tsv ~/lustre/qbt_essentials/quast/${s}_transposed_report.tsv

done

#rm -r ~/lustre/qbt/quast/


#mkdir -p ~/lustre/qbt_essentials/tiara/

#mv ~/lustre/qbt/tiara/* ~/lustre/qbt_essentials/tiara/

#rm -r ~/lustre/qbt/tiara/
