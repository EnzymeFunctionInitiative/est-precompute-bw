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
my $alphabetized = "$dir/1out/$unit.alphabetized";
my $alphabetized_and_sorted = "$dir/1out/$unit.alphabetized.sorted";

if(!-s $alphabetized){
	die "Cannot sort, $alphabetized does not exist!";
}

if(-s $alphabetized_and_sorted){
	die "$alphabetized_and_sorted already exists";
}

my $command = "sort -S 90% -T ~/scratch/tmp --parallel=32 -k1,1 -k2,2 -k5,5nr -t\$'\t' $alphabetized > $alphabetized_and_sorted.tmp";
system($command);
print "About to move $alphabetized_and_sorted.tmp to $alphabetized_and_sorted";
system("mv $alphabetized_and_sorted.tmp $alphabetized_and_sorted");



#Print time
my $end = time();
open O, ">$dir/1out/alphabetize_and_sorted.time" or die $!;
printf O ("%.3f\n", $end - $start);
close O;


