#!/usr/bin/env perl
#Author Boris Sadkhin
#Date Created Oct 31, 2014
#Summary : After concatenate, sort it!
#Should be done on bins to save compute time!
 
use strict;
use FindBin;
use File::Basename;
use Time::HiRes qw( time );
my $start = time();

my $dir = shift;
if(!$dir || not -s $dir){
	die "$dir does not exist";
}
my $unit = basename($dir);

my $input = "$dir/1out/$unit.blast.unsorted";
my $output = "$dir/1out/$unit.blast";
if(!-s $input){
	die "couldn't find $input\n";
}
if(-s $output){
	chomp(my $seconds = `cat $output.time`);
	die "$output already exists! No need to sort (time = $seconds)\n";
}

# set locale and use 
my $command = "LC_ALL=C sort -T ~/scratch/tmp -S 90% --parallel=8 -k 12,12 -nr -t'\t' $input > $output.tmp ; mv $output.tmp $output";
#my $command = "LC_ALL=C sort -k 12,12 -nr -t'\t' --parallel=8 $input > $output.tmp ; mv $output.tmp $output";
print "$command\n";
system($command);

#Print time
my $end = time();
open O, ">$output.time" or die $!;
printf O ("%.3f\n", $end - $start);
close O;


#"sort -T $sortdir -k 12,12 -nr -t\$\'\\t\' $ENV{PWD}/$tmpdir/unsorted.blastfinal.tab >$ENV{PWD}/$tmpdir/blastfinal.tab\n";
