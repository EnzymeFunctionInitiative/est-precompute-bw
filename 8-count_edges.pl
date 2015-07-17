#!/usr/bin/env perl
#Author  Boris Sadkhin
#Date Created Oct 31, 2014
#Summary : Wrapper for Dan's script for blast reduce
use strict;
use File::Basename;
use Time::HiRes qw( time );
my $start = time();

my $dir = shift;
if(!$dir || not -s $dir){
	die "$dir does not exist";
}
my $unit = basename($dir);

my $mux= "$dir/1out/$unit.multiplexed.1out";
my $demux = "$dir/1out/$unit.1out.demultiplexed";
my $fasta = "$dir/fasta/$unit.fa.renamed";
my $cdhit_fasta = "$dir/fasta/$unit.cdhit.fa";

chomp(my $mux_wc = `LC_ALL=C wc -l  < $mux`);
chomp(my $demux_wc = `LC_ALL=C wc -l < $demux`);
chomp(my $fasta_wc = `LC_ALL=C fgrep -c ">" $fasta `);
chomp(my $cdhit_wc = `LC_ALL=C fgrep -c ">" $cdhit_fasta`);
chomp(my $duh_mux = `du -h $mux | cut -f1`);
chomp(my $duh_demux = `du -h $demux | cut -f1`);

my $outfile = ">$dir/1out/edge_counts";

open F, $outfile or die $!;
print F (join "\t", $unit,$fasta_wc,$cdhit_wc,$duh_mux,$duh_demux,$mux_wc,$demux_wc) . "\n";
close F;
print "Printed to $outfile\n"; 

