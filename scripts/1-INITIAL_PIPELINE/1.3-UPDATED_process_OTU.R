library(tidyverse)
library(reshape2)

# Load and melt the OTU table
otu <- read_delim("seq2_easig_sags_A105_otuTable.txt", delim = "\t", trim_ws = TRUE)
otus_melt <- melt(otu)

# Split OTU ID into columns
otus_melt <- separate(otus_melt, OTUId, into = c("specie", "group", "supergroup"), sep = "_")

# Clean and arrange
otus_melt <- otus_melt %>%
    rename(sample = variable, mtags = value) %>%
    mutate(mtags = as.integer(mtags)) %>%
    filter(mtags > 0, group != "NA") %>%
    arrange(sample, desc(mtags))

# Prepare output list
samples <- unique(otus_melt$sample)
results <- list()

# Loop through each sample
for (s in samples) {
    df <- otus_melt %>% filter(sample == s)
    lgroup <- as.character(df$group)
    lspec  <- as.character(df$specie)
    lmtags <- df$mtags
    
    main_group <- lgroup[1]
    main_rows <- which(lgroup == main_group)
    values <- lmtags[main_rows]
    
    suma <- sum(values)
    suma_total <- sum(lmtags)
    purity <- round(100 * suma / suma_total, 1)
    
    NAS <- which(is.na(lspec[main_rows]))
    
    # Compose 'other_groups'
    rest_group <- ""
    if (length(unique(lgroup)) > 1) {
        rest_group <- unique(lgroup)[-1] %>%
            map(~ {
                idx <- which(lgroup == .x)
                paste0(.x, "(", lmtags[idx], ")")
            }) %>%
            unlist() %>%
            paste(collapse = ",")
    }
    
    main_OTU_mtags <- NA
    extra <- NA
    main_specie <- NA
    
    if (length(main_rows) > 1) {
        if (is.na(lspec[main_rows][1])) {
            if (length(values) >= 2) main_OTU_mtags <- values[2]
            if (length(NAS) > 0) extra <- values[NAS[1]]
            main_specie <- lspec[main_rows][2]
        } else {
            main_OTU_mtags <- values[1]
            if (length(NAS) > 0) extra <- values[NAS[1]]
            main_specie <- lspec[main_rows][1]
        }
    } else {
        if (length(NAS) > 0) {
            main_OTU_mtags <- values[NAS[1]]
        } else {
            main_OTU_mtags <- values[1]
            main_specie <- lspec[main_rows][1]
        }
    }
    
    results[[s]] <- tibble(
        sample = s,
        mtags = suma_total,
        main_group = main_group,
        total_group = suma,
        `purity(%)` = purity,
        main_specie = main_specie,
        main_OTU_mtags = main_OTU_mtags,
        other_groups = rest_group
    )
}

# Combine and write
final_df <- bind_rows(results)
write_csv(final_df, "UPDATED_seq2_table_clean_v2.csv")
