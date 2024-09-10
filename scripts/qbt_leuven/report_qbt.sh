#!/bin/sh

mkdir -p ~/lustre/qbt/all_reports


DATA_DIR=~/lustre/qbt/busco/
OUT_FILE=~/lustre/qbt/all_reports/busco_report.txt

HEADERS_SAMPLE=$(ls ${DATA_DIR} | grep 'GC' | head -1)
HEADERS=$(cat ${DATA_DIR}/${HEADERS_SAMPLE} | grep -v '^#' | sed '/^$/d' | grep -v '%' | perl -pe 's/.*\d+\s+//' | tr '\n' '\t')

echo -e "Sample\t${HEADERS}" > ${OUT_FILE}

for SAMPLE in $(ls ${DATA_DIR} | grep GC)
do
  REPORT=$(cat ${DATA_DIR}/${SAMPLE} | \
  grep -v '^#' | perl -pe 's/^\n//' | awk '{print $1}' | tr '\n' '\t')
  echo -e "${SAMPLE}\t${REPORT}" >> ${OUT_FILE}
done


DATA_DIR=~/lustre/qbt/tiara/
OUT_FILE=~/lustre/qbt/all_reports/tiara_report.txt

for SAMPLE in $(ls ${DATA_DIR} | grep '^GC')
do
  cat ${DATA_DIR}/log_${SAMPLE} | \
  grep -e 'archaea' -e 'bacteria' -e 'eukarya' -e 'organelle' -e 'unknown' -e 'prokarya' -e 'mitochondrion' -e 'plastid' | \
  awk -v var=${SAMPLE} '{print var$0}' OFS='\t' \
  >> ${OUT_FILE}
done


DATA_DIR=~/lustre/qbt/quast/
OUT_FILE=~/lustre/qbt/all_reports/quast_report.txt

HEADERS_SAMPLE=$(ls ${DATA_DIR} | grep 'GC' | head -1)
HEADERS=$(cat ${DATA_DIR}/${HEADERS_SAMPLE} | head -1)

echo -e "Sample\t${HEADERS}" > ${OUT_FILE}

for SAMPLE in $(ls ${DATA_DIR} | grep '^GC')
do
  REPORT=$(cat ${DATA_DIR}/${SAMPLE} | tail -1)
  echo -e "${SAMPLE}\t${REPORT}" >> ${OUT_FILE}
done
