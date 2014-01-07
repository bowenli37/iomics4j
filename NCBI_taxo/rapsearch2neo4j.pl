#!/usr/bin/env perl -l 
use strict;
use DBI;

if($#ARGV != 3) { print "Usage: rapsearch2neo4j.pl rapsearchoutput edges.tsv location.of.db.file\n"; exit;} #rmbr to trim away the headers including the column names

#connecting to DB
my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$ARGV[2]","","",  #db file, user, pwd #NOTE INCOMPLETE, the location of the db shd be in the same directory as this script or at least be usr definable 
        { RaiseError => 1 }) || die $DBI::errstr;

#accepted input format (rapsearch)
#HWI-ST884:57:1:1101:13989:75421#0/1     gi|163754271|ref|ZP_02161394.1| 56.6667 30      13      0   99       10      55      84      -0.14   37.7354

open(EDGES, "> $ARGV[1]") || die $!; #OUTPUT
print EDGES "readid:string:readID\tgi:int:giid\tlogevalue\tbitscore\tpair\n";

open(INPUT, "$ARGV[0]") || die $!; 
while(<INPUT>) { 
if(/ref/){
my @a=split("\t");

$a[0]=~/(^.+)\/(\d)$/;
my $readID=$1;
my $pair=$2;

$a[1]=~/^gi\|(\d+)/;
my $giid=$1;

#checks if gi exists
  my $sth = $dbh->prepare("SELECT COUNT(*) FROM ( SELECT * from gi2taxid where gi=$giid);");
            $sth->execute();
                my $rownum = $sth->fetchrow();
if($rownum != 0) { 
#gets the associated taxid
  my $sth2 = $dbh->prepare("select taxid from gi2taxid where gi=$giid;");

my $taxid= $sth->fetchrow();
my $identity=$a[2];
my $logevalue=$a[10];
my $bitscore=$a[11];
print EDGES "$readID\t$taxid\t$logevalue\t$bitscore\t$pair\n";
}}} 
