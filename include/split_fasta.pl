#!/usr/bin/perl
#split_fasta.pl version 1.0

use strict;
use warnings;

#Command line processing.
use Getopt::Long;
my $fasta;
my $prefix;
my $sequences_per_file;

Getopt::Long::Configure ('bundling');
GetOptions (
		'i|fasta=s' => \$fasta,
		'o|prefix=s' => \$prefix,
		'n|number=i' => \$sequences_per_file);


foreach my $input($fasta,$prefix,$sequences_per_file){
	if(!defined $input){
		die ("Usage: split_fasta.pl -i <input file> -o <output file prefix> -n <number of sequences to write per file>\n");
	}
}

open F, $fasta or die $!;

my $file_count = 0;
my $sequence_count = 0;

my $output = $prefix . "_" . $file_count;
open O, ">$output" or die $!;
print "About to print to $output\n";

while ( my $line = <F>)
{
	if(substr($line,0,1) eq ">"){
		$sequence_count++;
		if($sequence_count > $sequences_per_file){
			$sequence_count = 1;
#			print "$sequence_count and filehandle $output\n";
			$file_count++;
	
			$output = $prefix . "_" . $file_count;	
			open O ,">$output" or die $!;

			print "About to print to $output\n";
		}
#		print "$sequence_count and filehandle $output\n";
	
	}

	print O $line;
}
#if($sequence_count == 0){
#	unlink($output);
#
#}
close O;
close F;
