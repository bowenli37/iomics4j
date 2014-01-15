#!/usr/bin/env bash

KEGGDIR=$1;
OUTPUTDIR=$2;

cd $KEGGDIR
#ko
perl -ne 'BEGIN{$/=q(///)} $_=~/ENTRY\s+(K\d+)/; print qq(ko:$1\t); $_=~/NAME\s+(.+)/; $name=$1; $name=~s/\t/___/g; print qq($name\t); $_=~/DEFINITION\s+(.*)/; $definition=$1; $definition=~s/\t/___/g; print qq($definition\n)' ko  > ~/github/iomics4j/KEGG/ko_nodedetails
#cpd
perl -ne 'BEGIN{$/=q(///)} $_=~/ENTRY\s+(C\d+)/; print qq(cpd:$1\t); $_=~/NAME\s+(.+)/; $name=$1; $name=~s/\t/___/g; print qq($name\n)' compound  > ~/github/iomics4j/KEGG/cpd_nodedetails
#glycan
perl -ne 'BEGIN{$/=q(///)} $_=~/ENTRY\s+(G\d+)/; print qq(gl:$1\t); $_=~/COMPOSITION\s+(.+)/; $composition=$1; $composition=~s/\t/___/g; print qq($composition\n)' ligand/glycan/glycan > ~/github/iomics4j/KEGG/gl_nodedetails

#merging cpd with glycan 

