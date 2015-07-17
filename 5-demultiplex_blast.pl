#!/usr/bin/env perl

#program to re-add sequences removed by initial cdhit
#version 0.9.3 Program created
use Getopt::Long;
use File::Basename;
use warnings;

my $dir = shift @ARGV;
my $unit = basename($dir);
my $cluster = "$dir/fasta/$unit.cdhit.fa.clstr";
my $blastin   = "$dir/1out/1.out";
my $blastout = "$dir/1out/2.out";
if(-s $blastout){
	die "$blastout already exists\n";
}

#$result=GetOptions ("cluster=s"     => \$cluster,
#		    "blastin=s"     => \$blastin,
#		    "blastout=s"    => \$blastout);

#parse cluster file to get parent/child sequence associations

#create new 1.out file from input 1.out that populates associations

open CLUSTER, $cluster or die "cannot open cdhit cluster file $cluster\n";
open BLASTIN, $blastin or die "cannot open blast input file $blastin\n";

open BLASTOUT, ">$blastout.tmp" or die "cannnot write to blast output file $blastout\n";

%tree=();

#parse the clstr file
print "Read in clusters\n";
while(<CLUSTER>){
	my $line=$_;
	chomp $line;
	if($line=~/^>/){
#print "New Cluster\n";
		if(defined $head){
			@{$tree{$head}}=@children;
		}
		@children=();
	}elsif($line=~/ >(.+)\.\.\. \*$/){
#print "head\t$1\n";
		push @children, $1;
		$head=$1;

		print "$1\n";
	}elsif($line=~/^\d+.*>(.+)\.\.\. at/){
#print "child\t$1\n";
		push @children, $1;
	}else{
		die "died at $line\n";
	}
}

@{$tree{$head}}=@children;

print "Demultiplex blast\n";
#read BLASTIN and expand with clusters from cluster file to create demultiplexed file
while(<BLASTIN>){
	my $line=$_;
	chomp $line;
	my @lineary=split /\s+/, $line;
	$linesource=shift @lineary;
	$linetarget=shift @lineary;
	print "$linesource\t$linetarget\n";
	if($linesource eq $linetarget){
		for(my $i=0;$i<scalar @{$tree{$linesource}};$i++){
			for(my $j=$i+1;$j<scalar @{$tree{$linesource}};$j++){
				print BLASTOUT  "@{$tree{$linesource}}[$i]\t@{$tree{$linesource}}[$j]\t".join("\t", @lineary)."\n";
				print "likewise demux\t@{$tree{$linesource}}[$i]\t@{$tree{$linesource}}[$j]\n";
			}
		}
	}else{
		foreach my $source (@{$tree{$linesource}}){
			foreach my $target (@{$tree{$linetarget}}){
				print BLASTOUT "$source\t$target\t".join("\t", @lineary)."\n";
			}
		}
	}
}
	system("mv $blastout.tmp $blastout");
