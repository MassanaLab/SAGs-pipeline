#### Input ####

args = commandArgs(trailingOnly=TRUE)

if (length(args) < 3) {
  stop("Error! Falten arguments:
       1) Species name
       2) GFF
       3) Genome fasta", call.=FALSE)
} else {
  si=args[1]
  gi_fn=args[2]
  fa_fn=args[3]
}

# load libraries
library(plyr)
library(ape)
library(Rsamtools)
library(tidyr)
library(zoo)
library(data.table)
library(ggplot2)

exon_name="CDS"
gene_name="gene"
mRNA_name="transcript"

# load

print(paste(si,"load..."))

gi = read.gff(gi_fn)
indexFa(fa_fn)
fx = read.table(paste(fa_fn,".fai",sep=""))
colnames(fx) = c("chr","length","offset","linebases","linewidth")

# # load FASTA
fa = FaFile(fa_fn)
fi = getSeq(fa)


#### Add attributes ####

gi$attributes = gsub("ID=","",gi$attributes)
gi$attributes = gsub("Parent=","",gi$attributes)
gi$attributes = gsub("agat-.*;","",gi$attributes)
gi$attributes = gsub("transcript_id=","",gi$attributes)
gi$attributes = gsub(";.*","",gi$attributes)
gi = subset(gi, type %in% c(exon_name,mRNA_name))
levels(gi$type)[levels(gi$type)==exon_name] = "exon"
levels(gi$type)[levels(gi$type)==mRNA_name] = "gene"
gi = gi[order(gi[,"seqid"],gi[,"start"]),]
gi$source = "R"

#### Exon&intron table ####

giex = subset(gi, type %in% "exon")
giex = giex[order(giex[,"seqid"],giex[,"start"]),]

# add introns upstream downstream
giex$in1s = ifelse(giex$strand == "+",
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1),data.table::shift(giex$end,1)+1,NA),
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1,type="lead"),giex$end+1,NA))
giex$in1e = ifelse(giex$strand == "+",
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1),giex$start-1,NA),
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1,type="lead"),data.table::shift(giex$start,1,type="lead")-1,NA))
giex$in2s = ifelse(giex$strand == "+",
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1,type="lead"),giex$end+1,NA),
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1),data.table::shift(giex$end,1)+1,NA))
giex$in2e = ifelse(giex$strand == "+",
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1,type="lead"),data.table::shift(giex$start,1,type="lead")-1,NA),
                   ifelse(giex$attributes==data.table::shift(giex$attributes,1),giex$start-1,NA))

giex$in1valid  = is.na(giex$in1s)==F & giex$in1s < giex$in1e
giex$in2valid  = is.na(giex$in2s)==F & giex$in2s < giex$in2e

# length
giex$exL                     = giex$end - giex$start + 1
giex$in1L[giex$in1valid==T]  = giex[giex$in1valid==T,]$in1e - giex[giex$in1valid==T,]$in1s + 1 
giex$in2L[giex$in2valid==T]  = giex[giex$in1valid==T,]$in2e - giex[giex$in1valid==T,]$in2s + 1

# string sets
giex_exstring  = subseq(fi[giex[["seqid"]]],start=giex[["start"]],end=giex[["end"]])
giex_in1string = subseq(fi[giex[["seqid"]][giex$in1valid==T]],start=giex[["in1s"]][giex$in1valid==T],end=giex[["in1e"]][giex$in1valid==T])
giex_in2string = subseq(fi[giex[["seqid"]][giex$in2valid==T]],start=giex[["in2s"]][giex$in2valid==T],end=giex[["in2e"]][giex$in2valid==T])
giex_exdatafr  = as.data.frame(as.character(giex_exstring))
giex_in1datafr = as.data.frame(as.character(giex_in1string))
giex_in2datafr = as.data.frame(as.character(giex_in2string))

# GC
#giex$exGC                    = letterFrequency(giex_exstring,letters="GC",as.prob=T)
#giex$in1GC[giex$in1valid==T] = letterFrequency(giex_in1string,letters="GC",as.prob=T)
#giex$in2GC[giex$in2valid==T] = letterFrequency(giex_in2string,letters="GC",as.prob=T)
#giex$difexin1GC              = giex$exGC - giex$in1GC
#giex$difexin2GC              = giex$exGC - giex$in2GC

# complexity
giex$exComplexity                    = as.vector(apply(giex_exdatafr,1,function(x) length(memCompress(x,type="gzip")))) / giex$exL

#giex$in1Complexity[giex$in1valid==T] = as.vector(apply(giex_in1datafr,1,function(x) length(memCompress(x,type="gzip")))) / giex$in1L
LEIN1<-as.vector(apply(giex_in1datafr,1,function(x) length(memCompress(x,type="gzip"))))
IN1L<-giex$in1L[giex$in1valid==T]
giex$in1Complexity[giex$in1valid==T] = LEIN1/IN1L

#giex$in2Complexity[giex$in2valid==T] = as.vector(apply(giex_in2datafr,1,function(x) length(memCompress(x,type="gzip")))) / giex$in2L
LEIN2<-as.vector(apply(giex_in2datafr,1,function(x) length(memCompress(x,type="gzip"))))
IN2L<-giex$in2L[giex$in1valid==T]
giex$in2Complexity[giex$in2valid==T] = LEIN2/IN2L

giex$difexin1Complexity              = giex$exComplexity - giex$in1Complexity
giex$difexin2Complexity              = giex$exComplexity - giex$in2Complexity

# ADD
# CON
# SS!


# First and non-first exons (includes uniexonic...)

giex$first = (!duplicated(giex$attributes) & giex$strand=="+") |
  rev(!duplicated(giex[dim(giex)[1]:1,]$attributes) & giex[dim(giex)[1]:1,]$strand=="-")
giex$exinternal = !(is.na(giex$in1s) | is.na(giex$in2s))




#### Genes table ####

gige = subset(gi, type %in% "gene")
gige = gige[order(gige[,"seqid"],gige[,"start"]),]

# add intergenic upstream downstream
gige$ig1s = ifelse(gige$strand == "+",
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1),data.table::shift(gige$end,1)+1,NA),
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1,type="lead"),gige$end+1,NA))
gige$ig1e = ifelse(gige$strand == "+",
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1),gige$start-1,NA),
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1,type="lead"),data.table::shift(gige$start,1,type="lead")-1,NA))
gige$ig2s = ifelse(gige$strand == "+",
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1,type="lead"),gige$end+1,NA),
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1),data.table::shift(gige$end,1)+1,NA))
gige$ig2e = ifelse(gige$strand == "+",
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1,type="lead"),data.table::shift(gige$start,1,type="lead")-1,NA),
                   ifelse(gige$seqid==data.table::shift(gige$seqid,1),gige$start-1,NA))

# length
gige$geL  = (gige$end-gige$start) + 1
gige$ig1L = (gige$ig1e-gige$ig1s) + 1
gige$ig2L = (gige$ig2e-gige$ig2s) + 1

gige$ig1valid = 0<gige$ig1L & !is.na(gige$ig1L) & gige$ig1s < gige$ig1e
gige$ig2valid = 0<gige$ig2L & !is.na(gige$ig2L) & gige$ig2s < gige$ig2e

# String sets
gige_gestring  = subseq(fi[gige[["seqid"]]],start=gige[["start"]],end=gige[["end"]])
gige_ig1string = subseq(fi[gige[["seqid"]][gige$ig1valid==T]],start=gige[["ig1s"]][gige$ig1valid==T],end=gige[["ig1e"]][gige$ig1valid==T])
gige_ig2string = subseq(fi[gige[["seqid"]][gige$ig2valid==T]],start=gige[["ig2s"]][gige$ig2valid==T],end=gige[["ig2e"]][gige$ig2valid==T])
gige_gedatafr  = as.data.frame(as.character(gige_gestring))
gige_ig1datafr = as.data.frame(as.character(gige_ig1string))
gige_ig2datafr = as.data.frame(as.character(gige_ig2string))

# GC
gige$geGC                    = letterFrequency(gige_gestring,letters="GC",as.prob=T)
gige$ig1GC[gige$ig1valid==T] = letterFrequency(gige_ig1string,letters="GC",as.prob=T)
gige$ig2GC[gige$ig2valid==T] = letterFrequency(gige_ig2string,letters="GC",as.prob=T)

# complexity
gige$geComplexity                    = as.vector(apply(gige_gedatafr,1,function(x) length(memCompress(x,type="gzip")))) / gige$geL
#gige$ig1Complexity[gige$ig1valid==T] = as.vector(apply(gige_ig1datafr,1,function(x) length(memCompress(x,type="gzip")))) / gige$ig1L
GIGE1<-as.vector(apply(gige_ig1datafr,1,function(x) length(memCompress(x,type="gzip"))))
IG1L<-gige$ig1L[gige$ig1valid==T]
gige$ig1Complexity[gige$ig1valid==T] = GIGE1/IG1L

#gige$ig2Complexity[gige$ig2valid==T] = as.vector(apply(gige_ig2datafr,1,function(x) length(memCompress(x,type="gzip")))) / gige$ig2L
GIGE2<-as.vector(apply(gige_ig2datafr,1,function(x) length(memCompress(x,type="gzip"))))
IG2L<-gige$ig2L[gige$ig2valid==T]
gige$ig2Complexity[gige$ig2valid==T] = GIGE2/IG2L

print(paste(si,"counts..."))
#cdsdat      = aggregate(giex$exL~giex$attributes, FUN=sum)
#cdsdat$exoC = aggregate(giex$exL~giex$attributes, FUN=length)[,2]
#colnames(cdsdat) = c("attributes","cdsL","exC")
#gige=join(gige,cdsdat,by="attributes")
#gige$inC = gige$exC-1
#gige$intdxcdskbp = 1000*(gige$inC/gige$cdsL)

cdsdat      = aggregate(giex$exL~giex$attributes, FUN=sum)
cdsdat$exoC = aggregate(giex$exL~giex$attributes, FUN=length)[,2]
colnames(cdsdat) = c("attributes","cdsL","exC")
#cdsdat$attributes <- gsub('transcript_id "', '', cdsdat$attributes)
#cdsdat$attributes <- gsub('.t[0-9]', '', cdsdat$attributes)
gige=join(gige,cdsdat,by="attributes")
gige$inC = gige$exC-1
gige$intdxcdskbp = 1000*(gige$inC/gige$cdsL)
gige$insL = (gige$geL-gige$cdsL-3)
gige$UTRL = (3)

#### Chromosomes table ####

gich = fx[,c("chr","length")]

gendat      = aggregate(gige$geL~gige$seqid, FUN=sum)
gendat$genC = aggregate(gige$geL~gige$seqid, FUN=length)[,2]
cdsL = aggregate(gige$cdsL~gige$seqid, FUN=sum)
insL = aggregate(gige$insL~gige$seqid, FUN=sum)
exC = aggregate(gige$exC~gige$seqid, FUN=sum)
inC = aggregate(gige$inC~gige$seqid, FUN=sum)
UTRL = aggregate(gige$UTRL~gige$seqid, FUN=sum)
colnames(gendat) = c("chr","genL_cum","genC_cum")
colnames(cdsL) = c("chr","cdsL")
colnames(insL) = c("chr","insL")
colnames(exC) = c("chr","exC")
colnames(inC) = c("chr","inC")
colnames(UTRL) = c("chr","UTRL")

gich=join(gich,gendat,by="chr")
gich=join(gich,cdsL,by="chr")
gich=join(gich,insL,by="chr")
gich=join(gich,exC,by="chr")
gich=join(gich,inC,by="chr")
gich=join(gich,UTRL,by="chr")

gich[is.na(gich)] = 0
gich$interC = gich$genC_cum - 1
gich$genD100kbp = 1e5*(gich$genC_cum/gich$length)
gich$genDfrac   = gich$genL_cum/gich$length


genD100kbp_global = 1e5 * (sum(gich$genC_cum) / sum(gich$length))
genDfrac_global   = sum(gich$genL_cum) / sum(gich$length)

gich1k=subset(gich, length > 1000)
Length_1k=c(sum(gich1k$cdsL)/10E5, sum(gich1k$insL)/10E5, sum(gich1k$UTRL)/10E5, (sum(gich1k$length)-sum(gich1k$genL_cum))/10E5)
Region=c("Exonic", "Intronic", "UTR", "Intergenic")
Species=c(rep(si, each=4))
SAG1kgresults<-data.frame(Species, Region, Length_1k)

gich15k=subset(gich, length > 15000)
Length_15k=c(sum(gich15k$cdsL)/10E5, sum(gich15k$insL)/10E5, sum(gich15k$UTRL)/10E5, (sum(gich15k$length)-sum(gich15k$genL_cum))/10E5)
SAG15kgresults<-data.frame(Species, Region, Length_15k)





#### Plots ####

# Funcions de plots
plot.dist = function(dat,varX,ti,limX,linolog) {

  li = na.omit(dat[,varX])
  
  if (!is.na(limX[2])) { 
    limits=limX
  } else { 
    limits=c(limX,quantile(li,probs = 1))
  }
  
  if (linolog == "lin") {
    plot(density(li),xlim=limits,
         col="slategray3",
         xlab=ti,main=paste(ti),
         sub=paste("median =",round(quantile(li)[3],digits=3),"mean =",round(mean(li),digits=3),"n =",length(li)))
    
  } else {
    plot(density(li),xlim = limits,log="x",
         col="slategray3",
         xlab=ti,main=paste(ti),
         sub=paste("median =",round(quantile(li)[3],digits=3),"mean =",round(mean(li),digits=3),"n =",length(li)))
  }
  abline(v=quantile(li),lty=2,col="red")
  text(x=quantile(li),lty=2,y=0,col="red",labels=round(quantile(li),digits=3))
  abline(v=mean(li),lty=2,col="blue")
  text(x=mean(li),lty=2,y=0,col="blue",labels=round(mean(li),digits=3))
  
}

#plot.quantiles.bivar=function(dat,varX,varY,nom,numbins) {
  
#  dav = na.omit(dat[,c(varX,varY)])
#  dav$quantX  = ntile(unlist(dav[varX]),numbins)
#  spe = cor.test(as.vector(unlist(dav[varX])),as.vector(unlist(dav[varY])),method="spe")
#  graphics::boxplot(asView.vector(unlist(dav[varY]))~dav$quantX,col="slategray2",outline=F,
#                    ylab=varY,xlab=paste("Quantiles of",varX),main=nom,
#                    sub=paste("Spearman rho =",format(spe$estimate,digits=3),"p = ",format(spe$p.value,digits=3)))
#  
#}

#plot.scatter.bivar=function(dat,varX,varY,nom) {
  
#  dav = na.omit(dat[,c(varX,varY)])
#  spe = cor.test(as.vector(unlist(dav[varX])),as.vector(unlist(dav[varY])),method="spe")
#  plot(as.vector(unlist(dav[varY]))~unlist(dav[varX]),col="slategray2",outline=F,log="x",
#          ylab=varY,xlab=paste(varX),main=nom,
#          sub=paste("Spearman rho =",format(spe$estimate,digits=3),"p = ",format(spe$p.value,digits=3)))
#  
#}

# Plots
pdf(file=paste(si,"_long.annot.stats.pdf",sep=""),height = 6,width = 6)

# Plot scaffold length
fil = sort(gich$length,decreasing = T)

fil_N75 = fil[cumsum(fil) > sum(fil)*0.75][1]
fil_N75cum = cumsum(fil)[cumsum(fil) > sum(fil)*0.75][1]
fil_L75 = length(fil[cumsum(fil) < sum(fil)*0.75])+1

plot(cumsum(fil/1E3),col="slategray3",
     main="Cumulative scaffold length",ylim = c(0,sum(fil)/1E3),
     sub=paste("n =",length(fil),"scaffolds",
               "size = ",round(sum(fil)/1E6,digits=2),"Mb"),
     ylab="Cumulative genome length (kbp)",xlab="Scaffolds")
abline(h=fil_N75cum/1E3,lty=2,col="red")
abline(v=fil_L75,lty=2,col="red")
text(x=length(fil),y=fil_N75cum/1E3,labels = paste("L75 =",fil_L75,"\n","N75 =",fil_N75/1000,"kbp"),lty=2,col="red",pos = 2)
abline(h=0.75*(sum(fil)/1E3),lty=2,col="pink")

# Plot genic features length, intron density
plot.dist(gich,"genD100kbp",paste("Gene density, per 100 kbp\nGlobal:",signif(genD100kbp_global,4)),0,"lin")
plot.dist(gich,"genDfrac",paste("Gene density, fraction\nGlobal:",signif(genDfrac_global,4)),0,"lin")
plot.dist(gige,"geL","Gene length (bp)",100,"log")
plot.dist(gige,"cdsL","Transcript length (bp)",50,"log")
plot.dist(giex,"exL","Exon length (bp)",10,"log")
plot.dist(giex,"in2L","Intron length (bp)",10,"log")
plot.dist(gige,"ig1L","Upstream intergenic length (bp)",100,"log")
plot.dist(gige,"ig2L","Downstream intergenic length (bp)",100,"log")
plot.dist(gige,"intdxcdskbp","Intron density (Introns/CDS kbp)",0,"lin")
plot.dist(gige,"inC","Intron count",0,"lin")



# GCC
#plot.dist(giex,"exGC","Exon GCC",c(0,1),"lin")
#plot.dist(giex,"in2GC","Intron GCC",c(0,1),"lin")
#plot.dist(gige,"ig2GC","Intergenic GCC",c(0,1),"lin")
#plot.dist(giex,"exComplexity","Exon seq complexity",c(0,3),"lin")
#plot.dist(giex,"in2Complexity","Intron seq complexity",c(0,3),"lin")
#plot.dist(giex,"difexin2Complexity","Exon - intron seq complexity",c(-3,3),"lin")

# Plot comparisons
#plot.quantiles.bivar(giex,"in2L","in2GC","Intron length & GC",20)
#plot.quantiles.bivar(giex,"exL","exGC","Exon length & GC",20)
#plot.quantiles.bivar(giex,"in2L","difexin2GC","Intron length & ex-in GC diff",20)

#Plot Intergenic,exonic, intronic regions
SAG1kgresults$Region <-factor(SAG1kgresults$Region, levels=c("Intergenic","Intronic", "Exonic", "UTR"))
#ggplot(data = SAG1kgresults, aes(x=Species, y=Length_1k, fill=Region)) + geom_bar(stat = "identity", width = 0.4) + scale_x_discrete(expand =  expansion(add=c(1,1))) + theme_gray(base_size=18) + theme(plot.margin = unit(c(0.5,4,0.5,4), "cm"))

SAG15kgresults$Region <-factor(SAG15kgresults$Region, levels=c("Intergenic","Intronic", "Exonic", "UTR"))
#ggplot(data = SAG15kgresults, aes(x=Species, y=Length_15k, fill=Region)) + geom_bar(stat = "identity", width = 0.4) + scale_x_discrete(expand =  expansion(add=c(1,1))) + theme_gray(base_size=18) + theme(plot.margin = unit(c(0.5,4,0.5,4), "cm"))


#Plot Intergenic,exonic, intronic regions, all contigs together
Regions=c(Region, Region)
Length_all=c(Length_1k, Length_15k)
Contigs=c(rep("1k",each=4), rep("15k", each=4))
Genomic_reg_tab<-data.frame(Contigs, Regions, Length_all)
Genomic_reg_tab$Regions <-factor(Genomic_reg_tab$Regions, levels=c("Intergenic","Intronic", "Exonic", "UTR"))
ggplot(data = Genomic_reg_tab, aes(x=Contigs, y=Length_all, fill=Regions)) + geom_bar(stat = "identity", width = 0.4) + scale_x_discrete(expand =  expansion(add=c(1,1))) + theme_gray(base_size=18) + labs(x=si, y="Length (Mb)")



#Introun counts versus Intron Length per gene
InsCq=c(quantile(gige$inC)[2], quantile(gige$inC)[3], quantile(gige$inC)[4])
InsLq=c(quantile(gige$insL)[2], quantile(gige$insL)[3], quantile(gige$insL)[4])
InvsLq<-data.frame(InsLq, InsCq)
ggplot(data = InvsLq, aes(x=InsCq, y=InsLq))+ geom_point(color="firebrick", size=3) + geom_line(color="firebrick") +theme_linedraw(base_size = 18) + labs (x="Intron count", y="Intron Length (bp)")


inCmed<-median(gige$inC)
inCmax<-quantile(gige$inC, probs = seq( .9, by = .2))
insLmed<-mean(gige$insL)
geLmed<-median(gige$geL)
lgenome<-sum(fx$length)
ngenes<-nrow(gige) 
Gene_density_per100Kb<-1/(lgenome/ngenes/1000)*100
inCtotal<-sum(inC$inC)
CDSlength<-sum(gige$geL)
Intron_density<-1/(CDSlength/inCtotal/1000)

InCvsL<-data.frame(si, lgenome, ngenes, inCmed, inCmax, insLmed, geLmed,Gene_density_per100Kb, Intron_density)
colnames(InCvsL)=c("Species", "Length_Genome","Proteins_predicted", "Intron_count_median", "Intron_count9thdecile" , "Intron_Length","CDS length", "Gene_density_per_100Kb_genome", "Intron_density_per_Kb_of_CDS")

write.table(SAG1kgresults, file=paste(si,"_genomicregions1k.txt",sep=""), sep = "\t", row.names = FALSE, col.names = TRUE)
write.table(SAG15kgresults, file=paste(si,"_genomicregions15k.txt",sep=""), sep = "\t", row.names = FALSE, col.names = TRUE)
write.table(InCvsL, file=paste(si,"_IntronCvsL.txt",sep=""), sep = "\t", row.names = FALSE, col.names = TRUE)

dev.off()

# Save data

save(list=c("gi","gige","giex","gich"),file=paste(si,"_long.annot.stats.RData",sep=""))

stop("Acaba aquí")
