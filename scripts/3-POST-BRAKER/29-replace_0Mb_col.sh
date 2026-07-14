#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

W <- "coass_update"  # CHANGE THIS if you reuse elsewhere

combined_path <- sprintf("lustre/QBT_%s_filters123_combined.tsv", W)
og_path       <- sprintf("lustre/quast_og_%s_summary.tsv", W)
out_path      <- sprintf("lustre/QBT_%s_filters123_mb0_swapped.tsv", W)

message("[CFG] W = ", W)
message("[IN ] combined: ", combined_path)
message("[IN ] og      : ", og_path)
message("[OUT] out     : ", out_path)

if (!file.exists(combined_path)) stop("Combined file not found: ", combined_path)
if (!file.exists(og_path))	 stop("OG file not found: ", og_path)

# Helper: robustly find 'Mb (>= 0 ...)'
find_mb0_col <- function(nms) {
  # matches "Mb (>= 0", with any number of spaces after >= and before 0
  hits <- grep("^Mb \\(>= *0\\b", nms, value = TRUE)
  if (length(hits) != 1) {
    stop("Could not uniquely identify 'Mb (>= 0 ...)' column. Found: ",
         paste(hits, collapse = ", "))
  }
  hits
}

combined <- readr::read_tsv(combined_path, progress = FALSE, col_types = cols())
og	 <- readr::read_tsv(og_path,	   progress = FALSE, col_types = cols())

if (!"Sample" %in% names(combined) || !"Sample" %in% names(og)) {
  stop("Both input files must have a 'Sample' column.")
}

mb0_combined_col <- find_mb0_col(names(combined))
mb0_og_col	 <- find_mb0_col(names(og))

# Build map & replace
mb0_map <- setNames(og[[mb0_og_col]], og$Sample)

old_vals <- combined[[mb0_combined_col]]
combined[[mb0_combined_col]] <- as.numeric(mb0_map[combined$Sample])

# keep originals when OG missing
na_idx <- which(is.na(combined[[mb0_combined_col]]))
if (length(na_idx)) {
  warning(sprintf("No OG Mb(>=0) for %d row(s); keeping original values. Samples: %s",
                  length(na_idx),
                  paste(unique(combined$Sample[na_idx]), collapse = ", ")))
  combined[[mb0_combined_col]][na_idx] <- old_vals[na_idx]
}

# ---------- write ----------
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
readr::write_tsv(combined, out_path)
message("[OK] Wrote: ", out_path)
