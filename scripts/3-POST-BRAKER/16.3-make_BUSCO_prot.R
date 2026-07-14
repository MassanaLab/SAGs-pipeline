#!/usr/bin/env Rscript

rm(list = ls())

# ---- libs ----
for (pkg in c("readr", "dplyr")) {
  if (!suppressWarnings(require(pkg, character.only = TRUE))) {
    stop(sprintf("Package '%s' is required but not installed.", pkg))
  }
}

# ---- args ----
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 1) {
  stop(
    "Usage: Rscript scripts/26.5-make_BUSCO_prot.R <W>\n",
    "Example: Rscript scripts/26.5-make_BUSCO_prot.R busco_prot_coass_guigo_filter3\n"
  )
}

W <- args[1]

data_dir <- sprintf("data/clean/%s_ess/all_reports", W)
busco_file <- file.path(data_dir, "busco_report.txt")
out_file <- sprintf("data/clean/%s_ess/BUSCO_%s_summary.tsv", W, W)

message(sprintf("[BUSCO] Reading report from: %s", busco_file))

# ---- checks ----
if (!file.exists(busco_file)) {
  stop(sprintf("Missing %s", busco_file))
}

# ---- read BUSCO report safely ----
busco_raw <- readr::read_tsv(
  busco_file,
  col_types = readr::cols(.default = readr::col_character())
)

if (ncol(busco_raw) < 9) {
  stop(sprintf("Expected ≥ 9 columns in %s, got %d", busco_file, ncol(busco_raw)))
}

# ---- keep only first 9 columns ----
busco_small <- busco_raw[, 1:9, drop = FALSE]

colnames(busco_small) <- c(
  "Sample",
  "X",
  "Results",
  "Complete",
  "Complete_single",
  "Complete_duplicated",
  "Fragmented",
  "Missing",
  "Total"
)

# ---- BUSCO summary ----
busco_summ <- busco_small %>%
  dplyr::transmute(
    Sample = Sample,
    `Complete BUSCOs` = as.numeric(Complete),
    `Complete and Single` = as.numeric(Complete_single),
    `Complete and Duplicated` = as.numeric(Complete_duplicated),
    `Fragmented BUSCOs` = as.numeric(Fragmented),
    `Missing BUSCOs` = as.numeric(Missing),
    `Total BUSCOs` = as.numeric(Total)
  ) %>%
  dplyr::mutate(
    `Completeness (%) (out of 255)` =
      round(100 * (`Complete BUSCOs` + `Fragmented BUSCOs`) / 255, 2),
    `Complete (%)` =
      round(100 * `Complete BUSCOs` / 255, 2),
    `Fragmented (%)` =
      round(100 * `Fragmented BUSCOs` / 255, 2),
    `Missing (%)` =
      round(100 * `Missing BUSCOs` / 255, 2)
  )

# ---- write ----
readr::write_tsv(busco_summ, out_file)

message(sprintf("[BUSCO] Wrote: %s", out_file))
message("[BUSCO] Done.")
