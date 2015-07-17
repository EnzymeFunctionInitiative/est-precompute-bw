#!/usr/bin/env perl
#Author  Boris Sadkhin
#Summary : Wrapper for Dan's script for blast reduce 
#program to re-add sequences removed by initial cdhit
#version 0.9.3 Program created
use File::Basename;
use Time::HiRes qw( time );
my $start = time();

my $dir = shift;
if(!$dir || not -s $dir){
        die "$dir does not exist";
}
my $unit = basename($dir);
mkdir("$dir/demux");
my $blast_1out = "$dir/1out/$unit.multiplexed.1out";
my $demultiplexed = "$dir/demux/$unit.1out.demultiplexed";
my $cluster = "$dir/fasta/$unit.cdhit.fa.clstr";


die "$demultiplexed already exists!\n" if(-s $demultiplexed);


#parse cluster file to get parent/child sequence associations
#create new 1.out file from input 1.out that populates associations
open CLUSTER, $cluster or die "cannot open cdhit cluster file $cluster\n";
open BLASTIN, $blast_1out or die "cannot open blast input file $blast_1out\n";
open BLASTOUT, ">$demultiplexed.tmp" or die "cannnot write to blast output file $demultiplexed\n";


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
  }elsif($line=~/ >(\w{6,10})\.\.\. \*$/){
    #print "head\t$1\n";
    push @children, $1;
    $head=$1;
    #print "$1\n";
  }elsif($line=~/^\d+.*>(\w{6,10})\.\.\. at/){
    #print "child\t$1\n";
    push @children, $1;
  }else{
    die "$line\n";
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
  #print "$linesource\t$linetarget\n";
  if($linesource eq $linetarget){
    for(my $i=0;$i<scalar @{$tree{$linesource}};$i++){
      for(my $j=$i+1;$j<scalar @{$tree{$linesource}};$j++){
	print BLASTOUT  "@{$tree{$linesource}}[$i]\t@{$tree{$linesource}}[$j]\t".join("\t", @lineary)."\n";
	#print "likewise demux\t@{$tree{$linesource}}[$i]\t@{$tree{$linesource}}[$j]\n";
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

system("mv $demultiplexed.tmp $demultiplexed"); 
