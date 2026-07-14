#!/usr/bin/env bash

set -euo pipefail

#conda init
#conda activate R-4.5.1

##########################################################################################
##### execute with bash, make sure you are inside an enviroment where R is available #####
##########################################################################################

W=coass_revisit

# Paths
R_SCRIPT="scripts/Extract_gff_info_out_Braker.R"
NAMES_FILE="data/clean/names_${W}.txt"
#GFF_DIR="data/clean/gff3"
GFF_DIR="/mnt/smart/scratch/emm2/guillem/coass_revisit2/data/clean/aleix_gff_process_big2_coass_revisit_filter3/final_gff3"
#FA_DIR="data/clean/scaffolds_f3"
FA_DIR="/mnt/smart/scratch/emm2/guillem/coass_revisit2/data/clean/aleix_gff_process_big2_coass_revisit_filter3/assemblies3_clean"
OUT_DIR="data/clean/${W}_annotation_stats_test2"
LOG_DIR="data/logs/${W}"

rm -r "$OUT_DIR"
mkdir -p "$OUT_DIR"

rm -r "$LOG_DIR"
mkdir -p "$LOG_DIR"

# Check required files exist
[[ -f "$R_SCRIPT" ]] || { echo "ERROR: R script not found: $R_SCRIPT" >&2; exit 1; }
[[ -f "$NAMES_FILE" ]] || { echo "ERROR: names file not found: $NAMES_FILE" >&2; exit 1; }
[[ -d "$GFF_DIR" ]] || { echo "ERROR: GFF directory not found: $GFF_DIR" >&2; exit 1; }
[[ -d "$FA_DIR" ]] || { echo "ERROR: FASTA directory not found: $FA_DIR" >&2; exit 1; }

while IFS= read -r sample || [[ -n "$sample" ]]; do
    [[ -z "$sample" ]] && continue

    gff="${GFF_DIR}/${sample}_filter3.gff3"
    fa="${FA_DIR}/${sample}.fasta"
    sample_outdir="${OUT_DIR}/${sample}"

    echo "=== Processing: $sample ==="
    echo "GFF: $gff"
    echo "FASTA: $fa"
    echo "Output dir: $sample_outdir"

    if [[ ! -f "$gff" ]]; then
        echo "WARNING: missing GFF, skipping: $gff" >&2
        continue
    fi

    if [[ ! -f "$fa" ]]; then
        echo "WARNING: missing FASTA, skipping: $fa" >&2
        continue
    fi

    mkdir -p "$sample_outdir"

    (
        cd "$sample_outdir"

        if Rscript "$OLDPWD/$R_SCRIPT" \
            "$sample" \
            "$gff" \
            "$fa" \
            > "$OLDPWD/$LOG_DIR/${sample}.stdout.log" \
            2> "$OLDPWD/$LOG_DIR/${sample}.stderr.log"
        then
            echo "Done: $sample"
        else
            echo "FAILED: $sample (see logs)" >&2
        fi
    )

done < "$NAMES_FILE"

echo "All jobs finished."
