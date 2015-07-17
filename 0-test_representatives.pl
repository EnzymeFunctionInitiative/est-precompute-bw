#!/usr/bin/env perl
use strict;
use File::Basename;

print "EXPORTING export OMP_NUM_THREADS=31\n";
system("export OMP_NUM_THREADS=32");
$ENV{'OMP_NUM_THREADS'}=32;
system("export OMP_NUM_THREADS=32; echo OMP=\$OMP_NUM_THREADS;");

my $dir = shift @ARGV;
die "Input a directory" unless defined $dir;
my $unit_name = (split /\//, $dir)[-1]; 
my $fasta = "$dir/fasta/$unit_name";
my $fasta_name = (-s "$fasta.fa") ? "$fasta.fa" : "$fasta.fa.renamed";
if(-s "$fasta_name.sort"){
	$fasta_name = "$fasta_name.sort";
}

if(! -s $fasta_name){
	die "Couldn't find $fasta_name\n";
}

my $c = ".98";
my $l = 10;
my $s = ".9";
#98 percent similarity with at least 90% length

my @c = qw(.90 .92 .94 .96 .98 1);
my @s = qw(.80 .85 .90 .95 1);

my @c = qw(.98 1);
my @s = qw(.90 1);

foreach my $s(@s){

	foreach my $c(@c){
		
		my $safe_c = $c;
		my $safe_s = $s;
		$safe_s =~ s/\.//g;
		$safe_c =~ s/\.//g;

		
		system("mkdir -p $dir/cdhit_testing/$safe_s");
		my $output = "$dir/cdhit_testing/$safe_s/$unit_name.cdhit.$safe_c-$safe_s.fa";
		if(-s $output){
			print "\n*******$output already exists******\n";
			next;
		}

		my $call = "cd-hit -i $fasta_name -o $output.tmp -n 2 -c $c -s $s -d 0 -T 31 -M 0";
		system($call);

		print $call,"\n";

		if(-s "$output.tmp"){
			print "\n\nSuccess, moving outputs.tmp to output\n\n";
			system("mv $output.tmp $output\n");
			print "Moving $output.tmp.clstr to $output.clstr\n\n";
			system("mv $output.tmp.clstr  $output.clstr"); 
			my $count = "LC_ALL=C fgrep -c '>' $output > $output.count";
			print "$count";
			system($count); 
		}
		else{
			print "$output.tmp was not generated. something went wrong!\n\n";
		}


#	cd-hit -i $ENV{PWD}/$tmpdir/$filter-$minval-$minlen-$maxlen/sequences.fa -o $ENV{PWD}/$tmpdir/$filter-$minval-$minlen-$maxlen/cdhit\$CDHIT -n 3 -c \$CDHIT -d 0\n"

	}

}

