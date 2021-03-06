#veriables needed from mainSimulPop
#nb_genes_causal (renaming), genes (renaming)
#sample_size, testVariations,npermut, removeCommon
#dir, dirrep,codeDir,networkName,maxConnections
#ratioSignal,alpha, propagate, complexityDistr, decay
#netparam,netmax,netmaxNoise,netrelaxed,usenet2,removeExpressionOnly

#veriables needed from simulDisease
#truth
#net is being reread (as net1) but it could just be passed too



#model parameters
meancgenes=nb_genes_causal;

genenames=read.table(paste(dirrep,"genes.txt",sep=""),stringsAsFactors=FALSE)[,1];
clinical=read.table(paste(dirrep,"patients.txt",sep=""),stringsAsFactors=FALSE);
genotype=read.table(paste(dirrep,"genotype.txt",sep=""),sep="\t",stringsAsFactors =FALSE,colClasses=c("character","character","numeric"));
expr=read.table(paste(dirrep,"gene_expression.txt",sep=""),sep="\t",row.names=1);
rawanno=read.table(paste(dirrep,"variants.txt",sep=""),sep="\t",colClasses=c("character","character","NULL","numeric"));

pheno=clinical[,2]# 1 sick ; 0 control
nbpatients=length(pheno);nbgenes=length(genenames);

if (removeCommon){
allfreq=table(genotype[,1]);
toRem=names(allfreq)[which(allfreq>0.1*nbpatients)]
rawanno=rawanno[which(!(rawanno[,1] %in% toRem)),]
print(paste(length(toRem),"common variants removed"))
}


anno=rawanno[order(rawanno[,2]),];
indsnp=rep(1,nrow(anno));
nb=1;
for (i in 2:nrow(anno)){
if(anno[i,2]!=anno[i-1,2]){nb=1;}else nb=nb+1;
indsnp[i]=nb;
}

harm=list(); length(harm) <- nbgenes;
transform_harm=function(x)(x*0.9+0.05)
for(i in 1:nbgenes)harm[[i]]<- transform_harm(anno[which(anno[,2]==genenames[i]),3]);
nbsnps=rep(0,nbgenes);for (i in 1:nbgenes)nbsnps[i]=length(harm[[i]]);
harmgene=rep(meancgenes/nbgenes,nbgenes);

#create hashtable for variants, genes and patients
geneids=1:nbgenes;names(geneids)<- genenames;
varids=1:nrow(anno); names(varids)<- anno[,1];
patientids=1:nbpatients;names(patientids)<- clinical[,1];

source(paste(codeDir,"functions/process_expr.r",sep=""))
source(paste(codeDir,"newmethod/sumproductmem.r",sep=""))

#preprocessing expression
affectedexpr=which(clinical[patientids[colnames(expr)],2]==1);
e1=t(apply(expr[,affectedexpr],1,medmad));e2=t(apply(expr[,-affectedexpr],1,medmad));
e=cbind(e2,e1);colnames(e)<- NULL;#CONTROL THEN CASES (because pheno is that way)

abthres=2.5;
overt=function(e){return(length(which(abs(e) >abthres) ))}
abExpr=apply(abs(e1),1,overt);abExpr1=apply(abs(e2),1,overt);
print(paste("Expression abnormalities in cases/controls",sum(abExpr[truth]),sum(abExpr1[truth])));

#Add gene interactions (PPI) in a cleaner way
#source("newmethod/networkToCliques.r");
net1=load_network_genes(networkName,as.character(genenames),maxConnections)$network;
#cliks=networkToCliques(net);
net2=mapply(surround2,net1,1:length(net1) , MoreArgs=list(net1=net1));
net=net1;if (usenet2)net=net2;

netmax=max(netmax,5*meancgenes/nbgenes); #This is important : netmax should always be bigger than prior
netmaxNoise=max(netmaxNoise,2*meancgenes/nbgenes); #This is important : netmaxnoise should always be bigger than prior

#loading genotype
mappat=1:nbpatients;
het=list();length(het)<- nbgenes;for (i in 1:nbgenes){het[[i]]<- list(); length(het[[i]])<- nbpatients;} 
hom=list();length(hom)<- nbgenes;for (i in 1:nbgenes){hom[[i]]<- list(); length(hom[[i]])<- nbpatients;} 
p=mappat[patientids[genotype[,2]]];ind=varids[genotype[,1]];g=geneids[anno[ind,2]];
for (i in 1:nrow(genotype)){
  if(!is.na(g[i]) && !is.na(p[i])){
    if (genotype[i,3]==1)het[[g[i]]][[p[i]]] <- c(het[[g[i]]][[p[i]]], indsnp[ind[i]])
    if (genotype[i,3]==2)hom[[g[i]]][[p[i]]] <- c(hom[[g[i]]][[p[i]]], indsnp[ind[i]])
  }
}

object.size(x=lapply(ls(), get));print(object.size(x=lapply(ls(), get)), units="Mb")

e=NULL;#WARNING to remove

#Do Belief propagation
x <- grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,netparams=c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);


#Evaluations
if (x$status){
print(x$margC);
genestodraw=truth;
plot_graphs(x,pheno,dirrep,genestodraw);
th=x$h[truth]
}

xres[[1]]=x;
if (testVariations==5 & testrobust==1){#robustness for expression
xres[[2]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,NULL,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[3]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,NULL, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
harmrand=harm;for (i in 1: length(harm))if (length(harm[[i]]))harmrand[[i]]=rep(0.5,length(harm[[i]]));
xres[[4]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harmrand,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[5]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harmrand,harmgene,meancgenes,complexityDistr,pheno,hom,het,NULL,NULL, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}


if (testVariations==4 & testrobust==1){#robustness for exome only
xres[[2]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,NULL,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
harmrand=harm;for (i in 1: length(harm))if (length(harm[[i]]))harmrand[[i]]=rep(0.5,length(harm[[i]]));
xres[[3]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harmrand,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[4]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harmrand,harmgene,meancgenes,complexityDistr,pheno,hom,het,NULL,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}


if (testVariations>1 & testrobust==2){#robustness for the meancgenes hyperparameter (true value is 20)
xres[[2]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,rep(5/nbgenes,nbgenes),5,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,max(netmax,5*5/nbgenes),max(netmaxNoise,2*5/nbgenes),netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[3]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,rep(10/nbgenes,nbgenes),10,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,max(netmax,5*10/nbgenes),max(netmaxNoise,2*10/nbgenes),netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[4]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,rep(50/nbgenes,nbgenes),50,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,max(netmax,5*50/nbgenes),max(netmaxNoise,2*50/nbgenes),netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[5]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,rep(100/nbgenes,nbgenes),100,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,max(netmax,5*100/nbgenes),max(netmaxNoise,2*100/nbgenes),netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}

if (testVariations>1 & testrobust==3){#robustness for the ratioSignal hyperparameter (true value is 0.5)
xres[[2]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,0.05,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[3]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,0.25,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[4]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,0.75,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[5]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,1,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}

if (testVariations>1 & testrobust==4){#robustness for the complexityDistr hyperparameter (default is c(0,1,0,0))
xres[[2]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,c(1,0,0,0),pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[3]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,c(0,0,1,0),pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
xres[[4]]= grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,c(0,0,0,1),pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}

#h1=unlist(read.table(paste(dirrep,"genes9.txt",sep="")))

xp=list();length(xp)=npermut;
if(npermut){ for (i in 1:npermut){
pheno=sample(pheno);
xp[[i]]=grid_search(codeDir,nbgenes,nbpatients,nbsnps,harm,harmgene,meancgenes,complexityDistr,pheno,hom,het,net,e, cores,ratioSignal,decay,alpha,c(netparam,netmax,netmaxNoise,netrelaxed),removeExpressionOnly,truth,propagate=propagate);
}}


#top=3;
#topcauseproba=matrix(as.numeric(unlist(lapply(x$causes,top_cause_proba,top))),nrow=3);
#topcausegene=matrix(as.numeric(unlist(lapply(x$causes,top_cause_gene,top))),nrow=3);
#tocausetype=matrix(as.character(unlist(lapply(x$causes,top_cause_type,top))),nrow=3);
#png(paste(dirrep,"resultSep.png",sep=""));plot(1:length(pheno),topcauseproba[1,]);dev.off();# could use rowSums over the top causes
#genestodraw=truth;
#u=match(topcausegene[1,which(pheno==1)],genestodraw);u[is.na(u)]<- length(genestodraw)+1; 
#v=tocausetype[1,which(pheno==1)];
#occ=matrix(0,2,length(genestodraw)+1);colnames(occ)<- c(as.character(genenames[genestodraw]),"Others");
#for(i in 1:length(genestodraw)){ind=which(u==i);if(length(ind)){occ[1,i]=length(which(v[ind]=="Qual"));occ[2,i]=length(which(v[ind]=="Expr"));}}
#png(paste(dirrep,"resultFirstGene.png",sep=""));barplot(occ,las=2);dev.off();
#png(paste(dirrep,"resultPred.png",sep=""));plot(1:length(pheno),x$predict);dev.off();
#png(paste(dirrep,"resultProba.png",sep=""));plot(1:length(truth),x$h[truth]);dev.off();
#png(paste(dirrep,"resultNetcontrib.png",sep=""));hist(exp(x$munetall[,2]));dev.off();

