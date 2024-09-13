module load seqkit

for FAILED in $(ls lustre/braker_redo_v9/*/braker/Spaln/nuc*prot*);
do
  	PROT=$(echo ${FAILED} | perl -pe 's/nuc_\d+_//');
        grep '^>' ${PROT} | tr -d '>';

done > data/clean/remove_prots.txt

seqkit grep -v -f data/clean/remove_prots.txt store/Eukaryota_v9.fa > store/Eukaryota_v10.fa
