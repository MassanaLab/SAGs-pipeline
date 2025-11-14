#!/usr/bin/env Rscript

rm(list = ls())

# ---- libs (stop if missing) ----
for (pkg in c("readr","dplyr","tidyr","readxl")) {
  if (!suppressWarnings(require(pkg, character.only = TRUE))) {
    stop(sprintf("Package '%s' is required but not installed.", pkg))
  }
}

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
})

# -------------------- args --------------------
args <- commandArgs(trailingOnly = TRUE)
Wbase   <- if (length(args) >= 1) args[1] else "full_remake"
filters <- if (length(args) >= 2) as.integer(args[-1]) else c(1L,2L,3L)
if (!length(filters) || any(!filters %in% c(1L,2L,3L))) {
  stop("Filters must be chosen from {1,2,3}. Example: Rscript ... full_remake 1 2 3")
}

home <- path.expand("~")

# ---- helper: build one filter summary ----
build_one_filter <- function(f) {
  ess_dir   <- file.path(home, sprintf("lustre/qbt_%s_filter%d_ess", Wbase, f))
  data_dir  <- file.path(ess_dir, sprintf("all_reports%d", f))
  out_file  <- file.path(ess_dir, sprintf("QBT_%s_filter%d_summary.tsv", Wbase, f))

  message(sprintf("[QBT] Filter %d | Reading reports from: %s", f, data_dir))

  # --- read inputs ---
  quast_file <- file.path(data_dir, "quast_report.txt")
  busco_file <- file.path(data_dir, "busco_report.txt")
  tiara_file <- file.path(data_dir, "tiara_report.txt")

  if (!file.exists(quast_file)) stop(sprintf("Missing %s", quast_file))
  if (!file.exists(busco_file)) stop(sprintf("Missing %s", busco_file))
  if (!file.exists(tiara_file)) stop(sprintf("Missing %s", tiara_file))

  # ---- COMPATIBLE reads (works with old/new readr) ----
  quast <- readr::read_tsv(quast_file, progress = FALSE, col_types = readr::cols())
  busco <- readr::read_tsv(busco_file, progress = FALSE, col_types = readr::cols())
  tiara <- readr::read_tsv(tiara_file,
                           col_names = c("Sample","tiara"),
                           progress = FALSE,
                           col_types = readr::cols())

  # ---- TIARA reshape ----
  tiara <- tiara %>%
    tidyr::separate(tiara, sep = ": ", into = c("tax","n")) %>%
    dplyr::mutate(n = as.numeric(n)) %>%
    dplyr::group_by(Sample, tax) %>%
    dplyr::summarise(n = sum(n), .groups = "drop") %>%
    tidyr::pivot_wider(names_from = tax, values_from = n, values_fill = 0) %>%
    dplyr::mutate(dplyr::across(where(is.numeric), ~round(., 1))) %>%
    dplyr::select(
      Sample,
      dplyr::everything(),
      -dplyr::any_of("organelle")
    ) %>%
    dplyr::rowwise() %>%
    dplyr::mutate(
      all_tiara = sum(c_across(where(is.numeric)), na.rm = TRUE),
      `%-euk` = round(100 * ifelse("eukarya" %in% names(.), eukarya / all_tiara, 0), 1),
      `%-prok` = round(
        100 * sum(c_across(tidyselect::matches("bacteria|prokarya|archaea")), na.rm = TRUE) / all_tiara, 1
      )
    ) %>%
    dplyr::ungroup() %>%
    dplyr::select(
      Sample,
      `%-euk`,
      `%-prok`,
      dplyr::any_of(c("eukarya","bacteria","archaea","prokarya","unknown","mitochondrion","plastid")),
      all_tiara
    )

  # ---- base table skeleton ----
  base <- data.frame(matrix(NA, nrow = nrow(quast), ncol = 16))
  colnames(base) <- c(
    "Sample","Mb (>= 0 )","Mb (> =1k)","Mb (>= 3kb)","Mb (>= 5Kb)",
    "contigs (>= 1Kb)","contigs (>= 3Kb)","contigs (>= 5Kb)",
    "Largest contig","GC (%)","N50",
    "Complete BUSCOs","Complete and Single","Complete and Duplicated","Fragmented BUSCOs",
    "Completeness (%) (out of 255)"
  )

  # ---- QUAST mapping ----
  base$Sample <- quast$Sample
  base[2:5] <- round(quast[7:10] / 1e6, 2)
  base[6:8] <- quast[4:6]
  base$`Largest contig` <- quast$`Largest contig`
  base$`GC (%)` <- quast$`GC (%)`
  base$N50 <- quast$N50

  # ---- BUSCO (defensive rename) ----
  new_names <- c(
    "Sample","X","Results","Complete","Complete and Single",
    "Complete and Duplicated","Fragmented","Missing","X2","X3","X4"
  )
  length(new_names) <- ncol(busco)
  colnames(busco) <- new_names

  base$`Complete BUSCOs`         <- busco$Complete
  base$`Complete and Single`     <- busco$`Complete and Single`
  base$`Complete and Duplicated` <- busco$`Complete and Duplicated`
  base$`Fragmented BUSCOs`       <- busco$Fragmented
  base$`Completeness (%) (out of 255)` <- round(100 * (base$`Complete BUSCOs` + base$`Fragmented BUSCOs`) / 255, 2)

  # ---- merge TIARA + fill NA -> 0 ----
  base2 <- dplyr::left_join(base, tiara, by = "Sample")
  base2[is.na(base2)] <- 0

  # ---- write per-filter ----
  readr::write_tsv(base2, out_file)
  message(sprintf("[QBT] Filter %d | Wrote: %s", f, out_file))

  # return with filter tag for combined
  base2 %>% mutate(filter = f, .before = 1)
}

# -------------------- run --------------------
res_list <- lapply(filters, build_one_filter)
combined <- dplyr::bind_rows(res_list) %>%
  dplyr::mutate(filter = factor(filter, levels = sort(unique(filter)))) %>%
  dplyr::arrange(Sample, filter)

combined_out <- file.path(home, sprintf("lustre/QBT_%s_filters123_combined.tsv", Wbase))
readr::write_tsv(combined, combined_out)
message(sprintf("[QBT] Combined table written: %s", combined_out))
message("[QBT] Done.")
