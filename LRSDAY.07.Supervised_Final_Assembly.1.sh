#!/bin/bash
set -e -o pipefail
#######################################
# load environment variables for LRSDAY
source ./../../env.sh

#######################################
# set project-specific variables
prefix_1="A1" # The file name prefix (only allowing strings of alphabetical letters, numbers, and underscores) for the processing sample. Default = "CPG_1a" for the testing example.
prefix_2="A2"
prefix_3="A3"
prefix_4="A44"
prefix_5="A45"
prefix_6="A53"
prefix_7="A57"
prefix_8="A60"
prefix_9="A69"
prefix_10="A71"
prefix_11="C2"
prefix_12="D2"
number_of_genome_assemblies=12 #Input the number of genome assemblies that there is 
genome_assembly_1="./../A1_CSFP200004699-1a_H3LKHDSXY_L1.fasta" # The path of the input genome assembly.
genome_assembly_2="./../A2_CSFP200004700-1a_H3LKHDSXY_L1.fasta"
genome_assembly_3="./../A3_CSFP200004701-1a_H3LKHDSXY_L1.fasta"
genome_assembly_4="./../A44_CSFP200002105-1a_H3N7LDSXY_L1.fasta"
genome_assembly_5="./../A45_CSFP200002134-1a_H3N7LDSXY_L1.fasta"
genome_assembly_6="./../A53_CSFP200002104-1a_H3N7LDSXY_L1.fasta"
genome_assembly_7="./../A57_CSFP200004698-1a_H3LKHDSXY_L1.fasta"
genome_assembly_8="./../A60_CSFP200002135-1a_H3N7LDSXY_L1.fasta"
genome_assembly_9="./../A69_CSFP200002142-1a_H3LFKDSXY_L1.fasta"
genome_assembly_10="./../A71_CSFP200002144-1a_H3LFKDSXY_L1.fasta"
genome_assembly_11="./../C2_CSFP200002111-1a_H3N7LDSXY_L1.fasta"
genome_assembly_12="./../D2_CSFP200004703-1a_H3LKHDSXY_L1.fasta"

#######################################
# process the pipeline
# Step 1:
for i in $(seq 1 1 $number_of_genome_assemblies)
do
    prefix="prefix_$i"
    value="${!prefix}"
    genome_assembly="genome_assembly_$i"
    value_assembly="${!genome_assembly}"
    mkdir $value
    cd $value

	echo "#original_name,orientation,new_name" > ${value}.assembly.modification.list
	cat $value_assembly |egrep ">"|sed "s/>//gi"|awk '{print $1 ",+," $1}' >>${value}.assembly.modification.list

	echo "################################"
	echo "running LRSDAY.06.Supervised_Final_Assembly.1.sh > Done!"
	echo "Please manually edit the generated $value.modification.list for relabeling/reordering contigs when necessary"
	echo "Once you finish the editing, plase run the script LRSDAY.06.Supervised_Final_Assembly.2.sh."
	echo "################################"
	
cd ..

done

############################
# checking bash exit status
if [[ $? -eq 0 ]]
then
    echo ""
    echo "LRSDAY message: This bash script has been successfully processed! :)"
    echo ""
    echo ""
    exit 0
fi
############################
