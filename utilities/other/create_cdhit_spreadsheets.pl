#!/usr/bin/env perl
use strict;

my %hash;


my @pfams = split "\n", `egrep -o "PF[0-9]{5}" find | sort -u`;

my $count = 0;
foreach my $pfam(@pfams){
	chomp(my $original   = `LC_ALL=C fgrep -c '>' ./$pfam/fasta/$pfam.fa.renamed`);
	chomp( my $r_98_90   = `cat ./$pfam/cdhit_testing/90/$pfam.cdhit.98-90.fa.count`);
	chomp(my $r_1_1 = `cat ./$pfam/cdhit_testing/1/$pfam.cdhit.1-1.fa.count`);
	
	print "$pfam\t$original\t$r_1_1\t$r_98_90\n";	
	$count++;
}

exit;
open F, 'find' or die $!;

my $count = 0;
while(<F>){
	chomp;

	if($count++ == 500){
		last;
	}
	if($_ =~/PF[0-9]{5}\.cdhit.98-90\.fa/){
		my $pfam = (split /\//,$_)[1];
		chomp(my $count = `LC_ALL=C fgrep -c '>' $_`);
		$hash{$pfam}{'98-90'} = $count;
	}
	elsif($_ =~/PF[0-9]{5}\.cdhit\.1-1\.fa/){
		my $pfam = (split /\//,$_)[1];
		chomp(my $count = `LC_ALL=C fgrep -c '>' $_`);
		$hash{$pfam}{'1-1'} = $count;
	}
	elsif($_ =~/fasta\/PF[0-9]{5}\.fa\.renamed/){
		my $pfam = (split /\//,$_)[1];
		chomp(my $count = `LC_ALL=C fgrep -c '>' $_`);
		$hash{$pfam}{'full'} = $count;
	}
}

foreach my $key (sort keys %hash){
		print "$key $hash{$key}{'full'} $hash{$key}{'1-1'} $hash{$key}{'98-90'}\n";
}


sub add_hash{
	my ($line) =$_[0];
	my ($name) = $_[1];
	my @line = split /\//, $line;
	my $pfam = $line[1];
	open O ,$line or die $!;; 
	chomp(my $count = <O>); 
	close O;
#	print "adding $count to $name at $pfam\n";	
	$hash{$pfam}{$name} = $count;
}
