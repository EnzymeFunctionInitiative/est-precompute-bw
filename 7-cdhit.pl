#!/usr/bin/env perl
use strict;
use File::Basename;


my $threads=32;
print "EXPORTING export OMP_NUM_THREADS=$threads\n";
system("export OMP_NUM_THREADS=$threads");
$ENV{'OMP_NUM_THREADS'}=$threads;

die "No Input" unless(scalar @ARGV > 0);

my $dir   = shift @ARGV;
my $unit  = basename($dir);
my $multiplexed_fasta = "$dir/fasta/$unit.cdhit.fa";
my $original_fasta = "$dir/fasta/$unit.fa.renamed";
my $multiplexed_cdhit_dir = "$dir/cdhit/multiplexed";
my $original_cdhit_dir = "$dir/cdhit/demultiplexed";

if(not -s "$multiplexed_fasta"){
	die "$multiplexed_fasta does not exist";
}
if(not -s "$original_fasta"){
	die "$original_fasta does not exist";
}
mkdir("$dir/cdhit");
mkdir($multiplexed_cdhit_dir);#; or die "Cannot make directory $multiplexed_cdhit_dir";
mkdir($original_cdhit_dir);#; or die "Cannot make directory";

#CDHIT for each percentage, creating a dir for multiplexed and
my @percentages = reverse(40,45,50,55,60,65,70,75,80,85,90,95,98,100);
foreach my $fasta($multiplexed_fasta,$original_fasta){
	foreach my $percentage(@percentages){
		my $decimal = $percentage / 100;

		my $output = "$unit-$percentage.fa";

		if($fasta eq $multiplexed_fasta){
			$output = "$multiplexed_cdhit_dir/$output";
		}
		else{
			$output = "$original_cdhit_dir/$output";
		}
		if(not -s $fasta){
			die "$fasta does not exist\n";
		}
		if(-s "$output.clstr"){
			print "Skipping $percentage percent for  $output ,it already exists\n";
			next;
		}
		my $call = "cd-hit -i $fasta -o $output.tmp -n 2 -c $decimal -d 0 -T $threads -M 0";
		my $export = "export OMP_NUM_THREADS=$threads;";	
		print $call,"\n";
		system("export OMP_NUM_THREADS=$threads; echo OMP=\$OMP_NUM_THREADS ;  ");
		system($call);
		system("mv $output.tmp $output\n");
		system("mv $output.tmp.clstr  $output.clstr"); 
	}
}
