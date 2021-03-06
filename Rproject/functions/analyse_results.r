
top_cause_proba= function(cause,n){return(cause[which(cause[,4]==0)[1:n],2]);}
top_cause_gene= function(cause,n){return(cause[which(cause[,4]==0)[1:n],1]);}
top_cause_type= function(cause,n){return(cause[which(cause[,4]==0)[1:n],3]);}
top_cause_all= function(cause,n){return(cause[which(cause[,4]==0)[1:n],]);}

#Test other methods . Return p-values for every gene
other_methods=function(trans,labels,genesToTest,tests,perm,mf=NULL,dict=NULL, removeCommon=FALSE){
pvals=matrix(2,length(genesToTest) , length(tests));
k=1;
currentmafs=colSums(trans$mat)/(2*dim(trans$mat)[1]);
for (i in genesToTest){
cols=which(trans$gene==i);
colsrare=which(trans$gene==i & currentmafs<0.05);# real MAFs are mf[dict[trans$snps]]
if (removeCommon)cols=colsrare;
if(length(cols)>1){
  if (tests=="CAST"){ if (length(colsrare)>1){pvals[k,]=CAST(labels, trans$mat[,colsrare])$asym.pval;}
  }else if (tests=="VT"){
      pvals[k,]=VT(labels, trans$mat[,cols], perm=100)$perm.pval;
      if (!is.na(pvals[k,1]) && pvals[k,1]<0.05)pvals[k,]=VT(labels, trans$mat[,cols], perm=1000)$perm.pval;
      if (!is.na(pvals[k,1]) && pvals[k,1]<0.005)pvals[k,]=VT(labels, trans$mat[,cols], perm=10000)$perm.pval;
      if (perm>10000 && !is.na(pvals[k,1]) && pvals[k,1]<0.0005)pvals[k,]=VT(labels, trans$mat[,cols], perm=100000)$perm.pval;
      if (perm>100000 && !is.na(pvals[k,1]) && pvals[k,1]<0.00005)pvals[k,]=VT(labels, trans$mat[,cols], perm=1000000)$perm.pval;
  }else if (tests=="CALPHA"){ pvals[k,]=CALPHA(labels, trans$mat[,cols])$asym.pval;
  }else if (tests=="RWAS"){ if (length(colsrare)>1){pvals[k,]=RWAS(labels, trans$mat[,cols])$asym.pval;}
  }else if (tests=="SKAT"){pvals[k,]=SKAT(labels, trans$mat[,cols])$asym.pval;
  }else if (tests=="SKAT-O"){ x=SKAT_Null_Model(labels ~ 1,out_type="D",Adjustment=FALSE);pvals[k,]=SKAT(trans$mat[,cols],x,method="optimal.adj")$p.value;# was trans$mat[,cols] instead of 1
  }else pvals[k,]=MULTI(labels, trans$mat[,cols],tests=tests,perm = perm)$pvalue;
} else {if (length(cols)==1)pvals[k,]=chisq.test(labels, trans$mat[,cols])$p.value;}
k=k+1;
}
return(pvals)
}

run_dmgwas=function(net1,pvals,patExpr,ctrExpr){
networkInMatForm=matrix(0,sum(unlist(lapply(net1,length))),2);
k=1;for (w in 1:length(net1)){if(length(net1[[w]])){networkInMatForm[k:(k+length(net1[[w]])-1),]=cbind(w,net1[[w]]) ;k=k+length(net1[[w]]); }}
patExprfr=NULL;ctrExprfr=NULL;
if (length(patExpr))patExprfr=data.frame(1:length(net1),patExpr);if (length(ctrExpr))ctrExprfr=data.frame(1:length(net1),ctrExpr);
dmgwas=dms(networkInMatForm,data.frame(1:length(net1),pvals),patExprfr,ctrExprfr);
topmodule=as.numeric(unlist(chooseModule(dmgwas,1,plot=FALSE)$modules));
return(list(topmodule=topmodule,dmgwas=dmgwas));
}

get_occurences=function(geneslabels,u,v){
occ=matrix(0,2,length(geneslabels)+1);colnames(occ)<- c(geneslabels,"Others");
for(i in 1:(length(geneslabels)+1)){ind=which(u==i);if(length(ind)){occ[1,i]=length(which(v[ind]=="Qual"));occ[2,i]=length(which(v[ind]=="Expr"));}}
return(occ)
}

plot_graphs= function(x,pheno,resultdir,genestodraw,suff=NULL,reorder=TRUE){
top=3;
ord=1:length(pheno);if(reorder)ord=order(pheno);
topcauseproba=matrix(as.numeric(unlist(lapply(x$causes,top_cause_proba,top))),nrow=3);
topcausegene=matrix(as.numeric(unlist(lapply(x$causes,top_cause_gene,top))),nrow=3);
tocausetype=matrix(as.character(unlist(lapply(x$causes,top_cause_type,top))),nrow=3);
#png(paste(resultdir,"resultSep",suff,".png",sep=""));plot(1:length(pheno),topcauseproba[1,ord]);dev.off();# could use rowSums over the top causes
png(paste(resultdir,"resultPred",suff,".png",sep=""));plot(ord,x$predict[ord]);u=which(pheno[ord]>0.5);points(ord[u],x$predict[ord[u]],col="red");  dev.off();
png(paste(resultdir,"resultNetcontrib",suff,".png",sep=""));hist(exp(x$munetall[,2]));dev.off();
if(length(genestodraw)){
png(paste(resultdir,"resultProba",suff,".png",sep=""));plot(1:length(genestodraw),x$h[genestodraw]);dev.off();
u=match(topcausegene[1,which(pheno==1)],genestodraw);u[is.na(u)]<- length(genestodraw)+1; 
v=tocausetype[1,which(pheno==1)];
#occ=matrix(0,2,length(genestodraw)+1);colnames(occ)<- c(as.character(genenames[genestodraw]),"Others");
#for(i in 1:length(genestodraw)){ind=which(u==i);if(length(ind)){occ[1,i]=length(which(v[ind]=="Qual"));occ[2,i]=length(which(v[ind]=="Expr"));}}
png(paste(resultdir,"resultFirstGene",suff,".png",sep=""));barplot(get_occurences(as.character(genenames[genestodraw]),u,v),las=2,ylab="Number of patients",cex.names=0.80,legend=c("Quality","Quantity"));dev.off();

}
}

pie_plot_patients=function(cause,bestgenes,genenames,resultdir,clock){
cau=data.frame(genenames[as.numeric(cause[,1])],as.numeric(cause[,2]) )[which(cause[,4]==0),];
indcau=which(cau[,1] %in% genenames[bestgenes]);
others=sum(cau[-indcau,2]);
png(paste(resultdir,"resultPatient.png",sep=""));pie(c(cau[indcau,2],others),labels=c(as.character(cau[indcau,1]),"Others"),clockwise=clock,col=rainbow(length(indcau)+1,alpha=0.3));dev.off();
}




