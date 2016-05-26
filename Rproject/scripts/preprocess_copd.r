#!/hpf/tools/centos6/R/3.1.1/bin/Rscript
#awk -F"\t" '{print $1}'  genotype.txt | sort | uniq -c > genotype_counts.txt

#awk -F"\t" '{print $1; if ($3==2)print $1}'  exome.txt | sort | uniq -c > /hpf/largeprojects/agoldenb/aziz/myoc_results/genotype_counts.txt
#In exome but not in variants
#awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if(!a[$2])print $2;}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/exome.txt /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/variants_gen_con.txt| wc -l

#echo "/hpf/largeprojects/agoldenb/aziz/diseaseMechanism/Rproject/scripts/analyse_copd.r /hpf/largeprojects/agoldenb/aziz/diseaseMechanism/" | qsub -l vmem=62G,nodes=1:ppn=1,walltime=63:50:00 -N "copd"



#use example_analyse with the following inputs
path="/hpf/largeprojects/agoldenb/aziz/diseaseMechanism/"
datapath="/hpf/largeprojects/agoldenb/aziz/copd/"
resultdirparent="/hpf/largeprojects/agoldenb/aziz/copd/results/"

#preprocess COPD
/hpf/largeprojects/agoldenb/aziz/make_aziz_exome_variants.py /hpf/largeprojects/agoldenb/tal/COPD/PhenoGenotypeFiles/ChildStudyConsentSet_phs000296.COPDGene.v3.p2.c1.HMB/GenotypeFiles/phg000497.v1.COPDGene_6800.genotype-calls-vcf.c1.HMB.update/ESP_LungGO_COPDGene_288.vcf.hg19_multianno.vcf /hpf/largeprojects/agoldenb/aziz/copd/results/
#remove common variants
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 40)print $0}' /hpf/largeprojects/agoldenb/aziz/copd/genotype.txt /hpf/largeprojects/agoldenb/aziz/copd/variants.txt > /hpf/largeprojects/agoldenb/aziz/copd/variants1.txt
#adjust for sex (X and Y genotypes)
awk -F"\t" -v seed=$RANDOM 'BEGIN{srand(seed);} FNR==NR{a[$1]=substr($4,1,1);next;}{if (substr($1,1,1)!="Y"){if (substr($1,1,1)=="X"){if (a[$2]=="M" || $3==2){print $1"\t"$2"\t1";}else{if (rand()>0.5)print $1"\t"$2"\t1";} }else print $0;  }}' /hpf/largeprojects/agoldenb/aziz/copd/patients.txt /hpf/largeprojects/agoldenb/aziz/copd/genotype.txt > /hpf/largeprojects/agoldenb/aziz/copd/genotype1.txt 
#Or remove X and Y
awk -F"\t" '{if ( substr($1,1,1)!="Y" && substr($1,1,1)!="X" )print $0 }' /hpf/largeprojects/agoldenb/aziz/copd/genotype.txt > /hpf/largeprojects/agoldenb/aziz/copd/genotype2.txt 



#preprocess Myocardial infarction
./work/vcf_to_inputs.py /hpf/largeprojects/agoldenb/tal/myocardial-infarction/PhenoGenotypeFiles/RootStudyConsentSet_phs000279.ESP_Broad_EOMI.v2.p1.c1.DS-CVD/GenotypeFiles/phg000291.v1.Broad_EOMI.genotype-calls-vcf.c1/C315_subsetted.vcf.hg19_multianno.vcf /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/
#update patients file (use age to define case/control)
awk -F"\t" '{b=-1; if ($8>50)b=0;if ($8<44.2)b=1; if (b!=-1)print $1"\t"b"\t"$8"\t"$7"\t"$5}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/patients2.txt >/hpf/largeprojects/agoldenb/aziz/myocardial-infarction/patients.txt
#remove common variants
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 40)print $0}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/genotype.txt /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/variants.txt > /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/variants1.txt
#adjust for sex (X and Y genotypes)
awk -F"\t" -v seed=$RANDOM 'BEGIN{srand(seed);} FNR==NR{a[$1]=substr($4,1,1);next;}{if (substr($1,1,1)!="Y"){if (substr($1,1,1)=="X"){if (a[$2]=="M" || $3==2){print $1"\t"$2"\t1";}else{if (rand()>0.5)print $1"\t"$2"\t1";} }else print $0;  }}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/patients.txt /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/genotype.txt > /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/genotype1.txt 
#Or remove X and Y
awk -F"\t" '{if (substr($1,1,1)!="Y" && substr($1,1,1)!="X")print $0 }' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/genotype.txt > /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/genotype2.txt


#preprocess epi4k
#concat clinical file
awk -F"\t" '!/^[ \t]*#/&&NF{if ($2!="SUBJECT_ID")print $0}' /hpf/largeprojects/agoldenb/aziz/epi4k/phs000654.v2.pht003467.v1.p1.c1.Epi4K_Epileptic_Encephalopathies_Subject_Phenotypes.GRU.txt /hpf/largeprojects/agoldenb/aziz/epi4k/phs000654.v2.pht003824.v1.p1.c1.Epi4K_Epileptic_Encephalopathies_Subject_Phenotypes_v2.GRU.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/Subject_Phenotypes.txt
#transform and concat csv id map files:
awk -F"," '!/^[ \t]*#/&&NF{if ($2!="SUBJECT_ID")print $1"\t"$4}' /hpf/largeprojects/agoldenb/aziz/epi4k/sample/phg000376.v1.sample-info.csv > /hpf/largeprojects/agoldenb/aziz/epi4k/Subject_id_map.txt
awk -F"," '!/^[ \t]*#/&&NF{if ($2!="SUBJECT_ID")print $1"\t"$3}' /hpf/largeprojects/agoldenb/aziz/epi4k/sample/sample-info.csv >> /hpf/largeprojects/agoldenb/aziz/epi4k/Subject_id_map.txt
#Generate patients.txt file
awk -F"\t" 'FNR==NR{a[$1]=$2;next;}{if (a[$2]){b=0;if($3=="IS" || $3=="LGS")b=1;print a[$2]"\t"b"\t"$3"\t"$4"\t"$5"\t"$2}}'  /hpf/largeprojects/agoldenb/aziz/epi4k/Subject_id_map.txt /hpf/largeprojects/agoldenb/aziz/epi4k/Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/patientsraw.txt
#select only proband and same-gender parents
awk -F"\t" '!/^[ \t]*#/&&NF{if(FNR==NR){if ($6=="M" && $4!=0){a[$4]=1;a[$3]=1}if($6=="F" && $5!=0) {a[$5]=1;a[$3]=1}next;}if (a[$6]==1){print $0}}' /hpf/largeprojects/agoldenb/aziz/epi4k/pedigree.txt /hpf/largeprojects/agoldenb/aziz/epi4k/patientsraw.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/patients.txt
#remove common variants
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 40)print $0}' /hpf/largeprojects/agoldenb/aziz/epi4k/genotype.txt /hpf/largeprojects/agoldenb/aziz/epi4k/variants.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/variants1.txt
#adjust for sex (X and Y genotypes)
awk -F"\t" -v seed=$RANDOM 'BEGIN{srand(seed);} FNR==NR{a[$1]=substr($4,1,1);next;}{if (substr($1,1,1)!="Y"){if (substr($1,1,1)=="X"){if (a[$2]=="M" || $3==2){print $1"\t"$2"\t1";}else{if (rand()>0.5)print $1"\t"$2"\t1";} }else print $0;  }}' /hpf/largeprojects/agoldenb/aziz/epi4k/patients.txt /hpf/largeprojects/agoldenb/aziz/epi4k/genotype.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/genotype1.txt 
#Or remove X and Y
awk -F"\t" '{if (substr($1,1,1)!="Y" && substr($1,1,1)!="X")print $0 }' /hpf/largeprojects/agoldenb/aziz/epi4k/genotype.txt > /hpf/largeprojects/agoldenb/aziz/epi4k/genotype2.txt



#preprocess FHS
#concat clinical file
awk -F"\t" '!/^[ \t]*#/&&NF{if ($2!="SUBJECT_ID")print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/phs000401.v9.pht002476.v2.p10.c1.FHS_ESP_HeartGO_Subject_Phenotypes.HMB-IRB-MDS.txt   /hpf/largeprojects/agoldenb/aziz/FHS/phs000401.v9.pht002476.v2.p10.c2.FHS_ESP_HeartGO_Subject_Phenotypes.HMB-IRB-NPU-MDS.txt > /hpf/largeprojects/agoldenb/aziz/FHS/Subject_Phenotypes.txt


echo "/hpf/tools/centos6/annovar/2015.02.12/table_annovar.pl -protocol refGene,ljb26_all,snp138,esp6500siv2_all -operation g,f,f,f -vcfinput -buildver hg19 /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/fhs.c2.vcf /hpf/tools/centos6/annovar/2015.02.12/humandb/" | qsub -l vmem=62G,nodes=1:ppn=1,walltime=63:50:00 -N "anno"

./work/vcf_to_inputs.py /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/JHS.vcf.hg19_multianno.vcf /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS/

#remove multi-allelic calls from FHS
awk -F"\t" '{if (NF !=387){print $0;}else{split($5,a,","); if (length(a)==1)print $0}}' /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/fhs.c1.vcf.hg19_multianno.vcf > /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/fhs.c1cleaned.vcf.hg19_multianno.vcf

awk -F"\t" '{if (NF !=93){print $0;}else{split($5,a,","); if (length(a)==1)print $0}}' /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/fhs.c2.vcf.hg19_multianno.vcf > /hpf/largeprojects/agoldenb/aziz/FHS/vcfs/fhs.c2cleaned.vcf.hg19_multianno.vcf
#Add cohort prefix to patient ids
awk -F"\t" '{print $1"\tardsnet-"$2"\t"$3}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS/genotype-ardsnet.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS/genotype1-ardsnet.txt

#concatinating all variants files
cat /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS/variants-* | awk -F"\t" '{print $1"\t"$2"\t"$3"\t"$4}' - | sort | uniq > /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt
#concat genotypes
cat /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS/genotype-* | sort  | uniq > /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt


#get the patient id mapping from sample info
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "arsdsnet-"a[$2]"\t"$0}}' phg000476.v1.ESP_LungGO_ALI_6800.sample-info.MULTI/phg000476.v1_release_manifest.txt /hpf/largeprojects/agoldenb/aziz/FHS/ardsnet-Subject_Phenotypes-Root.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/ardsnet_Mapped_Phenotypes-Root.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "ARIC-"a[$2]"\t"$0}}' phg000482.v1.ESP_HeartGO_ARIC_6800.sample-info.MULTI/phg000482.v1_release_manifest.txt /hpf/largeprojects/agoldenb/aziz/FHS/ARIC_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/ARIC_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "FHS1-"a[$2]"\t"$0}}' phg000489.v2.ESP_HeartGO_FHS.sample-info.MULTI/phg000489.v2_release_manifest.txt /hpf/largeprojects/agoldenb/aziz/FHS/phs000401.v9.pht002476.v2.p10.c1.FHS_ESP_HeartGO_Subject_Phenotypes.HMB-IRB-MDS.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/FHS1_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "FHS2-"a[$2]"\t"$0}}' phg000489.v2.ESP_HeartGO_FHS.sample-info.MULTI/phg000489.v2_release_manifest.txt /hpf/largeprojects/agoldenb/aziz/FHS/phs000401.v9.pht002476.v2.p10.c2.FHS_ESP_HeartGO_Subject_Phenotypes.HMB-IRB-NPU-MDS.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/FHS2_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "JHS-"a[$2]"\t"$0}}' phg000522.v1.ESP_HeartGO_JHS_6800.sample-info.MULTI/phg000522.v1_release_manifest.txt /hpf/largeprojects/agoldenb/aziz/FHS/JHS_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "JHS1-"a[$2]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/JHS1.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/JHS1_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS1_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "CHS1-"a[$2]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/CHS1.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/CHS1_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/CHS1_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "CHS2-"a[$2]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/CHS2.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/CHS2_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/CHS2_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "CARDIA-"a[$2]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/CARDIA.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/CARDIA_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/CARDIA_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$2]){print "MESA-"a[$2]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/MESA.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/MESA-Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/MESA_Mapped_Phenotypes.txt
awk -F"\t" '!/^[ \t]*#/&&NF{if (FNR==NR){a[$2]=$1;next;} if (a[$1]){print "EOMI-"a[$1]"\t"$0}}' /hpf/largeprojects/agoldenb/aziz/FHS/EOMI_6800.sample-info.txt /hpf/largeprojects/agoldenb/aziz/FHS/EOMI_6800_Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI_6800_Mapped_Phenotypes.txt
#awk -F"\t" '!/^[ \t]*#/&&NF{if (NR>11)print "MESA-"$2"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/MESA-Subject_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/MESA_Mapped_Phenotypes.txt


#important columns in each file
#MESA  ESP-phenotype=4, ethnicity=7, sex=8, age=10, bmi_baseline=15, t2d=16, ldl=22, hdl=23, trig=24, sbp=27, dbd=28
#ARIC  ESP-phenotype=4, ethnicity=7, sex=8, age=10, bmi_baseline=15, t2d=16, ldl=22, hdl=23, trig=24, sbp=27, dbd=28
#CHS  ESP-phenotype=4, ethnicity=7, sex=8, age=10, bmi_baseline=15, t2d=16, ldl=22, hdl=23, trig=24, sbp=27, dbd=28
#JHS ESP-phenotype=4, ethnicity=7, sex=8, age=9, bmi_baseline=12, t2d=13, ldl=18, hdl=19, trig=20, sbp=23, dbd=24
#FHS ESP-phenotype=4, ethnicity=7, sex=8, age=10, bmi_baseline=16, t2d=17, ldl=22, hdl=23, trig=24, sbp=27, dbd=28
#CARDIA  ESP-phenotype=5, ethnicity=8, sex=9, age=11, bmi_baseline=14, t2d=15, ldl=20, hdl=21, trig=22, sbp=25, dbd=26
#ardsnet phenotype=3 (primary=3 , secondary=4), VFD, death_day, yoa, sex=8,  race    trauma  sepsis  transf  aspir   pneumo  other   source_site
#EOMI_6800 phenotype=3, sex=4, age=5

awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$10"\t"$13"\t"$14"\t"$19"\t"$20"\t"$21"\t"$24"\t"$25 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_JHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$10"\t"$13"\t"$14"\t"$19"\t"$20"\t"$21"\t"$24"\t"$25 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/JHS1_Mapped_Phenotypes.txt >> /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_JHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$17"\t"$18"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/FHS1_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_FHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$17"\t"$18"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/FHS2_Mapped_Phenotypes.txt >> /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_FHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$16"\t"$17"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/CHS1_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_CHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$16"\t"$17"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/CHS2_Mapped_Phenotypes.txt >> /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_CHS.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$16"\t"$17"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/MESA_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_MESA.txt
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$5"\t"$8"\t"$9"\t"$11"\t"$16"\t"$17"\t"$23"\t"$24"\t"$25"\t"$28"\t"$29 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/ARIC_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_ARIC.txt 
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$6"\t"$9"\t"$10"\t"$12"\t"$15"\t"$16"\t"$21"\t"$22"\t"$23"\t"$26"\t"$27 ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/CARDIA_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_CARDIA.txt 
awk -F"\t" '!/^[ \t]*#/&&NF{print $1"\t"$3"\t"NA"\t"$4"\t"$5"\t"NA"\t"NA"\t"NA"\t"NA"\t"NA"\t"NA"\tNA" ;}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI_6800_Mapped_Phenotypes.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_EOMI_6800.txt 


cat /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_* > /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt
awk -F"\t" '{print $2}'  /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt | sort | uniq -c


#create files for one phenotype
awk -F"\t" '{a=-1;if ($2=="BP_High")a=1;if ($2=="BP_Low")a=0; if (a>-1)print $1"\t"a"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/BP/patients.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$2])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/BP/patients.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/BP/genotype.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$1])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/BP/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/BP/variants.txt

awk -F"\t" '{a=-1;if ($2=="LDL_High")a=1;if ($2=="LDL_Low")a=0; if (a>-1)print $1"\t"a"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_old/patients.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$2])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_old/patients.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_old/genotype.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$1])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_old/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_old/variants.txt

awk -F"\t" '{a=-1;if ($2=="LDL_High")a=1;if ($2=="DPR")a=0; if (a>-1)print $1"\t"a"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/patients.txt
/hpf/largeprojects/agoldenb/aziz/diseaseMechanism/Rproject/scripts/select_patients.r "/hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/patients.txt" "/hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/patients1.txt" "2" "5,6"
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$2])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/patients1.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/genotype.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$1])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/variants.txt
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 37)print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/variants.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_High/variants1.txt

awk -F"\t" '{a=-1;if ($2=="LDL_Low")a=1;if ($2=="DPR")a=0; if (a>-1)print $1"\t"a"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/patients.txt
/hpf/largeprojects/agoldenb/aziz/diseaseMechanism/Rproject/scripts/select_patients.r "/hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/patients.txt" "/hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/patients1.txt" "2" "5,6"
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$2])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/patients1.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/genotype.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$1])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/variants.txt
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 40)print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/variants.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/LDL_Low/variants1.txt

awk -F"\t" '{a=-1;if ($2=="EOMI_CASE" || $2=="EOMI_Case")a=1;if ($2=="EOMI_Control")a=0; if (a>-1)print $1"\t"a"\t"$0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/phenotype_raw_all.txt | sort -rnk 6 > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients_raw.txt
awk -F"\t" '{if ($4=="EOMI_CASE" || $4=="EOMI_Case")print $5}'  /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients_raw.txt | sort | uniq -c
awk -F"\t" '{if ($4=="EOMI_Control")print $5}'  /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients_raw.txt | sort | uniq -c
#EOMI-controls are gender biased. 
#Solution : remove oldest 77 male cases and 239 female cases to match controls numbers. 
awk -F"\t" 'BEGIN{f=0;m=0;}{ a=1;if ($4=="EOMI_CASE" || $4=="EOMI_Case" ){ if (m<77 && $5="M"){m=m+1;a=0;} if(f<239 && $5="F"){f=f+1;a=0;} } if(a==1)print $0}'  /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients_raw.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients.txt
#Or add female controls from DPR (TODO)

awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$2])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/patients.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/genotype-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/genotype.txt
awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if (a[$1])print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/variants-all.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/variants.txt
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 110)print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/variants.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/EOMI/variants1.txt



#remove common variants and X and Y chromosomes
awk -F"\t" 'FNR==NR{if(a[$1]){a[$1]=a[$1]+$3;}else {a[$1]=$3} next;}{if (a[$1]< 103 && substr($1,1,1)!="Y" && substr($1,1,1)!="X")print $0}' /hpf/largeprojects/agoldenb/aziz/FHS/processed/DPR/genotype.txt /hpf/largeprojects/agoldenb/aziz/FHS/processed/DPR/variants.txt > /hpf/largeprojects/agoldenb/aziz/FHS/processed/DPR/variants1.txt

Brouillon:
#awk -F"\t" '{print $1}'  genotype.txt | sort | uniq -c > genotype_counts.txt
#load("/home/aziz/Desktop/aziz/diseaseMechanism_Results/brca/BRCA_methylation/BRCA_methyl_450__All__Both.rda")
#write.table(Data,"/home/aziz/Desktop/aziz/diseaseMechanism_Results/brca/processed/methyl_all.txt",col.names=substr(colnames(Data),9,12),row.names=Des[,1],sep="\t")
#x=load("/home/aziz/Desktop/aziz/diseaseMechanism_Results/brca/BRCA_methylation/BRCA_methyl_450__TSS1500__Both.rda")
#write.table(Data,"/home/aziz/Desktop/aziz/diseaseMechanism_Results/brca/processed/methyl_1500.txt",col.names=substr(colnames(Data),9,12),row.names=Des[,1],sep="\t")


#awk -F"\t" '{print $1; if ($3==2)print $1}'  /hpf/largeprojects/agoldenb/tal/myocardial-infarction/PhenoGenotypeFiles/RootStudyConsentSet_phs000279.ESP_Broad_EOMI.v2.p1.c1.DS-CVD/GenotypeFiles/phg000291.v1.Broad_EOMI.genotype-calls-vcf.c1/aziz_cadd_spidex_genes/exome.txt | sort | uniq -c > /hpf/largeprojects/agoldenb/aziz/myoc_results/genotype_counts.txt
#Exome without common:
#awk -F"\t" 'FNR==NR{a[$2]=$5;next;}{if(a[$1] && a[$1]<0.05)print $0;}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/variants_con_con.txt /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/exome.txt | wc -l
#In exome but not in variants
#awk -F"\t" 'FNR==NR{a[$1]=1;next;}{if(!a[$2])print $2;}' /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/exome.txt /hpf/largeprojects/agoldenb/aziz/myocardial-infarction/variants_gen_con.txt| wc -l

#echo "/hpf/largeprojects/agoldenb/aziz/diseaseMechanism/Rproject/scripts/analyse_myoc.r /hpf/largeprojects/agoldenb/aziz/diseaseMechanism/" | qsub -l vmem=62G,nodes=1:ppn=1,walltime=63:50:00 -N "myoc2"


#Breast cancer preprocessing
awk -F"\t" '{if ($2=="\"ER+\/HER2- Low Prolif\"")print $1"\t"1; if ($2=="\"ER-\/HER2-\"")print $1"\t"0}' /hpf/largeprojects/agoldenb/aziz/brca/processed/patients.txt > /hpf/largeprojects/agoldenb/aziz/brca/processed/patients_LumA-Basal.txt


