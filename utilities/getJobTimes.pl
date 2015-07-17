#!/usr/bin/env perl
use strict;
die "Input a list of nid files" unless scalar @ARGV  > 0;
my %hash;
while(<>){
	my $bin = `cat $_`;
	chomp $bin;
	$hash{$bin}{'job'} = $_;
	my $tracejob = "tracejob -n 2 $_ grep  -E \"\.nodes|walltime\"";
	print "$tracejob";
	system($tracejob);
	chomp $tracejob;
	$hash{$bin}{'walltime'} = $tracejob;

	print "bin[$bin] walltime=[$tracejob]";
}

