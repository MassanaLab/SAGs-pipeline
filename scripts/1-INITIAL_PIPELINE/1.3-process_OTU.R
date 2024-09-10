library(tidyverse)
library(reshape2)
library(readr)
library(stringr)
library(readxl)
library(dplyr)

getwd()

seq_easig_sags_A105_otuTable <- read_delim("seq2_easig_sags_A105_otuTable.txt", 
                                           "\t", escape_double = FALSE, trim_ws = TRUE)

otu <- seq_easig_sags_A105_otuTable

#sapply(otu, class) 

otus_melt <- melt(seq_easig_sags_A105_otuTable)

names <- separate(otus_melt, OTUId,
                  into = c("taxa", "group", "supergroup"), sep = "_")

names$variable <- sapply(names$variable, as.character)
names$value <- sapply(names$value, as.integer)

names <- arrange(names, desc(value))

#base <- read.table("names2.txt", header = TRUE)

names <- names[,c(4,1,2,3,5)]
colnames(names) <- c("sample", "specie", "group", "supergroup", "mtags")

base <- names
nozero <- which(base$mtags != 0)
base <- base[nozero,] # keep only rows with value > 0

NAs <- which(base$group == "NA")
base <- base[-NAs,] # remove NAs in group column

bsort <- base[with(base, order(sample,-mtags)),]

#head(bsort)

#write.csv(bsort, "bsort2_og.csv")

## 3 LISTS ##

# CHARACTER LIST

lgroup <- list()

for (x in bsort$sample){
  g <- c()
  w <- which(bsort$sample == x)
  g <- append(g, as.character(bsort[w, "group"]))
  lgroup[[x]] <- g
}

#head(lgroup)

# MTAGS LIST

lmtags <- list()

for (x in bsort$sample){
  g <- c()
  w <- which(bsort$sample == x)
  g <- append(g, as.character(bsort[w, "mtags"]))
  lmtags[[x]] <- g
}

#head(lmtags)

# get list with row nums of each sample

l2 <- list()

for (x in bsort$sample){
  g <- c()
  w <- which(bsort$sample == x)
  g <- append(g, w)
  l2[[x]] <- g
  
}

###################
# NEW CLEAN TABLE #
###################

total_n <- length(unique(bsort$sample))
newdf2 <- data_frame(data.frame(matrix(nrow = 0, ncol = 0)))  

for(n in 1:total_n){
    
    sample <- unique(bsort$sample)[n]
    total_n <- length(unique(bsort$sample))
    
    x <- unique(lgroup[[n]])[1] 
        
    a <- l2[[n]][1]
    b <- l2[[n]][length(l2[[n]])]
        
    t <- which(bsort[a:b,"group"] == x)
          
    values <- bsort[a:b, "mtags"][t]
          
    suma <- sum(bsort[a:b,"mtags"][t])
    suma_total <- sum(bsort[a:b,"mtags"])
     
    purity <- round(100*suma/suma_total,1)
    
    len <- length(as.character(bsort[a:b, "specie"][t]))
            
    NAS <- which(is.na(as.character(bsort[a:b, "specie"][t])) == TRUE)
    
    nc <- c()
    
    for(g in unique(lgroup[[n]])[-1]){
        j <- which(bsort[a:b,"group"] == g)
        
        o <- bsort[a:b,"mtags"][j]
        
        p <- paste0(lgroup[[n]][j], "(", o, ")")
        
        nc <-  append(nc, p) 
    }
    
    rest_group <-  paste(nc, collapse=",")
    
    if (len > 1){
        
        if (is.na(as.character(bsort[a:b, "specie"][t][1]))){
            
            if(length(unique(lgroup[[n]])) > 1){
                if(unique(lgroup[[n]])[1] != unique(lgroup[[n]])[2]){
                    main_group <- unique(lgroup[[n]])[1]
                } else{
                    main_group <- unique(lgroup[[n]])
                    }
            } else{
                if(lgroup[[n]][1] != lgroup[[n]][2]){
                    main_group <- unique(lgroup[[n]])[1]
                } else{
                    main_group <- unique(lgroup[[n]])
                }
            }
        
        own <- values[2] 
        extra <- values[NAS][1]
        
        main_specie <- bsort[a:b, "specie"][t][2]
        
        c <- c()
        c <- append(c, c(sample, suma_total, main_group, suma, purity, main_specie, own, extra, rest_group))
        
        newdf2 <- rbind(newdf2, c)
        
    } else{
        
        main_group <- unique(lgroup[[n]])[1]
        
        own <- values[1] 
        extra <- values[NAS][1]
        
        main_specie <- bsort[a:b, "specie"][t][1]
        
        c <- c()
        c <- append(c, c(sample, suma_total, main_group, suma, purity, main_specie, own, extra, rest_group))
        
        newdf2 <- rbind(newdf2, c)
    }
        
    } else{
        main_group <- unique(lgroup[[n]])[1]
        
        own <- values[NAS][1]
        extra <- ""
        
        main_specie <- bsort[a:b, "specie"][t][1]
        
        c <- c()
        c <- append(c, c(sample, suma_total, main_group, suma, purity, main_specie, own, purity, rest_group))
        
        newdf2 <- rbind(newdf2, c)
    }
}

colnames(newdf2) <- c("sample", "mtags", "main_group", "total_group", "purity(%)", "main_specie", "own", "from_1st_NA", "other_groups")


#write_csv(newdf2, "seq2_table_clean_v2.csv")
