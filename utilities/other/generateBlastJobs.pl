#!/usr/bin/env perl
#Author Boris Sadkhin
#Date last modified, August 7, 2014
#Date Created Aug 11, 2014
#Summary : Create a list of files for 4-family_blast.pl experiments.  
use strict;
use FindBin;
use lib "$FindBin::Bin/../include/";
require 'config.pl';

my $annotation_type = shift;
my $base_dir      = Config::getPath('base_dir');
my $data_dir      = Config::getPath('scratch_data');
if(!$annotation_type){
	die "Input an annotation type";

}
my $list_directory = "$base_dir/lists/$annotation_type";
my $output_directory = "$list_directory/blast";
my $list = "$list_directory/list.scheduler";


mkdir($output_directory);
open F, "$list_directory/experiment.list" or die $!;


#First 223 clans can be done with 32 processers
#So estimated to be 20,000

#Then 223 to 450 took two 8 core blasts on 400 nodes (114833 sequences)

my @bins = (25000,100000,150000,200000,300000,400000,500000,600000,700000,800000,900000,1000000);

chomp (my $ls = `ls $output_directory | wc -l`);
if($ls > 0){
	die "Please remove all blast files from\n $output_directory\n";

}



while(<F>){
	chomp;
	my $dir = "$data_dir/$annotation_type/$_/fasta/split";
	if(!-s $dir){
		next;
	}
	my $sequence_count_estimate = `ls $dir | wc -l` * 100;

	
	my $filename;


	
	foreach my $bin(@bins){
		if($sequence_count_estimate <= $bin){
			$filename = $bin;
			last;
		} 
		else{
			$filename = 'too_large';
		}
	}
	print "$dir\t$sequence_count_estimate\t$filename\n";	
	
	open O , ">>$output_directory/$filename" or die $!;
        print O  `ls -d -1 $dir/*`;	
	close O;
}
close F;






