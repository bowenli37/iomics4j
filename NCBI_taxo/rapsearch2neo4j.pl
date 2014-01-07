#!/usr/bin/env perl 
use strict;
use DBI;

if($#ARGV != 2) { print "Usage: rapsearch2neo4j.pl rapsearchfile output.tsv location.of.db.file\n"; exit;} #rmbr to trim away the headers including the column names

#connecting to DB
my $dbh = DBI->connect(
        "dbi:SQLite:dbname=$ARGV[2]","","",  #db file, user, pwd #NOTE INCOMPLETE, the location of the db shd be in the same directory as this script or at least be usr definable 
        { RaiseError => 1 }) || die $DBI::errstr;

#accepted input format (rapsearch)
#HWI-ST884:57:1:1101:13989:75421#0/1     gi|163754271|ref|ZP_02161394.1| 56.6667 30      13      0   99       10      55      84      -0.14   37.7354

open(EDGES, "> $ARGV[1]") || die $!; #OUTPUT
print EDGES "readid:string:readID\ttaxid:int:ncbitaxid\tlogevalue\tbitscore\tpair\n";

open(INPUT, "$ARGV[0]") || die $!; 
while(<INPUT>) { 
if(/ref/){
chomp;
my @a=split("\t");

$a[0]=~/(^.+)\/(\d)$/;
my $readID=$1;
my $pair=$2;

$a[1]=~/^gi\|(\d+)/;
my $giid=$1;

#getting the taxid from the giid in rapsearch
my $sth = $dbh->prepare("select taxid from gi2taxid where gi=$giid;");
            $sth->execute();
	    my $taxid= $sth->fetchrow();

if ($taxid ne '') { 
    my $identity=$a[2];
    my $logevalue=$a[10];
    my $bitscore=$a[11];
    print EDGES "$readID\t$taxid\t$logevalue\t$bitscore\t$pair\n";
}}} 
