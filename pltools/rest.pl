#!/usr/bin/env perl 

#2> /dev/null to shut rest up
use strict;
use REST::Neo4p;
use REST::Neo4p::Query;

my $server='http://metamaps.scelse.nus.edu.sg:7474';
REST::Neo4p->connect($server);

my @array=('path:ko00010','path:ko00061');
foreach my $pathway (@array){
my $stmt='start pathway=node:pathwayid(pathway={ pathwayiid }) return pathway';
my $query = REST::Neo4p::Query->new($stmt,{ pathwayiid=>$pathway });
$query->execute;

while (my $result = $query->fetch) {
print $result->[0]->get_property('pathwayname'),"\n";
}
}
