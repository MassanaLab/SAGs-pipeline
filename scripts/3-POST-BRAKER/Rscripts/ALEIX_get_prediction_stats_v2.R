# require(tidyverse)
require(readr)
require(tidyr)
require(dplyr)
require(stringr)
require(gtools)

# --- helpers ---------------------------------------------------------------

# Vectorized extractor for GFF3/GTF attribute strings: key=value;key2=value2
extract_attr <- function(x, key) {
  # returns the value for `key` or NA if absent
  m <- str_match(x, paste0("(^|;)", key, "=([^;]+)"))
  return(ifelse(is.na(m[,3]), NA_character_, m[,3]))
}

read_gtf <- function(gtf_file){
  gtf_colnames <- c('seqname','source','feature','start','end','score','strand','frame','attribute')

  # GFF3 has comment lines (##...), skip them
  gtf <- read_tsv(
    gtf_file,
    col_names = gtf_colnames,
    comment = "#",
    col_types = cols(
      seqname = col_character(),
      source = col_character(),
      feature = col_character(),
      start = col_integer(),
      end = col_integer(),
      score = col_character(),  # read as char then coerce later
      strand = col_character(),
      frame = col_character(),
      attribute = col_character()
    )
  )

  return(gtf)
}

gtf_summarizer <- function(gtf){

  # Parse attributes to get clean IDs for gene / transcript
  parsed <- gtf %>%
    mutate(
      len = end - start + 1,
      # pull typical GFF3 keys
      attr_ID = extract_attr(attribute, "ID"),
      attr_Parent = extract_attr(attribute, "Parent"),
      attr_gene_id = extract_attr(attribute, "gene_id"),
      attr_transcript_id = extract_attr(attribute, "transcript_id"),
      # normalize score (some features have ".", coerce to NA; else numeric)
      score = suppressWarnings(as.numeric(score))
    ) %>%
    mutate(
      # Define gene per row
      gene = dplyr::case_when(
        feature == "gene" ~ coalesce(attr_gene_id, attr_ID),
        feature %in% c("transcript", "mRNA") ~ coalesce(attr_gene_id, attr_Parent),
        TRUE ~ coalesce(attr_gene_id, NA_character_)
      ),
      # Define transcript per row
      transcript = dplyr::case_when(
        feature %in% c("transcript", "mRNA") ~ coalesce(attr_transcript_id, attr_ID),
        TRUE ~ coalesce(attr_transcript_id, attr_Parent) # exons/CDS/etc usually have Parent = transcript
      )
    ) %>%
    # fallbacks: still missing gene? for child rows, try to derive from transcript prefix like gX.tY -> gX
    mutate(
      gene = if_else(
        is.na(gene) & !is.na(transcript) & str_detect(transcript, "\\."),
        str_replace(transcript, "\\..*$", ""),
        gene
      )
    ) %>%
    # set factors for stable ordering (optional)
    mutate(
      seqname = factor(seqname, levels = unique(seqname)),
      gene = factor(gene, levels = unique(gene)),
      transcript = factor(transcript, levels = unique(transcript)),
      feature = factor(feature, levels = unique(feature))
    )

  # Gene lengths from 'gene' features
  gene_lengths <- parsed %>%
    filter(feature == "gene") %>%
    select(gene, gene_length = len)

  # Take transcript score from transcript rows (mRNA also supported)
  gene_score <- parsed %>%
    filter(feature %in% c("transcript","mRNA")) %>%
    select(transcript, score)

  # Summarize per (contig, gene, transcript, feature)
  gtf_summary <-
    parsed %>%
    filter(feature != "gene") %>%
    group_by(seqname, gene, transcript, feature) %>%
    summarise(n = n(), len = sum(len), .groups = "drop") %>%
    tidyr::pivot_wider(
      names_from = "feature",
      values_from = c("n","len"),
      values_fill = 0
    ) %>%
    select(-matches("length.*codon")) %>%
    mutate(across(contains("codon"), ~ ifelse(.x == 1, "yes", "no"))) %>%
    left_join(gene_lengths, by = "gene") %>%
    left_join(gene_score, by = "transcript") %>%
    select(
      contig = seqname, gene, gene_length, transcript, score, len_transcript,
      start_codon = n_start_codon, stop_codon = n_stop_codon,
      contains("CDS"), contains("exon"), contains("intron")
    ) %>%
    rename_with(~ paste0(str_remove(.x, "len_"), "_length"), contains("len_")) %>%
    rename_with(~ str_remove(.x, "^n_"), matches("^n_"))

  return(gtf_summary)
}

add_data_to_gtf_summary <- function(gtf_summary, tiara_file, emapper_file){

  emapper_kingdoms <-
    read_tsv(emapper_file, col_types = cols(.default = "c")) %>%
    # keep your original columns: 1 = query (transcript), 5 = tax/lineage-ish
    select(transcript = 1, annot = 5) %>%
    mutate(
      emapper_kingdom = case_when(
        str_detect(annot, "Bacteria") ~ "Bacteria",
        str_detect(annot, "Archaea") ~ "Archaea",
        str_detect(annot, "Viruses|viridae|virales") ~ "Viruses",
        str_detect(annot, "Eukaryota") ~ "Eukaryota",
        TRUE ~ "Unknown"
      )
    )

  tiara_df <-
    read_tsv(tiara_file, col_types = cols(.default = "c")) %>%
    select(contig = 1, tiara_1 = 2, tiara_3 = 3)

  # Join on clean transcript IDs (from summarizer) and contig
  prediction_stats <-
    gtf_summary %>%
    left_join(emapper_kingdoms, by = "transcript") %>%
    left_join(tiara_df, by = "contig") %>%
    group_by(gene) %>%
    arrange(desc(score), desc(transcript_length), .by_group = TRUE) %>%
    slice(1) %>%
    ungroup()

  return(prediction_stats)
}

get_prediction_stats <- function(gtf_file, emapper_file, tiara_file){
  gtf <- read_gtf(gtf_file)
  gtf_summary <- gtf_summarizer(gtf)
  add_data_to_gtf_summary(gtf_summary, tiara_file, emapper_file)
}

args <- commandArgs(trailingOnly = TRUE)
gtf_file <- args[1]
emapper_file <- args[2]
tiara_file <- args[3]
out_file <- args[4]

prediction_stats <- get_prediction_stats(gtf_file, emapper_file, tiara_file)
write_tsv(prediction_stats, out_file)
