#!/usr/bin/env perl
#Author  Boris Sadkhin
#Summary : Wrapper for Dan's script for blast reduce 
# This sorts an alphabetized file
use strict;
use File::Basename;
use Time::HiRes qw( time );
my $start = time();

my $dir = shift;
if(!$dir || not -s $dir){
	die "$dir does not exist";
}
my $unit = basename($dir);
my $reduced = "$dir/1out/$unit.unsorted.1out";
my $reduced_sorted = "$dir/1out/$unit.multiplexed.1out";

if(!-s $reduced){
	die "Cannot sort, $reduced does not exist!";
}

if(-s $reduced_sorted){
	die "$reduced_sorted already exists";
}

#my $command = "sort -S 90% --parallel=30 -k5,5nr -t\$'\t' $reduced > $reduced_sorted.tmp";
#my $command = "sort -T /u/sciteam/sadkhin/scratch/tmp -S 20% --parallel=8 -k5,5nr -t\$'\t' $reduced > $reduced_sorted.tmp";
my $command = "sort -T /u/sciteam/sadkhin/scratch/tmp -S 90% --parallel=32 -k5,5nr -t\$'\t' $reduced > $reduced_sorted.tmp";
print "Command = $command\n";
system("$command; mv $reduced_sorted.tmp $reduced_sorted");
print "Created $reduced_sorted\n";



#Print time
my $end = time();
open O, ">$dir/1out/1out.time" or die $!;
printf O ("%.3f\n", $end - $start);
close O;


