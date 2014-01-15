#!/usr/bin/env bash

#Pre-init:: takes all of the nodes eg format below 
#cat ./nodes/*_konodes > combined_redundant_konodeslist 		#commented out cause this is a time consuming process i wouldnt want to do this everytime

####################################################################################################
#NODES
####################################################################################################

#-- KO
rm nodes/newkonodes
for i in `perl -aln -F"\t" -e 'print $F[0]' nodes/*_konodes | sort | uniq | head -n -1 `
do
grep $i combined_redundant_konodeslist | perl -aln -F"\t" -e '$earlier=join("\t",@F[0..3]) if $.==1; push(@pathwayid, $F[4]); push(@pathwayname, $F[5]);END{print qq($earlier\t), join("|", @pathwayid),qq(\t), join("|", @pathwayname)}' >> nodes/newkonodes;
done;
perl -0777 -pi -e 'print qq(ko:string:koid\tname\tdefinition\tl:label\tpathway:string_array\tpathway.name:string_array\n)' nodes/newkonodes
perl -pi -e 's/\"/\\"/g' nodes/newkonodes

#-- CPD
rm nodes/newcpdnodes
cat nodes/*_cpdnodes | sort | uniq >> nodes/newcpdnodes
perl -0777 -pi -e 'print qq(cpd:string:cpdid\tname\tl:label\n)' nodes/newcpdnodes
perl -pi -e 's/\"/\\"/g' nodes/newcpdnodes

#--Pathways
perl -aln -F"\t" -e 'print qq($F[4]\t$F[5]\tpathway) unless $.==1' combined_redundant_konodeslist | sort | uniq > nodes/pathwaynodes
perl -0777 -pi -e 'print qq(pathway:string:pathwayid\tpathwayname\tl:label\n)' nodes/pathwaynodes
####################################################################################################


####################################################################################################
#EDGES
####################################################################################################

#-- ko2cpd, cpd2ko
perl -ne 'BEGIN{print qq(ko:string:koid\tcpd:string:cpdid\trelationship\trxnID\n)}print if !/^ko:string/' <(cat rels/*cpd.rels | sort | uniq) > rels/newcpdrels
perl -ne 'BEGIN{print qq(cpd:string:cpdid\tko:string:koid\trelationship\trxnID\n)}print if !/^cpd:string/' <(cat rels/*ko.rels | sort | uniq) > rels/newkorels

#-- pathway2KO
rm rels/ko2pathwayrels
for i in `perl -aln -F"\t" -e 'print $F[0]' nodes/*_konodes | sort | uniq | head -n -1 `
do
grep $i combined_redundant_konodeslist | perl -aln -F"\t" -e '$ko = $F[0] if $.==1; push(@pathwayid, $F[4]); END{foreach $e (@pathwayid){print qq($ko\t$e\tpathwayed)}}' >> rels/ko2pathwayrels;
done;
perl -0777 -pi -e 'print qq(ko:string:koid\tpathway:string:pathwayid\trelationship\n)' rels/ko2pathwayrels

#Still missing some relationships
#Importing 3614 Nodes took 1 seconds
#Importing 3512 Nodes took 1 seconds
#
#Importing 15847 Relationships skipped (55) took 0 seconds #missing KO data no point
#Importing 15875 Relationships skipped (69) took 0 seconds

#example data:
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00010    Glycolysis / Gluconeogenesis
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00071    Fatty acid metabolism
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00350    Tyrosine metabolism
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00625    Chloroalkane and chloroalkene degradation
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00626    Naphthalene degradation
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00641    3-Chloroacrylic acid degradation
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00830    Retinol metabolism
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00980    Metabolism of xenobiotics by cytochrome P450
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko00982    Drug metabolism - cytochrome P450
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko01100    Metabolic pathways
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko01110    Biosynthesis of secondary metabolites
#ko:K00001       E1.1.1.1, adh   alcohol dehydrogenase [EC:1.1.1.1]      ko      path:ko01120    Microbial metabolism in diverse environments
