#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

# ---------------- args parsing ----------------
# Flags:
#   --base <keyword>   (default: og_coass_update)
#   --in   <path>      (override input)
#   --out  <path>      (override output)

args <- commandArgs(trailingOnly = TRUE)
opt <- list(base = "og_coass_update", `in` = NULL, out = NULL)

i <- 1
while (i <= length(args)) {
  a <- args[i]
  if (a %in% c("--base","-b")) {
    opt$base <- args[i+1]; i <- i + 2
  } else if (a %in% c("--in","-i")) {
    opt$`in` <- args[i+1]; i <- i + 2
  } else if (a %in% c("--out","-o")) {
    opt$out <- args[i+1]; i <- i + 2
  } else {
    stop(sprintf("Unknown argument: %s\nUse: --base <kw> [--in <path>] [--out <path>]", a))
  }
}

home <- path.expand("~")
if (is.null(opt$`in`)) {
  opt$`in` <- file.path(home, sprintf("lustre/qbt_%s_ess/all_reports/quast_report.txt", opt$base))
}
if (is.null(opt$out)) {
  opt$out <- file.path(home, sprintf("lustre/quast_%s_summary.tsv", opt$base))
}

if (!file.exists(opt$`in`)) stop(sprintf("Input not found: %s", opt$`in`))

# ---------------- read ----------------
quast <- readr::read_tsv(opt$`in`, progress = FALSE, col_types = readr::cols())

# Columns we need
needed <- c(
  "Sample",
  "# contigs (>= 1000 bp)", "# contigs (>= 3000 bp)", "# contigs (>= 5000 bp)",
  "Total length (>= 0 bp)", "Total length (>= 1000 bp)", "Total length (>= 3000 bp)", "Total length (>= 5000 bp)",
  "Largest contig", "GC (%)", "N50"
)
missing <- setdiff(needed, names(quast))
if (length(missing)) stop(sprintf("Missing expected columns in quast_report: %s", paste(missing, collapse = ", ")))

# ---------------- transform ----------------
out <- quast %>%
  mutate(
    `Mb (>= 0)`   = round(`Total length (>= 0 bp)`    / 1e6, 2),
    `Mb (>= 1k)`  = round(`Total length (>= 1000 bp)` / 1e6, 2),
    `Mb (>= 3kb)` = round(`Total length (>= 3000 bp)` / 1e6, 2),
    `Mb (>= 5kb)` = round(`Total length (>= 5000 bp)` / 1e6, 2)
  ) %>%
  transmute(
    Sample,
    `Mb (>= 0)`,
    `Mb (>= 1k)`,
    `Mb (>= 3kb)`,
    `Mb (>= 5kb)`,
    `contigs (>= 1k)` = `# contigs (>= 1000 bp)`,
    `contigs (>= 3k)` = `# contigs (>= 3000 bp)`,
    `contigs (>= 5k)` = `# contigs (>= 5000 bp)`,
    `Largest contig`,
    `GC (%)`,
    N50
  ) %>%
  arrange(Sample)

# Ensure output dir exists
dir.create(dirname(opt$out), showWarnings = FALSE, recursive = TRUE)
readr::write_tsv(out, opt$out)

message(sprintf("[QUAST] Base:   %s", opt$base))
message(sprintf("[QUAST] Input:  %s", opt$`in`))
message(sprintf("[QUAST] Output: %s", opt$out))
