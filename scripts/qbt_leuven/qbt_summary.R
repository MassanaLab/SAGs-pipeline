rm(list = ls())

### Load libraries

library(readr)
library(dplyr)
library(tidyr)
library(readxl)

### Main directory

DATA_DIR <- "lustre/qbt/all_reports/"

### Re-format + clean unknowks from TIARA

tiara <- read_tsv(sprintf("%stiara_report.txt", DATA_DIR), col_names = FALSE)

tiara <- separate(tiara, X2, c("type", "num"))

tiaradf <- as.data.frame(tiara)

tiaradf$num <- as.numeric(tiaradf$num)

summed_data <- tiaradf %>%
    group_by(X1, type) %>%
    summarise(num = sum(num))

data_wide <- spread(summed_data, type, num)

write_tsv(data_wide, sprintf("%stiara_report_GOOD.tsv", DATA_DIR))

#################################################################################################################
### Read QUAST, BUSCO & TIARA report files
#################################################################################################################

rm(list = ls())

DATA_DIR <- "lustre/qbt/all_reports/"

quast <- read_tsv(sprintf("%squast_report.txt", DATA_DIR))
busco <- read_tsv(sprintf("%sbusco_report.txt", DATA_DIR))
tiara <- read_tsv(sprintf("%stiara_report_GOOD.tsv", DATA_DIR))

base <- data.frame(matrix(NA, nrow = nrow(quast), ncol = 21))

colnames(base) <- c("Sample", "Mb (>= 0 )", "Mb (> =1k)", "Mb (>= 3kb)", "Mb (>= 5Kb)", "contigs (>= 1Kb)", "contigs (>= 3Kb)", "contigs (>= 5Kb)", "Largest contig", "GC (%)", "N50", "Complete BUSCOs", "Fragmented BUSCOs", "Completeness (%) (out of 255)", "%-bact", "%-euk", "%-mit", "%-org", "%-plas", "%-unk", "all tiara")

### QUAST ###

base$Sample <- quast$Sample

base[2:5] <- round(quast[7:10] / 1000000, 2)

base[6:8] <- quast[4:6]

base$`Largest contig` <- quast$`Largest contig`

base$`GC (%)` <- quast$`GC (%)`

base$N50 <- quast$N50


### BUSCO ###

colnames(busco) <- c("Sample", "X", "Results", "Complete", "Complete and Single", "Complete and Duplicated", "Fragmented", "Missing", "X2", "X3", "X4")

base$`Complete BUSCOs` <-  busco$Complete

base$`Fragmented BUSCOs` <- busco$Fragmented

base$`Completeness (%) (out of 255)` <- round(100*(base$`Complete BUSCOs` + base$`Fragmented BUSCOs`)/255, 2)


### TIARA ###

tiara <- read_tsv(sprintf("%stiara_report_GOOD.tsv", DATA_DIR))

for (i in 1:dim(tiara)[1]){
  for (j in 1:dim(tiara)[2]){
    if (is.na(tiara[i,j]) == TRUE){
      tiara[i,j] = 0
    }
  }
}

base$`all tiara` <- rowSums(tiara[,2:ncol(tiara)])

base$`%-euk` <- round(100* tiara$eukarya / base$`all tiara`, 1)

base$`%-mit` <- round(100* tiara$mitochondrion / base$`all tiara`, 1)

base$`%-org` <- round(100* tiara$organelle / base$`all tiara`, 1)

base$`%-plas` <- round(100* tiara$plastid / base$`all tiara`, 1)

base$`%-unk` <- round(100* tiara$unknown / base$`all tiara`, 1)

if ("bacteria" %in% colnames(tiara)) {
    base$`%-bact` <- round(100* tiara$bacteria / base$`all tiara`, 1)
} else {
    base$`%-bact` <- 0
}

### Write final summary table

write_tsv(base, sprintf("%sQBT_summary_252.tsv", DATA_DIR))


