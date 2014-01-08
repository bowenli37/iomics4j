#AIM:code pathwayID & pathwayNAME into two arrays
#repeat for the last two columns pathwayID & pathwayNAME

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


#Pre-init
#cat ./nodes/*_konodes > combined_redundant_konodeslist
#NODES
#-- KO
for i in `perl -aln -F"\t" -e 'print $F[0]' nodes/*_konodes | sort | uniq | head -n -1 `
do
grep $i combined_redundant_konodeslist | perl -aln -F"\t" -e '$earlier=join("\t",@F[0..3]) if $.==1; push(@pathwayid, $F[4]); push(@pathwayname, $F[5]);END{print qq($earlier\t), join("|", @pathwayid),qq(\t), join("|", @pathwayname)}' >> nodes/newkonodes;
done;
perl -0777 -pi -e 'print qq(ko:string:koid\tname\tdefinition\tl:label\tpathway:string_array\tpathway.name:string_array\n)' nodes/newkonodes
perl -pi -e 's/\"/\\"/g' nodes/newkonodes

#-- CPD
cat nodes/*_cpdnodes | sort | uniq >> nodes/newcpdnodes
perl -0777 -pi -e 'print qq(cpd:string:cpdid\tname\tl:label\n)' nodes/newcpdnodes
perl -pi -e 's/\"/\\"/g' nodes/newcpdnodes

#--Pathways
#----Edges
echo > rels/ko2pathwayrels
for i in `perl -aln -F"\t" -e 'print $F[0]' nodes/*_konodes | sort | uniq | head -n -1 `
do
grep $i combined_redundant_konodeslist | perl -aln -F"\t" -e '$ko = $F[0] if $.==1; push(@pathwayid, $F[4]); END{foreach $e (@pathwayid){print qq($ko\t$e\tpathwayed)}}' >> rels/ko2pathwayrels;
done;
perl -0777 -pi -e 'print qq(ko:string:koid\tpathway:string:pathwayid\trelationship\n)' rels/ko2pathwayrels

#----NODES
perl -aln -F"\t" -e 'print qq($F[1])' rels/ko2pathwayrels | sort| uniq | head -n -1 > nodes/pathwaynodes
perl -0777 -pi -e 'print qq(pathway:string:pathwayid\n)' nodes/pathwaynodes

#EDGES
perl -ne 'BEGIN{print qq(ko:string:koid\tcpd:string:cpdid\trelationship\trxnID\n)}print if !/^ko:string/' <(cat rels/*cpd.rels | sort | uniq) > rels/newcpdrels
perl -ne 'BEGIN{print qq(cpd:string:cpdid\tko:string:koid\trelationship\trxnID\n)}print if !/^cpd:string/' <(cat rels/*ko.rels | sort | uniq) > rels/newkorels

#Still missing some relationships
#Importing 3614 Nodes took 1 seconds
#Importing 3512 Nodes took 1 seconds
#
#Importing 15847 Relationships skipped (55) took 0 seconds #missing KO data no point
#Importing 15875 Relationships skipped (69) took 0 seconds
