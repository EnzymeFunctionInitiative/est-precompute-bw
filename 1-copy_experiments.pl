#!/usr/bin/env perl
use strict;
use File::Basename;

my $dir = shift;
my $unit = basename($dir);
my $cdhit = "$dir/cdhit_testing/90/$unit.cdhit.98-90.fa";
my $cdhit_destination = "$dir/fasta/$unit.cdhit.fa";


die "no $dir or no $cdhit" unless (-s $dir && -s $cdhit);
#if( -s $cdhit_destination){
#	die "$cdhit_destination Already exists\n";
#}


my $command = "cp $cdhit $cdhit_destination.tmp ; mv $cdhit_destination.tmp $cdhit_destination;";
print $command,"\n";
system($command);
