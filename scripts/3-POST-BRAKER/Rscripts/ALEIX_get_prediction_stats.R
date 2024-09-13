
#require(tidyverse)
require(readr)
require(tidyr)
require(dplyr)
require(stringr)
require(gtools)

read_gtf <- function(gtf_file){
  
  gtf_colnames <- 
    c('seqname','source','feature','start','end','score','strand','frame','attribute')

  gtf <- 
    read_tsv(gtf_file, col_names = gtf_colnames)

  return(gtf)
}

gtf_summarizer <- function(gtf){

  gtf_processed <- 
    gtf %>% 
    mutate(len = end-start+1,
           seqname = factor(seqname, levels = unique(seqname)),
           gene = if_else(feature == 'gene',attribute, NA_character_),
           gene = factor(gene, levels = unique(gene)),
           transcript = if_else(feature == 'transcript', attribute, NA_character_),
           feature = factor(feature, levels = unique(feature))) %>% 
    fill(gene, transcript)
  
  gene_lengths <- 
    gtf_processed %>% 
    filter(feature == 'gene') %>% 
    select(gene, gene_length = len)
  
  # NEW
  gene_score <- 
      gtf_processed %>% 
      filter(feature == 'transcript') %>% 
      select(transcript, score)
  
  gtf_summary <- 
    gtf_processed %>% 
    filter(feature != 'gene') %>% 
    group_by(seqname, gene, transcript, feature) %>% 
    summarise(n = n(),
              len = sum(len)) %>% 
    pivot_wider(names_from = 'feature',values_from = c('n','len'), values_fill = 0) %>% 
    select(-matches('length.*codon')) %>% 
    mutate(across(contains('codon'), ~ ifelse(.x == 1, 'yes','no'))) %>% 
    left_join(gene_lengths) %>% 
    left_join(gene_score) %>% # NEW + ADD SCORE ABAJO EN EL SELECT
    select(contig = seqname, gene, gene_length, transcript, score, len_transcript,
           start_codon = n_start_codon, stop_codon = n_stop_codon,contains('CDS'), contains('exon'), contains('intron')) %>% 
    rename_with(~ paste0(str_remove(.x, 'len_'),'_length'), contains('len_')) %>% 
    rename_with(~ str_remove(.x, 'n_'), matches('^n_'))

  
  return(gtf_summary)  
}

add_data_to_gtf_summary <- function(gtf_summary, tiara_file, emapper_file){
  
  emapper_kingdoms <- 
      read_tsv(emapper_file) %>% 
      select(transcript = 1, annot = 5) %>% 
      mutate(emapper_kingdom = case_when(str_detect(annot, 'Bacteria') ~ 'Bacteria',
                                         str_detect(annot, 'Archaea') ~ 'Archaea',
                                         str_detect(annot, 'Viruses|viridae|virales') ~ 'Viruses',
                                         str_detect(annot, 'Eukaryota') ~ 'Eukaryota',
                                         TRUE ~ 'Unknown'))
  
  tiara_df <- 
    read_tsv(tiara_file) %>% 
    select(contig = 1, tiara_1 = 2, tiara_3 = 3)
  
  prediction_stats <- 
    gtf_summary %>% 
    left_join(emapper_kingdoms) %>% 
    left_join(tiara_df) %>% # NEW lo de abajo
      group_by(gene) %>% 
      arrange(desc(score), desc(transcript_length)) %>%
      slice(1) %>%
      ungroup()
  
  return(prediction_stats)
  
}

get_prediction_stats <- function(gtf_file, emapper_file, tiara_file){
  
  gtf <- 
    read_gtf(gtf_file)
  
  gtf_summary <- 
    gtf_summarizer(gtf)

  add_data_to_gtf_summary(gtf_summary, tiara_file, emapper_file)
  
}

args <- commandArgs(trailingOnly = T)

gtf_file <- args[1]
emapper_file <- args[2]
tiara_file <- args[3]
out_file <- args[4]

prediction_stats <- get_prediction_stats(gtf_file, emapper_file, tiara_file)

write_tsv(prediction_stats, out_file)
