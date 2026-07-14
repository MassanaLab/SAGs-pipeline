library(tidyverse)

tab <- read_tsv('~/Downloads/coass_revisit_Table_genome_prediction_stats.tsv')

new_tab <- 
    tab |> 
    select(1:5) |> 
    pivot_longer(-1) |> 
    group_by(Species) |> 
    mutate(perc = 100*value/sum(value))



df_perc <- new_tab %>%
    filter(name %in% c("Exonic", "Intronic", "Intergenic")) %>%
    select(Species, name, perc) %>%
    pivot_wider(
        names_from = name,
        values_from = perc
    ) %>%
    rename(
        Percent_Exonic = Exonic,
        Percent_Intronic = Intronic,
        Percent_Intergenic = Intergenic
    )

write_tsv(df_perc, "percent_genome_annotation.tsv")
