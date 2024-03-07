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
chrMT_tag="chrMT" # The sequence name for the mitochondrial genome in the final assembly. If there are multiple sequences, use a single ';' to separate them. e.g. "chrMT_part1;chrMT_part2". Default = "chrMT".
query="$LRSDAY_HOME/data/SC5314.centromere.fa" # The S. cerevisiae S288C reference centromere sequences based on Yue et al. (2017) Nature Genetics.
debug="no" # Whether to keep intermediate files for debugging. Use "yes" if prefer to keep intermediate files, otherwise use "no". Default = "no".

######################################
# process the pipeline



#echo $chrMT_tag | sed -e "s/;/\n/g" > $prefix.assembly.chrMT.list

for i in $(seq 1 1 $number_of_genome_assemblies)
do
    prefix="prefix_$i"
    value="${!prefix}"
    genome_assembly="genome_assembly_$i"
    value_assembly="${!genome_assembly}"
    mkdir $value
    cd $value

#	perl $LRSDAY_HOME/scripts/select_fasta_by_list.pl -i $value_assembly -m reverse -o $value.assembly.nuclear_genome.fa
	perl $LRSDAY_HOME/scripts/tidy_fasta.pl -i $value_assembly -o $value.assembly.nuclear_genome.tidy.fa

	$exonerate_dir/exonerate --showvulgar no --showcigar no --showalignment no --showtargetgff yes --bestn 1 $query $value_assembly  >$value.centromere.exonerate.gff
	perl $LRSDAY_HOME/scripts/exonerate_gff2gff3.pl  -i $value.centromere.exonerate.gff -o $value.centromere.gff3.tmp -t $value
	perl $LRSDAY_HOME/scripts/tidy_maker_gff3.pl -r $value.assembly.nuclear_genome.tidy.fa -i $value.centromere.gff3.tmp -o $value.nuclear_genome.centromere.gff3 -t $value

	# clean up intermediate files
	if [[ $debug == "no" ]]
	then
	#	rm $value.assembly.nuclear_genome.fa
    		rm $value.assembly.nuclear_genome.tidy.fa
    		rm $value.centromere.exonerate.gff
    		rm $value.centromere.gff3.tmp
	fi

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
