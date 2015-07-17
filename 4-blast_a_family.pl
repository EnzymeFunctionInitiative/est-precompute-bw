#!/usr/bin/env perl
#Author Boris Sadkhin
#Date last modified, August 7, 2014
#Date Created May 30, 2014
#Summary : Blast a chunk against a database 
use strict;
use FindBin;
use File::Basename;
use File::Path;
use lib "$FindBin::Bin/include/";
require 'config.pl';

use Time::HiRes qw( time );

my $start = time();



#/u/sciteam/sadkhin/scratch/release5/pfam/PF02629/fasta/split/PF02629.fa_0

#Get chunk, and based on chunk, get family and dir name
#Setup blast directory 
#Setup blast bin
#Get B value of database.

my $chunk = shift;
my $chunk_name = basename($chunk);
my $family = basename($chunk);
$family =~ s/-[0-9]+\.fa//g;
my $dir = dirname(dirname(dirname($chunk)));
my $database = "/tmp/$family.cdhit.fa";
my $blast_dir = "$dir/blast";
my $output = "$blast_dir/$chunk_name.blast";

#Prepare blast dir and check for existence of files
mkdir($blast_dir);
foreach my $file($chunk,$database){
	die "$file does not exist\n" unless (-s $file);
}
if(-s $output){
	die "Skipping $output it already exists\n";
}
#Count members
print "Counting members of $database";
chomp(my $b = `LC_ALL=C fgrep ">" $database  | wc -l`);
print " ($b) \n";
if($b == 0){
	die "Something went wrong! There are 0 members in the database! $database";
}
#Create Call
my $blastall = '/u/sciteam/sadkhin/bin/blast-2.2.26/bin/blastall';
my $call = "$blastall -p blastp -b $b  -m8 -e 1e-5 -d $database -i $chunk -o $output.tmp";
my $c = ("sh /mnt/a/u/sciteam/sadkhin/memprof/memprof.sh '$dir/memprof/blast/$chunk_name' '$call'; mv $output.tmp $output");

print "=" x 100;
print "\n";
print "About to blast against $database\n";
print $c;

#my $c = ("$call; mv $output.tmp $output");
system($c);
my $end = time();

open O, ">$output.time" or die $!;
printf O ("%.2f\n", $end - $start);
close O;

