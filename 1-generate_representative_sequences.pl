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
my $fasta_name = "$dir/fasta/$unit_name.domains.fa";

my $output = "$dir/fasta/$unit_name.cdhit.fa";
if(-s $output){
	print "$output already exists\n";
	die;
}

#Default to domains
if(! -s $fasta_name){
	$fasta_name = "$dir/fasta/$unit_name.fa.renamed";
	if(! -s $fasta_name){
		die  "Couldn't find $fasta_name\n";

	}
}

my $c = "1";
my $l = 10;
my $s = "1";
my $fasta_header_length= 999;
#98 percent similarity with at least 90% length
my $call = "cd-hit -d 999  -i $fasta_name -o $output.tmp -n 2 -c $c -l $l -s $s -d 0 -T 31 -M 0";
system($call);

print $call,"\n";

if(-s "$output.tmp"){
	print "\n\nSuccess, moving outputs.tmp to output\n\n";
	system("mv $output.tmp $output\n");
	print "Moving $output.tmp.clstr to $output.clstr\n\n";
	system("mv $output.tmp.clstr  $output.clstr"); 

}
else{
	die "$output.tmp was not generated. something went wrong!\n\n";
}


#	cd-hit -i $ENV{PWD}/$tmpdir/$filter-$minval-$minlen-$maxlen/sequences.fa -o $ENV{PWD}/$tmpdir/$filter-$minval-$minlen-$maxlen/cdhit\$CDHIT -n 3 -c \$CDHIT -d 0\n"
