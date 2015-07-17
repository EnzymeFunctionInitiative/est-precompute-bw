#!/usr/bin/env perl
#Author  Boris Sadkhin
#Date Created Oct 31, 2014
#Summary : Wrapper for Dan's script for blast reduce
use strict;
use File::Basename;
use Time::HiRes qw( time );
my $start = time();

my $dir = shift;
if(!$dir || not -s $dir){
	die "$dir does not exist";
}
my $unit = basename($dir);
my $fasta = "$dir/fasta/$unit.cdhit.fa";#You can use the cdhit fasta, cuz the db you are blasting against is cdhit reduced
my $blast = "$dir/1out/$unit.blastfinal.tab";
my $alphabetize = "$dir/1out/$unit.alphabetized";
if(! -s $blast){
	die "$blast does not exist!";
	
}
if( !-s $fasta){
	die "$fasta does not exist!"
}
if(-s $alphabetize){
	die "$alphabetize already exists!";
}

#Get Lengths
open F, $fasta or die "Cannot open fasta file $fasta\n";
my %seqlengths;
my $header;
while(my $line =<F>){
	chomp $line;
	if(substr($line,0,1) eq ">"){
		$header = substr($line,1);
	}
	else{
		$seqlengths{$header} += length($line);
	}
}
close F;

#Alphabetize the blast, and create a new 1out
open F, $blast or die $! . " Cannot open blast[$blast] file \n";
open O, ">$alphabetize.tmp" or die $! . "Cannot print to $alphabetize \n";
while(my $line = <F>){
	chomp $line;
	$line=~/^(\w+)\t(\w+)\t(.*)$/;
	my $mult=$seqlengths{$1}*$seqlengths{$2};
	if($1 lt $2){
		print O "$line\t$seqlengths{$1}\t$seqlengths{$2}\n"; #Forward
	}else{
		print O "$2\t$1\t$3\t$seqlengths{$2}\t$seqlengths{$1}\n"; #Reverse
	}
}
close F;
print "Moving $alphabetize.tmp to $alphabetize\n";
system("mv $alphabetize.tmp $alphabetize");

#Print time
my $end = time();
open O, ">$dir/1out/alphabetize.time" or die $!;
printf O ("%.3f\n", $end - $start);
close O;


