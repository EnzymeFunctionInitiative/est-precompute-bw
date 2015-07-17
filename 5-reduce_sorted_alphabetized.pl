#!/usr/bin/env perl
#Author Boris Sadkhin
#Summary : Wrapper for Dan's scripts
#filter a sorted and alphabetized blast

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

my $input = "$dir/1out/$unit.alphabetized.sorted";
my $output = "$dir/1out/$unit.unsorted.1out";
if(!-s $input){
	die "couldn't find $input\n";
}
if(-s $output){
	chomp(my $seconds = `cat $output.time`);
	die "$output already exists! No need to sort (time = $seconds)\n";
}

open(BLASTFILE,$input) or die "Could not open blast input $input\n";
open(OUT,">$output.tmp") or die "Could not write to $output\n";
my $first="";
my $second="";

while (my $line=<BLASTFILE>){
  chomp $line;
  $line=~/^(\w+)\t(\w+)/;
  unless($1 eq $first and $2 eq $second){
    print OUT "$line\n";
    $first=$1;
    $second=$2;
  }
}
close BLASTFILE;
close OUT;
system("mv $output.tmp $output");


#Print time
my $end = time();
open O, ">$output.time" or die $!;
printf O ("%.3f\n", $end - $start);
close O;


#"sort -T $sortdir -k 12,12 -nr -t\$\'\\t\' $ENV{PWD}/$tmpdir/unsorted.blastfinal.tab >$ENV{PWD}/$tmpdir/blastfinal.tab\n";
