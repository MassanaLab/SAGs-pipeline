require(readr)
require(tidyr)
require(dplyr)
require(stringr)
require(gtools)


read_kaiju <- function(kaiju_file){
    
    k <- read.table(kaiju_file, fill = TRUE, sep = "\t", header = FALSE) %>% 
        separate(V4, c("x1", "x2", "x3")) %>% 
        select("transcript" = V2, "Kaiju" = x3) %>% 
        mutate(Kaiju = ifelse(grepl("vir", Kaiju), "Viruses", Kaiju)) %>% 
        mutate(Kaiju = ifelse(grepl("bact", Kaiju), "Bacteria", Kaiju))
    
    return(k)
}

read_gtf <- function(processed_gtf_file){
    
    proc_gtf <- read_tsv(processed_gtf_file) %>% 
        select(contig, transcript, 
               transcript_length, CDS_length, exon, 
               start_codon, stop_codon, 
               "eggNOG" = emapper_kingdom, tiara_1, tiara_3)
    
    return(proc_gtf)
}

create_table1 <- function(kaiju_file, processed_gtf_file){
    
    proc_gtf <- read_gtf(processed_gtf_file)
        
    k <- read_kaiju(kaiju_file)
    
    table1 <- left_join(proc_gtf, k, by = "transcript") %>% 
        rename(scaffold = contig)
    
    return(table1)
}

args <- commandArgs(trailingOnly = T)

kaiju_file <- args[1]
processed_gtf_file <- args[2]
out_file <- args[3]

table1 <- create_table1(kaiju_file, processed_gtf_file)
write_tsv(table1, out_file)
