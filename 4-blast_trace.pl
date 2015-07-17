#!/usr/bin/env perl
use strict;
my $family_type = shift @ARGV;
my $dir = $ENV{'EST_PRECOMPUTE_SCRIPTS'};
die "Input pfam/gene3d/ssf unless " unless defined $family_type;
die "Load EST Module\n" unless defined $dir;

my $blast_job_dir = "$dir/qsub/$family_type/blast/";
my @nids = split "\n", `ls $blast_job_dir | grep nid | grep -e "[0-9]\$"`;

foreach my $nid(@nids){
        
	chomp(my $bin = `cat $blast_job_dir/$nid`);
       # my $tracejob = "tracejob -n 2 $nid | grep -e \"\.nodes|walltime\"";
        #print "$tracejob\n";
        #chomp($tracejob = system("$tracejob 2> /dev/null"));
	my $grep = `tracejob -n 5 $nid 2>/dev/null | grep -E "resources_used.walltime|nodect|Exit_status"`;
	$grep =~ s/ +|\n/ /g;        
	$grep =~ s/ +/ /g;        
	my ($node1,$node2,$exit,$walltime) = split " ", $grep;
	my @resources = split /=/, $node1;
	my $node_numeric = $resources[1];
	my @resources = split /=/, $walltime;
	my @walltime_numeric = split /:/, $resources[1];
	my $walltime_numeric = $walltime_numeric[0];
	if($walltime_numeric < 1){
		$walltime_numeric = 1;
	}
	my $estimate = $walltime_numeric * $node_numeric;

	print "$bin\t$nid\t$node1\t$walltime\t$estimate\t$exit\n"
}
