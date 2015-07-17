#!/usr/bin/env perl
use strict;
use warnings;
use Memory::Usage;
use Tree::Trie;
use File::Basename;
my $mu = Memory::Usage->new();


$mu->record('starting work');

my $base_dir = shift @ARGV;
die "$base_dir does not exist\n" unless ($base_dir && -s $base_dir);

my $unit = basename($base_dir);

my $fasta = "$base_dir/fasta/$unit.cdhit.fa";
my $blast = "$base_dir/1out/$unit.blast";
my $out   = "$base_dir/1out/1.out";

unless(-s $fasta){
	die "$fasta not found!\n";
}

if(-s $out){
#	die "$out already exists!\n";
}

my %sequence_lengths;
open F, $fasta or die $!. "$fasta\n";
#Get lengths of sequences
my $current_sequence;
while(my $line = <F>){
	chomp $line;
	if(substr($line,0,1) eq ">"){
		$current_sequence = substr($line,1);
		$sequence_lengths{$current_sequence} = 0; #Reset in case of duplicates
	}
	else{
		$sequence_lengths{$current_sequence} += length $line;
	}	
}
close F;

#Start filtering
my $trie =  new Tree::Trie;

my $records = 75000;
my $count;

open O, ">$out.tmp" or die $!. "\nCannot open $out\n";
open F, $blast or die $! . "$blast\n";
while(my $line = <F>){
	chomp $line;
	my @line = split /\t/, $line;
	my $sequenceA = $line[0];
	my $sequenceB = $line[1];
	if( $trie->lookup("$sequenceA$sequenceB") || $trie->lookup("$sequenceB$sequenceA") ){
		next;	
	}
	else{
		$trie->add("$sequenceA$sequenceB");
		my $id = $line[2] / 100;

		print O join "\t", 
		      $sequenceA, $sequenceB,
		      $line[11],
		      ( $sequence_lengths{$sequenceA} * $sequence_lengths{$sequenceB} ), 
		      $line[3], $id, $line[6], $line[7], $line[8], $line[9],
		      $sequence_lengths{$sequenceA} , $sequence_lengths{$sequenceB}; 
		print O "\n";

		$count++;
		if($count eq $records){
			$count = 0;
			$mu->record("after $sequenceA v $sequenceB");
			my $dump = $mu->dump();
			print STDERR $dump;
			$mu = Memory::Usage->new();	
		}	


	}
}
close F;
print STDERR "printed $out completed for $base_dir\n";
close O;
system("mv $out.tmp $out");

