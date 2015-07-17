#!/usr/bin/env perl
#Author Boris Sadkhin
#Date last modified, August 7, 2014
#Date Created May 30, 2014
#Modified March 30, 2015
#Summary : Create a list of files to be blasted based on size. 
#Summary : NEW: Create a list of scheduler.x files. 
use strict;
use FindBin;
use lib "$FindBin::Bin/include/";
require 'config.pl';

my $annotation_type = shift;
my $f = shift;
my $base_dir      = Config::getPath('base_dir');
my $data_dir      = Config::getPath('scratch_data');
my $list_directory= Config::getPath('lists_dir') . "/$annotation_type";
mkdir('blast_stats');
my $stats = "blast_stats/bin_members";


if(!$annotation_type){
	die "Input an annotation type";

}
my $blast_list_directory = "$list_directory/blast";
my $scheduler_x_directory = "$list_directory/scheduler.x";

my $list_of_units = "$list_directory/list.sorted";


mkdir($blast_list_directory);
mkdir($scheduler_x_directory);


#First 223 clans can be done with 32 processers
#So estimated to be 20,000

#Then 223 to 450 took two 8 core blasts on 400 nodes (114833 sequences)

#I want 50 jobs between 1 and 50,000 sequences
#I want 50 jobs between 50,000 sequences and 600,000 sequences

my @bins;
for(my $i=1000 ; $i<100000; $i+=1000){
	push @bins, $i;
}
for(my $i=101000; $i <= 1100000 ; $i+=10000){
	push @bins, $i;

}
#my @bins = (1000,2500,5000,10000,25000,50000,75000,90000,100000,150000,200000,250000,300000,400000,500000,600000,700000,800000,900000,1000000);

chomp (my $ls_sched = `ls $scheduler_x_directory | wc -l`);
chomp (my $ls_blast = `ls $blast_list_directory | wc -l`);
if($ls_sched > 0 || $ls_blast > 0){
	if(defined $f){
		use File::Path qw(rmtree);
		rmtree($blast_list_directory);
		rmtree($scheduler_x_directory);
		mkdir($blast_list_directory);
		mkdir($scheduler_x_directory);
	}else{
		die "Please remove all blast files from\n".
			"$blast_list_directory ($ls_sched files)\n".
			"$scheduler_x_directory ($ls_blast files) or add 'f' to force delete \n";
	}
}

# a split directory has a fasta file that has been split into many parts
#This section goes through each split directory, counts the number of files and multiplies by 100
#It also creates a list for the scheduler.x directory
print "Opening $list_of_units\n";
open F, "$list_of_units" or die "$list_of_units $! ";
my $count =0;
my %stats;
while(<F>){
	last if($. == 6000);
	chomp;
	chomp;
	$count++;
	my $dir = "$data_dir/$annotation_type/$_/fasta/split";
	if(!-s $dir){
		next;
	}
#print "Estimated sequence count for $dir\n";
	my @units = split "\n", `ls $dir | grep \.fa\$`;
	chomp(my $seq_count = "LC_ALL=C fgrep -c '>' $dir/$_-0.fa");
	my $sequence_count_estimate = scalar @units * $seq_count;

	print "$_\t$dir\t$sequence_count_estimate\t$count\n";	
	

	my $filename;
	foreach my $bin(@bins){
		if($sequence_count_estimate <= $bin){
			$filename = $bin;
			last;
			push @{$stats{$bin}}, $_;
		}
	}
	if(!$filename){
		$filename = 'too_large';
	}
	
	open O , ">>$blast_list_directory/$filename" or die $!;
	open X , ">>$scheduler_x_directory/$filename" or die $!;
	
#Prepend directory and print list of blast jobs
	foreach my $unit(@units){
		print O	"$dir $dir/$unit\n";
	}
	print X "$data_dir/$annotation_type/$_/ $data_dir/$annotation_type/$_/\n";
	close X;	
	close O;
}
close F;

open F , ">$stats" or die $!;
foreach my $bin (sort {$a <=> $b} keys %stats){
	print F "$bin\t" . (join ",", @{$stats{$bin}}) . "\n"; 
}
close F;




