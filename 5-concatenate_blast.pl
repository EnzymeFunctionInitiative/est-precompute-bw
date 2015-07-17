#!/usr/bin/env perl
#Author Boris Sadkhin
#Date Created Oct 31, 2014
#Summary : Concatenate  
use strict;
use FindBin;
use File::Basename;

my $dir = shift;
my $f = shift;
my $dieOnEmpty = 1;
if(!$dir || not -s $dir){
	die "$dir does not exist";
}
my $unit = basename($dir);

chomp(my $split_count = `ls $dir/fasta/split | egrep "\.fa\$" | wc -l`);
chomp(my $blast_count = `ls $dir/blast | egrep "blast\$" | wc -l`);

if($split_count == 0 || $blast_count ==0){
	die "Sorry, no blast or split files found\n";
}

if($split_count != $blast_count && !$f){
	print "Sorry, cannot concatenate $unit , it is not finished split_count[$split_count] blast_count[$blast_count]";
}
else{

	my $output_file = "$dir/1out/$unit.blastfinal.tab";
	if(-s $output_file){
		die "$output_file already exists";
	}
	mkdir("$dir/1out");
	unlink("$output_file.tmp");
	
	my @blast_chunks = split "\n", `ls $dir/blast | egrep "blast\$"`;
	foreach my $blast_chunk(@blast_chunks){
		if($dieOnEmpty){
			if(not -s "$dir/blast/$blast_chunk"){
				die "Error, $dir/blast/$blast_chunk is of zero size! Maybe I shouldn't cat this!\n";
			}
		}
		#system("cat $dir/blast/$blast_chunk | grep -v '#'|cut -f 1,2,3,4,12 >> $output_file.tmp");
		system("cut -f 1,2,3,4,12 $dir/blast/$blast_chunk | grep -v '#'  >> $output_file.tmp");
	}
	system("mv $output_file.tmp $output_file");
}
