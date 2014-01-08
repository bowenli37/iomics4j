
KEGGDIR=$1;
OUTPUTDIR=$2;

cd $KEGGDIR
#ko
perl -ne 'BEGIN{$/=q(///)} $_=~/ENTRY\s+(K\d+)/; print qq(ko:$1\t); $_=~/NAME\s+(.+)/; $name=$1; $name=~s/\t/___/g; print qq($name\t); $_=~/DEFINITION\s+(.*)/; $definition=$1; $definition=~s/\t/___/g; print qq($definition\n)' ko  > ~/github/iomics4j/KEGG/ko_nodedetails
#cpd
perl -ne 'BEGIN{$/=q(///)} $_=~/ENTRY\s+(C\d+)/; print qq(cpd:$1\t); $_=~/NAME\s+(.+)/; $name=$1; $name=~s/\t/___/g; print qq($name\n)' compound  > ~/github/iomics4j/KEGG/cpd_nodedetails
