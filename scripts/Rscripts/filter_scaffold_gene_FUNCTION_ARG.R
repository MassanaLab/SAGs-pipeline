require(readr)
require(tidyr)
require(dplyr)
require(stringr)
require(gtools)

read_gtf <- function(processed_gtf_file){
    
    proc_gtf <- read_tsv(processed_gtf_file) %>% 
        select("scaffold" = contig, transcript)
    
    return(proc_gtf)
}


read_filter3 <- function(filter3){
    
    f3 <- read_tsv(filter3) %>% 
        select(scaffold)
    
    return(f3)
}

create_lj <- function(processed_gtf_file, filter3){
    
    gtf <- read_gtf(processed_gtf_file)
    
    f3 <- read_filter3(filter3)
    
    lj <-left_join(f3, gtf) %>% 
        na.omit() # HAGO NA OMIT PORQUE ENTRARN SCAFFOLDS QUE NO TIENEN GENES, PORQUE ENTRAN DESDE NEW_TIRA O DE FLON, osea que con filter3 me los quedo porque son buenos, pero no me interesan a la hora de pillar genes porque no tiene gen predicted ascoiado.
      
    return(lj)
}

args <- commandArgs(trailingOnly = T)

processed_gtf_file <- args[1]
filter3 <- args[2]
out_file <- args[3]

final_lj <- create_lj(processed_gtf_file, filter3)

write_tsv(final_lj, sprintf("%s_filter3_scaffold_gene_link.tsv", out_file))










