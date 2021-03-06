#!/hpf/tools/centos6/R/3.1.1/bin/Rscript
if (length(commandArgs(TRUE))<3){print("Error: incorrect number of arguments");if(NA)print("Error");}
dir=commandArgs(TRUE)[1];#"/hpf/largeprojects/agoldenb/aziz/brca/processed/"
name="LumB-Basal"
cases="ER+/HER2- High Prolif";       #"ER-/HER2-"; "ER+/HER2- Low Prolif";"ER+/HER2- High Prolif";"HER2+";
controls="ER-/HER2-";

dir.create(paste(dir,name,sep=""))
pheno=read.table(paste(dir,"patients.txt",sep=""),sep="\t",stringsAsFactors =FALSE);
indcases=which(pheno[,2]==cases);
indcontrols=which(pheno[,2]==controls);
if(length(indcases)>length(indcontrols))indcases=sample(indcases,length(indcontrols))
if(length(indcontrols)>length(indcases))indcontrols=sample(indcontrols,length(indcases))

pheno2=rbind(data.frame(pat=pheno[indcases,1],label=1,stringsAsFactors =FALSE),data.frame(pat=pheno[indcontrols,1],label=0,stringsAsFactors =FALSE));
write.table( pheno2, paste(dir,name,"/patients.txt",sep=""),sep="\t",row.names=FALSE,col.names=FALSE);
