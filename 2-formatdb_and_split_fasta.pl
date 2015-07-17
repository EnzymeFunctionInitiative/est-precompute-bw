#!/usr/bin/env perl
#Author Boris Sadkhin
#Date Created March 31, 2015
#Date modified March 31, 2015

#Summary : Format a blast database for a given cdhit database. 
#Summary : Split families into chunks of 100 sequences for blast
#There is not a good way to check if the files were split or the formatdb succesfully finished
use strict;
use FindBin;
use List::MoreUtils qw(uniq);
use lib "$FindBin::Bin/include/";
use File::Basename;
use File::Path qw(mkpath rmtree);
my $dir = shift @ARGV;
my $family = basename($dir);
my $cdhit_fasta = "$dir/fasta/$family.cdhit.fa";
if(not -s $cdhit_fasta ){
	die "$cdhit_fasta does not exist for $family\n";
}

formatdb();
chunk();

#Creates a protein database
sub formatdb{
#May need to check to see if software exists 
	my $command = "formatdb -pT -i $cdhit_fasta";
	print STDERR "$command\n";
	system($command);
}

#Creates a directory called fasta/split and chunks the fasta file
#100 sequences per file
sub chunk{
	my $split_dir = "$dir/fasta/split";
	rmtree($split_dir);
	mkdir($split_dir);
	open F, $cdhit_fasta or die $!;
	my $sequence_count = 0;
	my $sequences_per_file = 100;
	my $file_count = 0;
	my $output = "$split_dir/$family-$file_count.fa";
	open O, ">$output" or die $!;
	print STDERR "About to print to $split_dir\n";

	while ( my $line = <F>)
	{
		if(substr($line,0,1) eq ">"){
			$sequence_count++;
			if($sequence_count > $sequences_per_file){
				$file_count++;
				$sequence_count = 1;
				$output = "$split_dir/$family-$file_count.fa";
				close O;
				open O ,">$output" or die $!;
				print STDERR "$output\n";
			}
		}
		print O $line;
	}
	close O;
	close F;	
	print STDERR "Printed $file_count chunks to $split_dir\n";
}

