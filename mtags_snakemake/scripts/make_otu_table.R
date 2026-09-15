#!/usr/bin/env Rscript

suppressMessages(library(tidyverse))

# Read args ---------------------------------------------------------------

args <- commandArgs(trailingOnly = T)

output_file <- args[1]
input_files <- args[2:length(args)]

# create named object
files <- 
  set_names(
    input_files,
    str_remove(basename(input_files),'_filtered\\.uc')
  )

# Main function -----------------------------------------------------------

make_otu_table <- function(input_files) {
  
  file_colnames <- 
    c('read_id','perc_id','aln','OTUId')
  
  otu_table <-
    files |> 
    map(
      ~ read_tsv(.x, col_names = file_colnames, col_types = 'cccc')
    ) |> 
    bind_rows(.id = 'sample') |> 
    mutate(sample = factor(sample, levels = names(files))) |> 
    count(sample, OTUId) |> 
    arrange(-n) |> 
    pivot_wider(names_from = sample, values_from = n, values_fill = 0, names_expand = T)

  return(otu_table)
}

# Create OTU table --------------------------------------------------------

otu_table <- make_otu_table(input_files = files)

write_tsv(x = otu_table, file = output_file)