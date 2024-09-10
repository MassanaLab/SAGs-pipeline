
require(readr)
require(tidyr)
require(dplyr)
require(stringr)
require(gtools)


read_kaiju <- function(kaiju_file){
    
    col_names <- c("V1", "V2", "V3", "V4")
    
    k <- read.table(kaiju_file, fill = TRUE, sep = "\t", header = FALSE, col.names = col_names) %>%
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

read_new_tiara <- function(new_tiara_file){
    
    new_tiara <- read_tsv(new_tiara_file, col_names = c("scaffold", "tiara")) %>% 
        select(scaffold, tiara)
    
    return(new_tiara)
}


read_flon_file <- function(flon_file){
    
    flon <- read_tsv(flon_file, col_names = "scaffold")
    
    return(flon)
}




create_table5 <- function(kaiju_file, processed_gtf_file, new_tiara_file, flon_file){
    
    proc_gtf <- read_gtf(processed_gtf_file)
        
    k <- read_kaiju(kaiju_file)
    
    table1 <- left_join(proc_gtf, k, by = "transcript") %>% 
        rename(scaffold = contig)
    
    table2_Kaiju <- 
        table1 %>% 
        select(scaffold, Kaiju) %>%
        mutate(across(everything(), ~na_if(., ""))) %>%
        replace_na(list(Kaiju = "NA")) %>% 
        group_by(scaffold, Kaiju) %>%
        summarise(count = n()) %>%
        spread(Kaiju, count, fill = 0) %>% 
        mutate(numeric_part = as.numeric(sub("^NODE_(\\d+).*", "\\1", scaffold))) %>%
        arrange(numeric_part) %>%
        select(-numeric_part) %>% 
        rename_with(~if_else(. == "scaffold", ., paste0("K_", .)), -scaffold)
    
    table2_eggNOG <- 
        table1 %>% 
        select(scaffold, eggNOG) %>%
        mutate(across(everything(), ~na_if(., ""))) %>%
        replace_na(list(eggNOG = "NA")) %>% 
        group_by(scaffold, eggNOG) %>%
        summarise(count = n()) %>%
        spread(eggNOG, count, fill = 0) %>% 
        mutate(numeric_part = as.numeric(sub("^NODE_(\\d+).*", "\\1", scaffold))) %>%
        arrange(numeric_part) %>%
        select(-numeric_part) %>% 
        rename_with(~if_else(. == "scaffold", ., paste0("E_", .)), -scaffold)
    
    split_df <- as.data.frame(do.call(rbind, str_split(table2_eggNOG$scaffold, "_")))
    
    # Check if columns are present, add missing columns filled with zeros

    # this how i want my columns
    k_cols <- c("scaffold", "K_Archaea", "K_Bacteria", "K_Eukaryota", "K_NA", "K_Viruses")
    e_cols <- c("scaffold", "E_Archaea", "E_Bacteria", "E_Eukaryota", "E_NA", "E_Viruses")

    if (!all(k_cols %in% colnames(table2_Kaiju))) {
      missing_cols <- setdiff(k_cols, colnames(table2_Kaiju))
      for (col in missing_cols) {
        table2_Kaiju[[col]] <- 0
      }
    }

    if (!all(e_cols %in% colnames(table2_eggNOG))) {
      missing_cols <- setdiff(e_cols, colnames(table2_eggNOG))
      for (col in missing_cols) {
        table2_eggNOG[[col]] <- 0
      }
    }


    
    table3 <- left_join(table2_Kaiju, table2_eggNOG) %>% 
        ungroup() %>% 
        select(-contains("NA"), -scaffold)
    
    ct <- 
        table1 %>% 
        select(scaffold, start_codon, stop_codon) %>% 
        group_by(scaffold) %>%
        summarize(
            count = n(),
            yes_yes_count = sum(start_codon == "yes" & stop_codon == "yes"),
            completeness = round((yes_yes_count / count) * 100)) %>% 
        mutate(numeric_part = as.numeric(sub("^NODE_(\\d+).*", "\\1", scaffold))) %>%
        arrange(numeric_part) %>%
        select(-numeric_part) %>% 
        select(scaffold, completeness)
    
    table4 <- 
        table3 %>% 
        mutate(
            completeness = ct$completeness,
            total_NA = table2_eggNOG$E_NA + table2_Kaiju$K_NA,
            total_nonNA = rowSums(table3),
            sum_Euk = K_Eukaryota + E_Eukaryota, 
            sum_Prok = K_Bacteria + E_Bacteria + K_Archaea + E_Archaea,
            perc_Euk = round(100*sum_Euk/total_nonNA, 0),
            perc_Prok = round(100*sum_Prok/total_nonNA, 0),
            scaffold = table2_eggNOG$scaffold,
            length = as.numeric(split_df$V4)
        ) %>% 
        select(scaffold, length, completeness, total_nonNA, total_NA, sum_Euk, sum_Prok, perc_Euk, perc_Prok) 
    
    tiara <- 
        proc_gtf %>%
        group_by(contig, tiara_1) %>% 
        summarise() %>% 
        mutate(numeric_part = as.numeric(sub("^NODE_(\\d+).*", "\\1", contig))) %>%
        arrange(numeric_part) %>%
        select("scaffold" = contig, "tiara" = tiara_1)
    
    
    new_tiara <- read_new_tiara(new_tiara_file) 
    
    split_df_nt <- as.data.frame(do.call(rbind, str_split(new_tiara$scaffold, "_")))
    
    new_tiara_len <- new_tiara %>% 
        mutate(length = as.numeric(split_df_nt$V4))
    
    flon <- read_flon_file(flon_file)
    
    split_df_flon <- as.data.frame(do.call(rbind, str_split(flon$scaffold, "_")))
    
    flon_len <- flon %>% 
        mutate(length = as.numeric(split_df_flon$V4))
    
    if (nrow(new_tiara) > 0) {
        
        flon_len_tiara <- left_join(flon_len, new_tiara_len)
        
        table5 <- left_join(table4, tiara) %>% 
            mutate(across(where(is.numeric), ~ ifelse(is.nan(.), 0, .))) %>% 
            bind_rows(flon_len_tiara)
        
    } else {
        
        table5 <- left_join(table4, tiara) %>% 
            mutate(across(where(is.numeric), ~ ifelse(is.nan(.), 0, .))) %>% 
            bind_rows(flon_len)
    }
    
    return(table5)
    
}

create_table6_filter1 <- function(table5){
    
    table6_filter1 <- table5 %>%
        filter(!(length < 1000))
    
    return(table6_filter1)
}

create_table6_filter2 <- function(table6_filter1){
    
    table6_filter2 <- 
        table6_filter1 %>%
        filter(!(length >= 3000 & (tiara == "bacteria" | tiara == "archaea" | tiara == "prokarya")))  
    
    return(table6_filter2)
}

create_table6_filter3 <- function(table6_filter2){
    
    table6_filter3 <-
        table6_filter2 %>%
        filter(!(length < 3000 & (perc_Euk == 0 & perc_Prok > 0)) | is.na(perc_Euk) | is.na(perc_Prok))
    
    return(table6_filter3)
}



args <- commandArgs(trailingOnly = T)

kaiju_file <- args[1]
processed_gtf_file <- args[2]
new_tiara_file <- args[3]
flon_file <- args[4]
out_file <- args[5]

table5 <- create_table5(kaiju_file, processed_gtf_file, new_tiara_file, flon_file)

table6_filter1 <- create_table6_filter1(table5)
table6_filter2 <- create_table6_filter2(table6_filter1)
table6_filter3 <- create_table6_filter3(table6_filter2)


write_tsv(table6_filter1, sprintf("%s_table6_filter1.tsv", out_file))
write_tsv(table6_filter2, sprintf("%s_table6_filter2.tsv", out_file))
write_tsv(table6_filter3, sprintf("%s_table6_filter3.tsv", out_file))
