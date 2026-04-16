#!/usr/bin/env bash
#
# 0_parsing_extract_regions_output.sh
# Collects per-species region and intron statistics from:
#   lustre/coass_revisit_annotation_stats/<sample>/
#
# Output:
#   Table_genome_prediction_stats.tsv
#

set -euo pipefail

W=coass_revisit

SPECIES_LIST="data/clean/names_${W}.txt"
STATS_DIR="data/clean/${W}_annotation_stats"
OUTFILE="coass_revisit_Table_genome_prediction_stats.tsv"

tmp_prefix="$(mktemp -u tmp_extract_XXXXXXXX_)"
data_all="${tmp_prefix}dataALL"

[[ -f "$SPECIES_LIST" ]] || { echo "ERROR: missing species list: $SPECIES_LIST" >&2; exit 1; }
[[ -d "$STATS_DIR" ]] || { echo "ERROR: missing stats dir: $STATS_DIR" >&2; exit 1; }

first_species=""

while IFS= read -r sp || [[ -n "$sp" ]]; do
    [[ -z "$sp" ]] && continue

    sample_dir="${STATS_DIR}/${sp}"
    genreg1k="${sample_dir}/${sp}_genomicregions1k.txt"
    intron="${sample_dir}/${sp}_IntronCvsL.txt"

    echo "Extracting data from ${sp} ..."

    if [[ ! -f "$genreg1k" ]]; then
        echo "WARNING: missing file, skipping: $genreg1k" >&2
        continue
    fi

    if [[ ! -f "$intron" ]]; then
        echo "WARNING: missing file, skipping: $intron" >&2
        continue
    fi

    if [[ -z "$first_species" ]]; then
        first_species="$sp"
    fi

    # Region info: keep only numeric lengths as one line, prefixed by species
    {
        printf "%s\t" "$sp"
        grep -v "Region" "$genreg1k" \
            | cut -f3 \
            | paste -sd $'\t' -
        printf "\n"
    } > "${tmp_prefix}genreg_${sp}"

    # Intron summary: keep data line only
    tail -1 "$intron" | cut -f2-9 > "${tmp_prefix}intron_${sp}"

    paste \
        "${tmp_prefix}genreg_${sp}" \
        "${tmp_prefix}intron_${sp}" \
        >> "$data_all"

done < "$SPECIES_LIST"

[[ -n "$first_species" ]] || { echo "ERROR: no valid samples found" >&2; exit 1; }

first_sample_dir="${STATS_DIR}/${first_species}"
first_genreg="${first_sample_dir}/${first_species}_genomicregions1k.txt"
first_intron="${first_sample_dir}/${first_species}_IntronCvsL.txt"

# Build header
{
    printf "Species\t"
    grep -v "Region" "$first_genreg" \
        | cut -f2 \
        | paste -sd $'\t' -
    printf "\n"
} > "${tmp_prefix}genreg_head"

head -1 "$first_intron" | cut -f2-9 > "${tmp_prefix}intron_head"

paste \
    "${tmp_prefix}genreg_head" \
    "${tmp_prefix}intron_head" \
    > "${tmp_prefix}table_head"

cat "${tmp_prefix}table_head" "$data_all" > "$OUTFILE"
rm -f "${tmp_prefix}"*

echo
echo "Results written to ${OUTFILE}"
