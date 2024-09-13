rm(list = ls())

getwd()
setwd("/home/guillem/Desktop/ICM-CSIC/QBT_DAVID_52/")

library(readr)
library(dplyr)
library(tidyr)
library(readxl)

DATA_DIR <- "all_reports/"

quast <- read_tsv(sprintf("%squast_report.txt", DATA_DIR))
busco <- read_tsv(sprintf("%sbusco_report.txt", DATA_DIR))


tiara <- read_tsv(sprintf("%stiara_report.txt", DATA_DIR), col_names = c('Sample', 'tiara'))

tiara <- tiara[1:166,] %>% 
    separate(tiara, sep = ': ', into = c('tax','n')) %>% 
    mutate(n = as.numeric(n)) %>% 
    group_by(Sample, tax) %>% 
    summarise(n = sum(n)) |> 
    pivot_wider(names_from = tax, values_from = n) |> 
    mutate_at(vars(-Sample), ~replace_na(., 0))
    
    
exclude_cols <- c("Sample", "mitochondrion", "plastid")

# Identify the columns to sum (all columns except those in exclude_cols)
cols_to_sum <- setdiff(colnames(tiara), exclude_cols)

# Sum the existing columns and create a new column
tiara <- tiara %>%
    mutate(all_tiara = rowSums(across(all_of(cols_to_sum)), na.rm = TRUE))


base <- data.frame(matrix(NA, nrow = nrow(quast), ncol = 14))

colnames(base) <- c("Sample", "Mb (>= 0 )", "Mb (> =1k)", "Mb (>= 3kb)", "Mb (>= 5Kb)", "contigs (>= 1Kb)", "contigs (>= 3Kb)", "contigs (>= 5Kb)", "Largest contig", "GC (%)", "N50", "Complete BUSCOs", "Fragmented BUSCOs", "Completeness (%) (out of 255)")


### QUAST 

base$Sample <- quast$Sample

base[2:5] <- round(quast[7:10] / 1000000, 2)

base[6:8] <- quast[4:6]

base$`Largest contig` <- quast$`Largest contig`

base$`GC (%)` <- quast$`GC (%)`

base$N50 <- quast$N50


### BUSCO

colnames(busco) <- c("Sample", "X", "Results", "Complete", "Complete and Single", "Complete and Duplicated", "Fragmented", "Missing", "X2", "X3", "X4")

base$`Complete BUSCOs` <-  busco$Complete

base$`Fragmented BUSCOs` <- busco$Fragmented

base$`Completeness (%) (out of 255)` <- round(100*(base$`Complete BUSCOs` + base$`Fragmented BUSCOs`)/255, 2)


### TIARA

tiara <- select(tiara, Sample, all_of(cols_to_sum), mitochondrion, plastid, all_tiara)

base2 <- left_join(base, tiara, by = "Sample")

### Write final summary table

colnames(base2) <- c("Sample", "Mb (>= 0 )", "Mb (> =1k)", "Mb (>= 3kb)", "Mb (>= 5Kb)", "contigs (>= 1Kb)", "contigs (>= 3Kb)", "contigs (>= 5Kb)", "Largest contig", "GC (%)", "N50", "Complete BUSCOs", "Fragmented BUSCOs", "Completeness (%) (out of 255)", colnames(tiara)[2:ncol(tiara)])

base2[is.na(base2)] <- 0



write.table(base2, file = sprintf("%sQBT_david_summary_52.tsv", DATA_DIR), sep = "\t", row.names = FALSE)


# Ensure the columns are numeric
base2$eukarya <- as.numeric(base2$eukarya)
base2$unknown <- as.numeric(base2$unknown)
base2$organelle <- as.numeric(base2$organelle)

# Create a new column with the sum of "eukarya", "unknown", and "organelle"
rowSums(base2[, c("eukarya", "unknown", "organelle")], na.rm = TRUE)

base2$all_tiara

# Print the first few rows to verify
print(head(base2))

