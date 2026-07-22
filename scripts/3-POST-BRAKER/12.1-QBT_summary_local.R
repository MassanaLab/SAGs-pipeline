# esta en mi pc en Desktop/ICM-CSIC/CESGA/LEUVEN_QBT_FILTERS

rm(list = ls())

library(readr)
library(dplyr)
library(tidyr)
library(readxl)

#DATA_DIR <- "lustre/qbt_test_filter/all_reports/"

getwd()

#setwd("Desktop/ICM-CSIC/KAIJU//")

rm(list = ls())

for (x in seq(1:3)) {
    
    
    DATA_DIR <- sprintf("all_reports%s/", x)
    
    quast <- read_tsv(sprintf("%squast_report.txt", DATA_DIR))
    busco <- read_tsv(sprintf("%sbusco_report.txt", DATA_DIR))
    tiara <- read_tsv(sprintf("%stiara_report.txt", DATA_DIR), col_names = c('Sample', 'tiara'))
    
    tiara <- 
        tiara %>% 
        separate(tiara, sep = ': ', into = c('tax','n')) %>% 
        mutate(n = as.numeric(n)) %>% 
        group_by(Sample, tax) %>% 
        summarise(n = sum(n)) %>% 
        mutate(perc = 100*n/sum(n),
               all_tiara = sum(n)) %>% 
        select(-n) %>% 
        pivot_wider(names_from = tax, values_from = perc)
    
    tiara2 <- tiara |> 
        mutate_at(vars(3:ncol(tiara)), ~round(., 1))
    
    # %>% 
    #    mutate_at(vars(eukarya, bacteria, archaea, organelle, prokarya, unknown, plastid, mitochondrion), ~round(., 1)) 
    
    
    
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
    
    
    tiara <- select(tiara2, Sample, colnames(tiara2)[3:ncol(tiara2)], all_tiara)
    
    base2 <- left_join(base, tiara, by = "Sample")
    
    ### Write final summary table
    
    colnames(base2) <- c("Sample", "Mb (>= 0 )", "Mb (> =1k)", "Mb (>= 3kb)", "Mb (>= 5Kb)", "contigs (>= 1Kb)", "contigs (>= 3Kb)", "contigs (>= 5Kb)", "Largest contig", "GC (%)", "N50", "Complete BUSCOs", "Fragmented BUSCOs", "Completeness (%) (out of 255)", colnames(tiara2)[3:ncol(tiara2)], "all tiara")
    
    base2[is.na(base2)] <- 0
    
    write.table(base2, file = sprintf("QBT_LEUVEN_summary_test_filter%s.tsv", x), sep = "\t", row.names = FALSE)
    
}






