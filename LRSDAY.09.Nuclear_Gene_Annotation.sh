#!/bin/bash
# set -e -o pipefail
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
genome_assembly_1="/home/lab/LRSDAY-v1.7.2/Project_Ckefyr/07.Supervised_Final_Assembly/A1/A1.assembly.final.fa" # The path of the input genome assembly.
genome_assembly_2="/home/lab/LRSDAY-v1.7.2/Project_Ckefyr/07.Supervised_Final_Assembly/A2/A2.assembly.final.fa"
genome_assembly_3="/home/lab/LRSDAY-v1.7.2/Project_Ckefyr/07.Supervised_Final_Assembly/A3/A3.assembly.final.fa"
genome_assembly_4="/home/lab/LRSDAY-v1.7.2/Project_Ckefyr/07.Supervised_Final_Assembly/A44/A44.assembly.final.fa"
genome_assembly_5="./../A45_CSFP200002134-1a_H3N7LDSXY_L1.fasta"
genome_assembly_6="./../A53_CSFP200002104-1a_H3N7LDSXY_L1.fasta"
genome_assembly_7="./../A57_CSFP200004698-1a_H3LKHDSXY_L1.fasta"
genome_assembly_8="./../A60_CSFP200002135-1a_H3N7LDSXY_L1.fasta"
genome_assembly_9="./../A69_CSFP200002142-1a_H3LFKDSXY_L1.fasta"
genome_assembly_10="./../A71_CSFP200002144-1a_H3LFKDSXY_L1.fasta"
genome_assembly_11="./../C2_CSFP200002111-1a_H3N7LDSXY_L1.fasta"
genome_assembly_12="./../D2_CSFP200004703-1a_H3LKHDSXY_L1.fasta"
chrMT_tag="chrMT" # The sequence name for the mitochondrial genome in the final assembly. If there are multiple sequences, use a single ';' to separate them. e.g. "chrMT_part1;chrMT_part2". Default = "chrMT".
threads=8 # The number of threads to use. Default = "8".
#maker_opts="$LRSDAY_HOME/miisc/maker_opts.customized.ctl" # The configuration file for MAKER. You can edit this file if you have native transciptome/EST data for the strain/species that you sequenced or if you want to adapt it to annotate other eukaryotic organisms. Otherwise, please keep it unchanged. Please note that if this file is in the same directory where this bash script is executed, the file name cannot be "maker_opts.ctl".
EVM_weights="$LRSDAY_HOME/misc/EVM_weights.customized.txt" # The configuration file for EVM. A list of numeric weight values to be applied to each type of evidence.
debug="no" # use "yes" if prefer to keep intermediate files, otherwise use "no".

#######################################
# process the pipeline

for i in $(seq 1 1 $number_of_genome_assemblies)
do
    prefix="prefix_$i"
    genome_tag="${!prefix}"
    #seq_assembly="genome_assembly_$i"
    genome_assembly="/home/lab/LRSDAY-v1.7.2/Project_Ckefyr/07.Supervised_Final_Assembly/$genome_tag/$genome_tag.assembly.final.fa"
    mkdir $genome_tag
    cd $genome_tag
    
	maker_opts="$LRSDAY_HOME/misc/maker_opts.customized_albicans.ctl"
	echo "genome_tag=$genome_tag"
	echo "genome_assembly=$genome_assembly"

# convert the genome assembly file to all uppercases

#echo $chrMT_tag | sed -e "s/;/\n/g" > $genome_tag.assembly.chrMT.list
	#perl $LRSDAY_HOME/scripts/select_fasta_by_list.pl -i $genome_assembly -l $genome_tag.assembly.chrMT.list -m reverse -o $genome_tag.assembly.nuclear_genome.fa
# perl $LRSDAY_HOME/scripts/select_fasta_by_list.pl -i $genome_assembly -l $genome_tag.assembly.chrMT.list -m normal -o $genome_tag.assembly.mitochondrial_genome.fa
	perl $LRSDAY_HOME/scripts/tidy_fasta.pl -i $genome_assembly -o $genome_tag.assembly.nuclear_genome.tidy.fa

	cp $maker_opts maker_opts.ctl
	cp $LRSDAY_HOME/misc/maker_exe.ctl .
	cp $LRSDAY_HOME/misc/maker_bopts.ctl .
	cp $LRSDAY_HOME/misc/maker_evm.ctl .

	$maker_dir/maker -fix_nucleotides -genome $genome_tag.assembly.nuclear_genome.tidy.fa -cpus $threads -base $genome_tag

	# $maker_dir/fasta_merge -d $genome_tag.maker.output/${genome_tag}_master_datastore_index.log -o $genome_tag.nuclear_genome.maker.fasta
	$maker_dir/gff3_merge -d $genome_tag.maker.output/${genome_tag}_master_datastore_index.log -n -g -o $genome_tag.nuclear_genome.maker.raw.gff3
	perl $LRSDAY_HOME/scripts/collect_maker_evidences.pl -t $genome_tag -p $genome_tag.nuclear_genome
	cat $genome_tag.nuclear_genome.maker.raw.gff3 |egrep "=trnascan" > $genome_tag.nuclear_genome.maker.raw.tRNA.gff3
	# cat $genome_tag.nuclear_genome.maker.raw.gff3 |egrep "=snoscan" > $genome_tag.nuclear_genome.maker.raw.snoscan.gff3 # developmental feature
	cat $genome_tag.nuclear_genome.maker.raw.gff3 |egrep -v "=trnascan"|egrep -v "=snoscan" > $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.gff3

	# use EVM to further polishing the annotation for multi-exon genes
	perl $LRSDAY_HOME/scripts/filter_gff3_for_single_exon_genes.pl -i $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.gff3 -o $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.single_exon_gene.gff3

	$bedtools_dir/bedtools intersect -v  -a $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.gff3 \
			       -b $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.single_exon_gene.gff3 \
			       > $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.multiple_exon_gene.gff3
	$bedtools_dir/bedtools intersect -v  -a $genome_tag.nuclear_genome.protein_evidence.gff3 \
			       -b $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.single_exon_gene.gff3 \
			       > $genome_tag.nuclear_genome.protein_evidence.for_gene_model_refinement.gff3
	$bedtools_dir/bedtools intersect -v  -a $genome_tag.nuclear_genome.est_evidence.gff3 \
			       -b $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.single_exon_gene.gff3 \
			       > $genome_tag.nuclear_genome.est_evidence.for_gene_model_refinement.gff3

	perl $LRSDAY_HOME/scripts/exonerate2gene_maker.pl -i $genome_tag.nuclear_genome.protein_evidence.for_gene_model_refinement.gff3 -o $genome_tag.nuclear_genome.protein_evidence.complementary_gene_model.gff3 
	perl $LRSDAY_HOME/scripts/exonerate2gene_maker.pl -i $genome_tag.nuclear_genome.est_evidence.for_gene_model_refinement.gff3 -o $genome_tag.nuclear_genome.est_evidence.complementary_gene_model.gff3

	cat $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.gff3 $genome_tag.nuclear_genome.protein_evidence.complementary_gene_model.gff3 $genome_tag.nuclear_genome.est_evidence.complementary_gene_model.gff3 > $genome_tag.nuclear_genome.maker.combined.gff3

	mkdir $genome_tag.nuclear_genome.EVM.output
	cd $genome_tag.nuclear_genome.EVM.output
	$EVM_HOME/EvmUtils/partition_EVM_inputs.pl \
	    --genome ./../$genome_tag.assembly.nuclear_genome.tidy.fa \
	    --gene_predictions ./../$genome_tag.nuclear_genome.maker.combined.gff3 \
	    --protein_alignments ./../$genome_tag.nuclear_genome.protein_evidence.gff3 \
	    --transcript_alignments ./../$genome_tag.nuclear_genome.est_evidence.gff3 \
	    --segmentSize 100000 \
	    --overlapSize 10000 \
	    --partition_listing $genome_tag.nuclear_genome.partitions_list.out

	$EVM_HOME/EvmUtils/write_EVM_commands.pl \
	    --genome ./../$genome_tag.assembly.nuclear_genome.tidy.fa \
	    --weights $EVM_weights  \
	    --gene_predictions ./../$genome_tag.nuclear_genome.maker.combined.gff3 \
	    --output_file_name $genome_tag.nuclear_genome.evm.out \
	    --partitions $genome_tag.nuclear_genome.partitions_list.out \
	    > $genome_tag.nuclear_genome.commands.list

	$EVM_HOME/EvmUtils/execute_EVM_commands.pl $genome_tag.nuclear_genome.commands.list | tee $genome_tag.nuclear_genome.EVM_run.log
	$EVM_HOME/EvmUtils/recombine_EVM_partial_outputs.pl \
	    --partitions $genome_tag.nuclear_genome.partitions_list.out \
	    --output_file_name $genome_tag.nuclear_genome.evm.out
	$EVM_HOME/EvmUtils/convert_EVM_outputs_to_GFF3.pl \
	    --partitions $genome_tag.nuclear_genome.partitions_list.out \
	    --output $genome_tag.nuclear_genome.evm.out \
	    --genome ./../$genome_tag.assembly.nuclear_genome.tidy.fa

	perl $LRSDAY_HOME/scripts/collect_EVM_gff3.pl -p $genome_tag.nuclear_genome  -r ./../$genome_tag.assembly.nuclear_genome.tidy.fa

	cat $genome_tag.nuclear_genome.EVM.raw.gff3 ./../$genome_tag.nuclear_genome.maker.raw.tRNA.gff3 > $genome_tag.nuclear_genome.EVM.raw.with_tRNA.gff3
	perl $LRSDAY_HOME/scripts/tidy_maker_gff3.pl \
	    -i $genome_tag.nuclear_genome.EVM.raw.with_tRNA.gff3 \
	    -r ./../$genome_tag.assembly.nuclear_genome.tidy.fa \
	    -t $genome_tag \
	    -o $genome_tag.nuclear_genome.EVM.gff3
	cp $genome_tag.nuclear_genome.EVM.gff3 ./../$genome_tag.nuclear_genome.gff3
	cd ..

	perl $LRSDAY_HOME/scripts/extract_cds_from_tidy_gff3.pl \
	    -r $genome_tag.assembly.nuclear_genome.tidy.fa \
	    -g $genome_tag.nuclear_genome.gff3 \
	    -o $genome_tag.nuclear_genome.cds.fa
	perl $LRSDAY_HOME/scripts/cds2protein.pl \
	    -i $genome_tag.nuclear_genome.cds.fa \
	    -p $genome_tag.nuclear_genome \
	    -t 1


	# filtered out snoRNA annotation since it is still an experimental features suffering from redundant annotations
	cp $genome_tag.nuclear_genome.gff3 $genome_tag.nuclear_genome.gff3.tmp
	cat $genome_tag.nuclear_genome.gff3.tmp | egrep -v "snoRNA" > $genome_tag.nuclear_genome.snoRNA_filtered.gff3
	perl $LRSDAY_HOME/scripts/label_pseudogene_in_gff3.pl -i $genome_tag.nuclear_genome.snoRNA_filtered.gff3 -l $genome_tag.nuclear_genome.manual_check.list -o $genome_tag.nuclear_genome.gff3

	perl $LRSDAY_HOME/scripts/extract_cds_from_tidy_gff3.pl \
	    -r $genome_tag.assembly.nuclear_genome.tidy.fa \
	    -g $genome_tag.nuclear_genome.gff3 \
	    -o $genome_tag.nuclear_genome.cds.fa
	perl $LRSDAY_HOME/scripts/cds2protein.pl \
	    -i $genome_tag.nuclear_genome.cds.fa \
	    -p $genome_tag.nuclear_genome \
	    -t 1

	perl $LRSDAY_HOME/scripts/prepare_PoFFgff_simple.pl -i $genome_tag.nuclear_genome.gff3 -o $genome_tag.nuclear_genome.PoFF.gff 
	perl $LRSDAY_HOME/scripts/prepare_PoFFfaa_simple.pl -i $genome_tag.nuclear_genome.trimmed_cds.fa -o $genome_tag.nuclear_genome.PoFF.ffn 
	perl $LRSDAY_HOME/scripts/prepare_PoFFfaa_simple.pl -i $genome_tag.nuclear_genome.pep.fa -o $genome_tag.nuclear_genome.PoFF.faa

	# clean up intermediate files
	if [[ $debug == "no" ]]
	then
	#    rm $genome_tag.assembly.nuclear_genome.fa
	    rm $genome_tag.nuclear_genome.maker.raw.tRNA.gff3
	    rm $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.gff3
	    rm $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.single_exon_gene.gff3
	    rm $genome_tag.nuclear_genome.maker.raw.protein_coding_gene.multiple_exon_gene.gff3
	    rm $genome_tag.nuclear_genome.protein_evidence.for_gene_model_refinement.gff3
	    rm $genome_tag.nuclear_genome.est_evidence.for_gene_model_refinement.gff3
	    rm $genome_tag.nuclear_genome.protein_evidence.complementary_gene_model.gff3
	    rm $genome_tag.nuclear_genome.est_evidence.complementary_gene_model.gff3
	    rm $genome_tag.nuclear_genome.gff3.tmp
	    rm $genome_tag.nuclear_genome.maker.combined.gff3
	    rm $genome_tag.nuclear_genome.snoRNA_filtered.gff3
	    rm -rf _Inline
	    rm *.ctl
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
