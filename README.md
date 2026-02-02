# SAGs Processing Pipeline

## 0. Important remark on array use for sample selection in SLURM scripts

In some scripts, you will see a line like this:

```
SAMPLE=$(cat <samples file> | awk "NR == ${SLURM_ARRAY_TASK_ID}")
```

Two important remarks:

1. `<samples file>` refers to a txt file that contains the names of all the samples you want to use in that particular script. In most cases, you will want to run the script with all samples, but in other cases you might select a subset of samples that you are interested in and run the script with those. The file should look like this:

```
GC1003827_A03
GC1003827_A05
GC1003827_A06
GC1003827_A07
GC1003827_A10
GC1003827_A12
GC1003827_B04
GC1003827_B05
GC1003827_B06
GC1003827_B08
...
```

2. The whole line is used to define the variable **"SAMPLE"**. What we are doing is linking each sample inside the `<samples file>` to an array number (defined in `#SBATCH --array=1-x1%x2`, inside the script' header). This will run as many "copies" of our script as we define in `x1` (and will run x2 scripts at the same time), but every copy will have a different name inside the **SAMPLE** variable. So every time **SAMPLE** appears in the script, it will be one of the names inside the `<samples file>`. So if the script is running with array 3, **SAMPLE** will be the name in the third line of the `<samples file>`, _GC1003827_A06_ if we use the previous example.

## 1. Preprocessing of raw reads

### 1.1 SeqKit: General statistics of raw reads

Checks general statistics of raw files.

[0.1-seqkit_stats.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/0.1-seqkit_stats.sh)


### 1.2 Trim Galore: Adapter removal and read trimming according to quality

Automatically detects and removes adapter sequences from reads. It supports single-end and paired-end sequencing data.
Uses Cutadapt for the actual trimming process, ensuring flexibility and reliability.

`--paired` indicates that we have paired-end sequencing data, that is forward and reverse reads. In this line, we just need to indicate which are the pairs. In our case, they are differentiated by R1 and R2 inside the reads name (R1 = forward, R2 = reverse). Notice

`--length` sets the minimum length for retaining reads after trimming. In our case, we put 75.

[0.2-trimgalore.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/0.2-trimgalore.sh)


### 1.3 Seqkit: Post-Trimming Quality Check

Just repeat SeqKit but now for the trimmed reads. Check that the trimming has been properly done.

[0.3-seqkit_stats_clean.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/0.3-seqkit_stats_clean.sh)

### 1.4 Merging sequencing replicates (if needed)

In the case of having several sequencing repetitions for each SAG, we need to concatenate all reads that should go together.

[0.5-concatenate.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/0.5-concatenate.sh)

## 2. Taxonomic Assignment Using mTags (18S-V4 Region)

Check the general taxonomy of your reads using 18S-V4 fragments (mTags).

### 2.1 BLAST-based extraction of 18S-V4 fragments

[1.1-extraction_blast.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/1.1-extraction_blast.sh)

Performs a basic BLAST of your reads against the eukaryotesV4 blast database. Generates mTags, which show the specific sequence of the hits.

Result: 
-data/clean/extraction_blast/* 
*.hits = “identification code” of the hits
*.blast = “identification code” + specie_group_supergroup + data

-data/clean/mtags/*.mtags.fna = “id code” with its entire sequence

### 2.2 mTag classification and OTU table generation

[1.2-mtags_classification.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/1.2-mtags_classification.sh)

Generates OTU table. Some additional R scripts are needed to clean and sort the table so it becomes more readable and has a better format for later analyses. 

Result: data/clean/mtags/easig_sags_A105_mtags.fasta & easig_sags_A105_otuTable.txt

### 2.3 Process OTU table

[1.3-UPDATED_process_OTU.R](scripts/1-INITIAL_PIPELINE/1.3-UPDATED_process_OTU.R) 

The resulting `.csv` file summarizes the OTU table using the following columns.

| Column           | Description                                                                     |
| ---------------- | ------------------------------------------------------------------------------- |
| `sample`         | Sample identifier (from input table column names).                               |
| `mtags`          | Total number of tags (OTU counts) detected in that sample.                       |
| `main_group`     | Most abundant taxonomic group in the sample (based on summed `mtags`).           |
| `total_group`    | Total number of tags assigned to `main_group`.                                   |
| `purity(%)`      | Proportion of `mtags` from `main_group` over total tags, as a percentage.        |
| `main_specie`    | Representative species of the `main_group` (the most abundant non-NA OTU).       |
| `main_OTU_mtags` | Number of tags assigned to the representative OTU of `main_group`.              |
| `other_groups`   | Comma-separated list of other groups detected, with their respective tag counts.|


## 3. Genome Assembly

### 3.1 SPAdes

[spades_127_sel252.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/1-INITIAL_PIPELINE/spades_127_sel252.sh)

Unify forward and reverse sequences to obtain the whole genome.

Result: data/clean/assembly/*, inside each sample, find contigs and scaffolds.

## 4. Post-Assembly Quality Assessment

### 4.1 Run QUAST, BUSCO, and Tiara (QBT)

QUAST (Quality Assessment Tool for Genome Assemblies): evaluate the quality of the assembly.

BUSCO (Benchmarking Universal Single-Copy Orthologs): given a database of eukaryote genes, BUSCO searches them inside our assemblies. Then computes how many of them were found, and if they were found complete or fragmented.

Tiara: a deep-learning-based approach for the classification of sequences into eukarya, bacteria, archaea, organelle...

All information on how to run QBT [here](https://github.com/MassanaLab/QBT-pipeline).

## 5. Gene prediction with BRAKER

### 5.1 Prerequisites: GeneMark license and database download

1. Download GeneMark license (GeneMark-ES/ET/EP+ ver 4.72_lic): http://topaz.gatech.edu/GeneMark/license_download.cgi
2. Send it to your cluster `home` directory via `scp`.
3. Do `gunzip`.
4. Rename it to to .gm_key.

```
mv <license file> .gm_key
```

5. Download the database for **BRAKER**.

```
wget  https://bioinf.uni-greifswald.de/bioinf/partitioned_odb11/Eukaryota.fa.gz
```
### 5.2 BRAKER

Here is a general ideal script for **BRAKER**. Notice how in `cd $LUSTRE_SCRATCH` it's changing the directory to this `LUSTRE_SCRATCH` kinda limbo space and it will create a folder for each sample. Inside this folder is where all the files (lots of files) will be generated. In the end, if everything is finished well, the most important files (_.aa_, _.codingseq_, _.gtf_, _.log_) will be copied to folders in `lustre`, where they are accessible. 

[braker_general.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/2-BRAKER/braker_general.sh)

However, it's really common for some samples to fail. In that case, we don't want **BRAKER** to write things in LUSTRE_SCRATCH because we want to be able to see what is going on. Here is a modified script just for those cases where we don't want to use `LUSTRE_SCRATCH`. It's nothing special, just a script where some lines are commented.

[braker_redo.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/2-BRAKER/braker_redo.sh)

Notice how the script starts with `N=10`. That's the iteration number. Due to the failures, Aleix Obiol discovered a way to fix the problem. It essentially consists of finding the corrupted _nuc\*prot\*_ files inside the **Spaln** folder that **BRAKER** generates. This _nuc\*prot\*_ file has some numbers that are related to proteins inside the database. With the following script, we can remove those proteins that are being problematic and create a new database without them. So each new database will have its iteration number `N` to be used in the `braker_redo.sh` script.

[ALEIX_BRAKER_Spaln_solution_seqkit_grep_remove.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/2-BRAKER/ALEIX_BRAKER_Spaln_solution_seqkit_grep_remove.sh)

After you have braker results. I use this script to organize the outputs:

[rename_and_organize.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/2-BRAKER/rename_and_organize.sh)

## 6. BRAKER Gene Predictions Processing

After running BRAKER to predict genes on each SAG assembly, we applied a three-step post-processing pipeline to clean headers, standardize annotation files, filter gene models, and generate the final curated FAA and GFF3 outputs.

The first step is to prepare a clean, standardized dataset for all SAGs before applying any filtering. This script ensures that every sample has a clean assembly and GTF with matching contig headers, which is essential before running gene-length filtering.

[1-build_ingredients_and_clean_headers.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/1-build_ingredients_and_clean_headers.sh)

Then we proceed with the processing of each gtf file. The following script produces high-confidence, longest-isoform, ≥50 aa gene sets for each sample.

[2-process_gtf_filter1.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/2-process_gtf_filter1.sh)

Finally, we collect all processed results and produce the final curated gene datasets.

[3-final_gff_final_faa.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/3-final_gff_final_faa.sh)

## 7. Gene annotation

Here is the post-braker pipeline, specially designed and refined for the Leuven SAGs.

### 7.1 Functional annotation with EggNOG-mapper

Here we use EggNOG-mapper for functional annotation of genes. It uses its own database, which contains orthologous groups and functional annotations, to assign functions to sequences based on homology. 

[4-eggnog_mapper+skip4.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/4-eggnog_mapper+skip4.sh)

In this script, I create a singular file for each sample. It is inside this file where EggNOG-mapper will create 3 files:

-*.annotations

-*.hits

-*.seed_orthologs

All 3 files are interesting but in our case, we only focus on the `.anotations` one. If you open it with Excel you will see a big file with lots of data. Don't worry, in the following steps, we will be cleaning and selecting only those rows that are useful to us. But since the first 5 lines on the `.anotations` file are very annoying, we start by removing them and putting all clean eggnog files in the same folder.


### 7.2 Taxonomic Annotation with Kaiju

To add more taxonomic information about each SAG we use Kaiju, which takes our genes from **BRAKER** and assigns them a taxonomy according to its database. Notice that in _CESGA_ and _Marbits_ the database is already downloaded and placed somewhere. If you don't know where it is, it is highly recommended for you to ask, because the database is huge and it will take too much time to download and will occupy too much space in your cluster.

The script is simple, just provide the location of the genes from **BRAKER** and the location of the database.

[5-kaiju_faa+grep_C.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/5-kaiju_faa+grep_C.sh)

The script creates single files for each sample so Kaiju can write its 3 output files:

-*_kaiju_faa.out

-*_kaiju_faa_names.out

-*_kaiju_faa_summary.tsv

We will only need *_kaiju_faa_names.out for this pipeline but the other files can also be useful for other purposes.

In the same script we also filter out those rows (genes) from `*_kaiju_faa.out` that ended up unclassified (U), so we only keep those that were classified (C). This step should not be necessary but I encountered problems in R when reading files that started with an unclassified gene.  That is because if the row is U it will only have 3 columns, while if the column is C it has more columns. So if the first line of a file has 3 columns, R will read 3 columns and will understand that the whole table will be 3 columns, but it will not because the C rows have more columns and they will not fit in a table that is already stated to have 3 columns. It is a bit of a messy situation and the only way I found to correct this is to just do this simple filter with `grep`:


## 8. Removing small contigs and contigs with prokaryotic signal 

### 8.1 Preparing gene annotations files

#### 8.1.1 GTF file cleaning and transcript selection

Then, using this script from @aleixop we will clean up the `.gtf` files from **BRAKER** and merge the information we have from **Tiara** and **EggNOG**.

The cleaning of the `.gtf` files is essentially choosing one transcript per gene. Notice how in `.gtf` files we can have more than one transcript for each gene (they are named as _.t1_, _.t2_, _.t3_...) and it becomes really annoying, so with this script we are just keepping longest transcript to make this easier.

[7.1-GFF_use_ALEIX_get_prediction_stats.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/3-use_ALEIX_get_prediction_stats.sh)

Then we can check if gene counts are consistent between files and everything went according to plan. It justs compares how many protein sequences there are in the FASTA file (\*_filter1_genes.faa) and how many gene rows there are in the corresponding processed table (\*_gff_processed.txt (lines minus the header)).

[ALEIX_get_prediction_stats.R](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/Rscripts/ALEIX_get_prediction_stats.R)

[7.2-check_GFF3_vs_FAA.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/7.2-check_GFF3_vs_FAA.sh)



#### 8.1.2 Merge GTF + EggNOG + Kaiju annotations

The last step in this block will be to merge together the results from the [**gtf file processing**](https://github.com/gmafer/SAGs-pipeline/wiki/SAGs-Alacant-Pipeline#gtf-file-cleaning) step (where we merged gtf & EggNOG) and the result from Kaiju.

Again, very simple script: just make sure to input the `grep_C` Kaiju files from the previous step and the processed gtf files.

[8-use_kaiju_process_TABLE1_FUNCTIONS_ARG.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/8-use_kaiju_process_TABLE1_FUNCTIONS_ARG.sh)

[kaiju_process_TABLE1_FUNCTIONS_ARG.R](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/Rscripts/kaiju_process_TABLE1_FUNCTIONS_ARG.R)

#### 8.1.3 Identify Tiara-only scaffolds without predictions

The first step would be to find those scaffolds that have Tiara information but **BRAKER** was not able to predict any genes inside them. We are very sure of Tiara's results so we want to keep these scaffolds, it does not matter what **BRAKER** says.

[9-process_leftovers_new_tiara_leuven.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/9-process_leftovers_new_tiara_leuven.sh)


### 8.2 Filtering genome assemblies

Now we will start with the process of filtering out those scaffolds from our SAG that are considered to be prokaryotes. 

#### 8.2.1 Apply 3 filters

These leftover (lo) scaffolds need to be included inside the tables where we have all the information, so we just add them with their corresponding Tiara information.

The following script will also perform 3 filters:

1. Filter out scaffolds smaller than 1000bp
2. Filter out those scaffolds larger than 3000bp that are considered by Tiara to be _bacteria_, _archaea_, or _prokarya_.
3. Filter out scaffolds in the range of 1000-3000bp that have **any** hints (EggNOG & Kaiju instances) of being _eukaryotes_ and have **some** (more than 0) hints of being _prokaryotes_.


[10-use_kaiju_process_FUNCTIONS_ARG.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/10-use_kaiju_process_FUNCTIONS_ARG.sh)

[kaiju_process_FUNCTIONS_ARG_old_pipe.R](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/Rscripts/kaiju_process_FUNCTIONS_ARG_old_pipe.R)

#### 8.2.2 Select scaffolds to keep after the 3 filtering

Once we have our 3 filters, we can use `seqkit grep` to grab the names of the selected scaffolds to be kept.

[11.1-seqkit_greps_leuven.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/11.1-seqkit_greps_leuven.sh)

[11.2-quick_filters_report.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/11.2-quick_filters_report.sh)

### 8.3 Reporting clean assemblies

#### 8.3.1 QUAST, BUSCO, Tiara (QBT)

**1. Run QBT on filtered assemblies and clean unnecessary files**

Then we can do a QBT analysis (explained before).

Notice the `N=x` variable. Indicate there to which filter (1, 2, or 3) you want to do QBT.

[12-QBT_filterx+cleanning.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/12-QBT_filterx+cleanning.sh)

**2. Generate reports**

[14-QBT_report.sh](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/14-QBT_report.sh)

**3. Summarize filtered QBT results**

*on your computer*

Move the 3 `all_repotsx` files to a folder in your computer and execute this script in R:

[QBT_LEUVEN_summary_final_filters.R](https://github.com/gmafer/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/QBT_LEUVEN_summary_final_filters.R)

*on hpc cluster*

[15-make_QBT_summary_filters.R](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/15-make_QBT_summary_filters.R)

## POST FILTER 3

Here we repeat the same process applied on filter1 genomes, but now with filter3 genomes.

[16-braker3_post_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/16-braker3_post_filter3.sh)

[17-rename_and_organize.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/17-rename_and_organize.sh)

[18-build_ingredients_and_clean_headers_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/18-build_ingredients_and_clean_headers_filter3.sh)

[19-process_gtf_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/19-process_gtf_filter3.sh)

[20-final_gff_final_faa_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/20-final_gff_final_faa_filter3.sh)

[21-eggnog_mapper_filter3+skip4.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/21-eggnog_mapper_filter3%2Bskip4.sh)


[22.1-GFF_use_ALEIX_get_prediction_stats_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/22.1-GFF_use_ALEIX_get_prediction_stats_filter3.sh)

[22.2-check_GFF3_vs_FAA_filter3.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/22.2-check_GFF3_vs_FAA_filter3.sh)

[23-genes_filter50_100_200.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/23-genes_filter50_100_200.sh)

[24-gene_count50_100_200.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/24-gene_count50_100_200.sh)

[25-og_QUAST+cleanning.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/25-og_QUAST%2Bcleanning.sh)

[26-og_new_QUAST_report.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/26-og_new_QUAST_report.sh)

[27-quast_only_summary.R](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/27-quast_only_summary.R)

[28-replace_0Mb_col.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/28-replace_0Mb_col.sh)

[29.1.1-filter1_initial.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/29.1.1-filter1_initial.sh)

[29.1.2-filter3_initial.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/29.1.2-filter3_initial.sh)

[29.2-interproscans.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/29.2-interproscans.sh)

[29.3-excluded.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/29.3-excluded.sh)

[29.4-made_withs.sh](https://github.com/MassanaLab/SAGs-pipeline/blob/main/scripts/3-POST-BRAKER/29.4-made_withs.sh)
