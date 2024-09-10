#!/bin/sh

N=3

OUT=~/lustre/qbt_leuven_filter${N}_ess/all_reports${N}

mkdir -p ${OUT}


DATA_DIR=~/lustre/qbt_leuven_filter${N}_ess/busco/
OUT_FILE=${OUT}/busco_report.txt

HEADERS_SAMPLE=$(ls ${DATA_DIR} | grep 'G' | head -1 | awk -F "." '{print $4}')
HEADERS=$(cat ${DATA_DIR}/short_summary.specific.eukaryota_odb10.${HEADERS_SAMPLE}.txt | grep -v '^#' | sed '/^$/d' | grep -v '%' | perl -pe 's/.*\d+\s+//' | tr '\n' '\t')

echo -e "Sample\t${HEADERS}" > ${OUT_FILE}

for SAMPLE in $(ls ${DATA_DIR} | grep G | awk -F "." '{print $4}')
do
  REPORT=$(cat ${DATA_DIR}/short_summary.specific.eukaryota_odb10.${SAMPLE}.txt | \
  grep -v '^#' | perl -pe 's/^\n//' | awk '{print $1}' | tr '\n' '\t')
  echo -e "${SAMPLE}\t${REPORT}" >> ${OUT_FILE}
done


DATA_DIR=~/lustre/qbt_leuven_filter${N}_ess/tiara/
OUT_FILE=${OUT}/tiara_report.txt

for SAMPLE in $(ls ${DATA_DIR} | grep '^G')
do
  cat ${DATA_DIR}/log_${SAMPLE} | \
  grep -e 'archaea' -e 'bacteria' -e 'eukarya' -e 'organelle' -e 'unknown' -e 'prokarya' -e 'mitochondrion' -e 'plastid' | \
  awk -v var=${SAMPLE} '{print var$0}' OFS='\t' \
  >> ${OUT_FILE}
done


DATA_DIR=~/lustre/qbt_leuven_filter${N}_ess/quast/
OUT_FILE=${OUT}/quast_report.txt

HEADERS_SAMPLE=$(ls ${DATA_DIR} | grep 'G' | head -1 | awk -F "_" '{print $1"_"$2}')
HEADERS=$(cat ${DATA_DIR}/${HEADERS_SAMPLE}_transposed_report.tsv | head -1)

echo -e "Sample\t${HEADERS}" > ${OUT_FILE}

for SAMPLE in $(ls ${DATA_DIR} | grep '^G' | awk -F "_" '{print $1"_"$2}')
do
  REPORT=$(cat ${DATA_DIR}/${SAMPLE}_transposed_report.tsv | tail -1)
  echo -e "${SAMPLE}\t${REPORT}" >> ${OUT_FILE}
done
