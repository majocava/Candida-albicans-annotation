#!/bin/bash
set -e -o pipefail
#######################################
# load environment variables for LRSDAY
source ./../../env.sh
PATH=$gnuplot_dir:$PATH

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
dotplot="no" # Whether to plot genome-wide dotplot based on the comparison with the reference genome below. Use "yes" if prefer to plot, otherwise use "no". Default = "yes".
ref_genome_raw="./../00.Reference_Genome/S288C.ASM205763v1.fa" # The path of the raw reference genome, only needed when dotplot="yes" or vcf="yes".
threads=8 # The number of threads to use. Default = 8.
debug="no" # Whether to keep intermediate files for debugging. Use "yes" if prefer to keep intermediate files, otherwise use "no". Default = "no".

#######################################
# process the pipeline
# Please mark desiarable changes in the $prefix.modification.list file and comment the command lines for Step 1 before proceeding with Step 2.

vcf="no" # Whether to generate a vcf file generated to show SNP and INDEL differences between the assembled genome and the reference genome for their uniquely alignable regions. Use "yes" if prefer to have vcf file generated to show SNP and INDEL differences between the assembled genome and the reference genome. Default = "no".
# Step 2:

for i in $(seq 1 1 $number_of_genome_assemblies)
do
    prefix="prefix_$i"
    value="${!prefix}"
    genome_assembly="genome_assembly_$i"
    value_assembly="${!genome_assembly}"
    cd $value

	perl $LRSDAY_HOME/scripts/relabel_and_reorder_sequences.pl -i $value_assembly -m $value.assembly.modification.list -o $value.assembly.relabel_and_reorder.fa
	# generate assembly statistics
	perl $LRSDAY_HOME/scripts/tidy_fasta.pl -i $value.assembly.relabel_and_reorder.fa -o $value.assembly.final.fa
	perl $LRSDAY_HOME/scripts/cal_assembly_stats.pl -i $value.assembly.final.fa -o $value.assembly.final.stats.txt
cd ..
done

# check project-specific variables
if [[ $vcf == "yes" || $dotplot == "yes" ]]
then
    # check if ref_genome_raw is defined
    if [[ -z $ref_genome_raw ]]
    then
        echo "The vcf and doptlot outputs require the variable ref_genome_raw be defined!"
        echo "Please define this variable in the script; Please delete all the old output files and directories; and re-run this step!"
        echo "Script exit!"
        echo ""
        exit
    elif [[ ! -f $ref_genome_raw ]]
    then
        echo "The vcf and doptlot outputs require the $ref_genome_raw as defined with the variable \"ref_genome raw\" but this file cannot be found!"
        echo "Please make sure that this file truly exists; Please delete all the old output files and directories; and re-run this step!"
        echo "Script exit!"
        echo ""
        exit
    else
        ln -s $ref_genome_raw ref_genome.fa
    fi
fi

# make the comparison between the assembled genome and the reference genome
#$mummer4_dir/nucmer -t $threads --maxmatch --nosimplify  -p $prefix.assembly.final  $ref_genome_raw $prefix.assembly.final.fa 
#$mummer4_dir/delta-filter -m $prefix.assembly.final.delta > $prefix.assembly.final.delta_filter

# generate the vcf output
if [[ $vcf == "yes" ]]
then
    $mummer4_dir/show-coords -b -T -r -c -l -d $prefix.assembly.final.delta_filter > $prefix.assembly.final.filter.coords
    $mummer4_dir/show-snps -C -T -l -r $prefix.assembly.final.delta_filter > $prefix.assembly.final.filter.snps
    perl $LRSDAY_HOME/scripts/mummer2vcf.pl -r ref_genome.fa -i $prefix.assembly.final.filter.snps -t SNP -p $prefix.assembly.final.filter
    perl $LRSDAY_HOME/scripts/mummer2vcf.pl -r ref_genome.fa -i $prefix.assembly.final.filter.snps -t INDEL -p $prefix.assembly.final.filter
    $samtools_dir/samtools faidx ref_genome.fa 
    awk '{printf("##contig=<ID=%s,length=%d>\n",$1,$2);}' ref_genome.fa.fai > $prefix.vcf_header.txt
    sed -i -e "/##reference/r $prefix.vcf_header.txt" $prefix.assembly.final.filter.mummer2vcf.SNP.vcf
    sed -i -e "/##reference/r $prefix.vcf_header.txt" $prefix.assembly.final.filter.mummer2vcf.INDEL.vcf
fi

# generate genome-wide dotplot
if [[ $dotplot == "yes" ]]
then
    $mummer4_dir/mummerplot --large --postscript $prefix.assembly.final.delta_filter -p $prefix.assembly.final.filter
    perl $LRSDAY_HOME/scripts/fine_tune_gnuplot.pl -i $prefix.assembly.final.filter.gp -o $prefix.assembly.final.filter_adjust.gp -r ref_genome.fa -q $prefix.assembly.final.fa
    $gnuplot_dir/gnuplot < $prefix.assembly.final.filter_adjust.gp
fi

# clean up intermediate files
if [[ $debug == "no" ]]
then
    rm *.delta
    rm *.delta_filter
    rm ref_genome.fa
    rm $prefix.assembly.relabel_and_reorder.fa

    if [[ $vcf == "yes" ]] 
    then
	rm ref_genome.fa.fai
        rm *.filter.coords
        rm $prefix.vcf_header.txt
        rm $prefix.assembly.final.filter.snps
    fi
    if [[ $dotplot == "yes" ]]
    then
        rm *.filter.fplot
        rm *.filter.rplot
        rm *.filter.gp
        rm *.filter_adjust.gp
        rm *.filter.ps
    fi
fi

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
