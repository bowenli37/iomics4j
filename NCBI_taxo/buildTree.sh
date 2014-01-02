#!/bin/sh

#set the directories
targetdir=/export2/home/uesu/opt/batch-import-20/taxo_index2
mkdir -p $targetdir/nodes
mkdir -p $targetdir/rels
cd $targetdir

taxodump=/export2/home/uesu/downloads/taxonomy

#load taxonomic DUMP from ftp in CWD
wget -P $taxodump -m ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/
taxodump=$taxodump/ftp.ncbi.nlm.nih.gov/pub/taxonomy

unzip $taxodump/gi_taxid_prot.zip -d $taxodump
tar zvxf $taxodump/taxdump.tar.gz 

#cd into the dump directory targetdir
cd $targetdir

#-- NODES
#indexing::::propertyname:fieldtype:indexName##########
#01::taxnodes##########################################
#taxid:int:ncbitaxid     name    l:label
#1       root    rank,no rank
#######################################################
#stores hash table into tempfile
perl -aln -F"\\t\\|\\t" -e 'BEGIN{use Storable} $tax2rank{$F[0]}=$F[2]; END{ store(\%tax2rank,q(tempfile)) }' $taxodump/nodes.dmp
perl -aln -F"\\t\\|\\t" -e 'BEGIN{use Storable; %tax2rank=%{retrieve(q(tempfile))}; print qq(taxid:int:ncbitaxid\tname\tl:label\t)} print qq($F[0]\t$F[1]\t$tax2rank{$F[0]},Taxon) if /scientific name/' $taxodump/names.dmp > nodes/tax_nodes
#####################################################################

#02::ginodes#########################################################
#gi:int:giid
#6
#####################################################################
unzip  $taxodump/gi_taxid_prot.zip -d targetdir/nodes
perl -aln -F"\t" -e 'BEGIN{print qq(gi:int:giid\tl:label)} print qq($F[0]\tgi)' $taxodump/gi_taxid_prot.dmp > nodes/gi_nodes
#####################################################################

#readnodes########################################
#readid:string:readID
#HWI-ST884:124:D0G92ACXX:1:1101:10761:149051
##################################################
perl -aln -F"\t" -e '$F[0]=~s/\/\d+$//; print qq($F[0]\tread)' K01963 | sort | uniq > nodes/read_nodes
perl -0777 -ni -e 'print qq(readid:string:readID\tl:label\n$_)' nodes/read_nodes
####################################################################################################


##################################################################
#-- EDGES
#01::taxid2taxid##################################################
#taxid:int:ncbitaxid     taxid:int:ncbitaxid     relationship
#1       1       child.of
##################################################################
perl -aln -F"\\t\\|\\t" -e 'BEGIN{print qq(taxid:int:ncbitaxid\ttaxid:int:ncbitaxid\trelationship)} print qq($F[0]\t$F[1]\tchildof)' $taxodump/nodes.dmp > rels/tax2tax.rel

#02::gi2taxid##################################################
#gi:int:giid     taxid:int:ncbitaxid link	
#6       9913	link
##################################################################
perl -aln -F"\t" -e 'BEGIN{print qq(gi:int:giid\ttaxid:int:ncbitaxid\tgi2tax)} print qq($F[0]\t$F[1]\tgi2tax)' $taxodump/gi_taxid_prot.dmp > rels/gi2tax.rel

#03::read2gi##########################################################
#readid:string:readID    gi:int:giid     logevalue       bitscore        pair
#HWI-ST884:57:1:1101:13989:75421#0       325954302       0.21    36.5798 1
######################################################################
#pre-initialising::setting up sqlite DB

#executing the gi database
~/opt/rapsearch2neo4j.pl K01963 rels/reads2gi.rel

#Building the graphdb 
#just gi and taxid
mvn clean compile exec:java -Dexec.mainClass="org.neo4j.batchimport.Importer" -Dexec.args="graph.db taxo3/nodes/tax_nodes,taxo3/nodes/gi_nodes,taxo3/nodes/read_nodes taxo3/rels/tax2tax,taxo3/rels/gi2tax.rel,taxo3/rels/reads2gi.rel"

#with reads
mvn clean compile exec:java -Dexec.mainClass="org.neo4j.batchimport.Importer" -Dexec.args="graph.db taxo3/nodes/tax_nodes,taxo3/nodes/gi_nodes,taxo3/nodes/read_nodes taxo3/rels/tax2tax,taxo3/rels/gi2tax.rel,taxo3/rels/reads2gi.rel"

#misc
##
#
##Setting up sqlite::creating tables still need why? cause the perl script needs it
#sqlite3 ''
#
#
#
#
#perl -aln -F"\\t\\|\\t" -e 'print qq($F[0]\t$F[1]\t$F[2])' $taxodump/nodes.dmp > tax2rank
#sqlite3 -separator $'\t' sequencing.output/data/gi_taxid_prot.db ".import 'tax2rank' tax2rank"
#
#perl -aln -F"\\t\\|\\t" -e 'print qq($F[0]\t$F[1]) if /scientific name/' names.dmp > taxid2name
#sqlite3 -separator $'\t' sequencing.output/data/gi_taxid_prot.db ".import 'taxid2name' taxid2name"
#
##Use sqlite to merge 
#sqlite3 -separator $'\t' /export2/home/uesu/sequencing.output/data/gi_taxid_prot.db 'select tax2rank.taxid, name, rank from tax2rank join taxid2name on tax2rank.taxid = taxid2name.taxid' > taxnodes


#perl -aln -i.bak -F"\t" -e 'print qq(taxid:int:ncbitaxid\tname\tl:label) if $.==1; print qq($F[0]\t$F[1]\trank,$F[2])' nodes/tax_nodes
