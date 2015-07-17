#!/usr/bin/env perl
use strict;
use File::Basename;
use File::Touch;

my $dir = shift;
my $unit = basename($dir);
die unless(-s $dir);

my @blast_files = 
("1out/$unit.blastfinal.tab",
"1out/$unit.multiplexed.1out",
"1out/$unit.1out.demultiplexed",
"1out/demux/$unit.1out.demultiplexed",
"demux/$unit.1out.demultiplexed",
"1out/$unit.unsorted.1out",
"1out/$unit.alphabetized",
"1out/$unit.alphabetized.sorted",
"1out/1.out",
"1out/2.out");

my @fasta_files =
("fasta/$unit.fa",
"fasta/$unit.fa.renamed",
"fasta/$unit.cdhit.fa",
"fasta/$unit.cdhit.fa.clstr");

my @cdhit;
my @xgmml;

foreach my $name(qw(40 45 50 55 60 65 70 75 80 85 90 95 98 100)){
        
        foreach my $type(qw(multiplexed demultiplexed)){
                my $cdhit       = "cdhit/$type/$unit-$name.fa";
                my $cdhit_clstr = "cdhit/$type/$unit-$name.fa.clstr";
                my $xgmml       = "transfer/xgmml/$type/$unit-$name.xgmml";
		foreach my $file($cdhit,$cdhit_clstr,$xgmml){
			if(! -s $file){
				#print "$file does not exist!\n";
			}
			else{
				touch($file)
			}
		}
		push @xgmml, $cdhit,$cdhit_clstr,$xgmml;
	}


}
my $xgmml_full       = "transfer/xgmml/multiplexed/$unit-full.xgmml";
my $xgmml_full2      = "transfer/xgmml/demultiplexed/$unit-full.xgmml";
push @xgmml, $xgmml_full, $xgmml_full2;

foreach my $zipme(@blast_files,@fasta_files,@xgmml){
	my $out_file = "$dir/$zipme.gz";
	$zipme = "$dir/$zipme";	
	if(-s "$zipme"){
	#print "About to touch $zipme\n";
		touch($zipme);
		if(-s $out_file){
			touch($out_file);
			#print "Skipping $out_file it exists\n";
		}
		else{
			print "Zipping $zipme\n";
			system("pigz -p 8 -c $zipme > $out_file.tmp; mv $out_file.tmp $out_file"); 
		}
	}
	else{
	#	print "$zipme does not exist\n";
	}
	
}
