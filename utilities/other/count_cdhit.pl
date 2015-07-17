#!/usr/bin/env perl
use strict;

my $fasta = shift;
my $cdhit_fasta = shift;

my %hash;
open F , $fasta or die $!;



while(<F>){
    chomp;
    next if length $_  <2;
my ($pfam,$count) = split /:/;
    $pfam =~ m/(PF[0-9]+)/;
    my $PFAM = $1;
    if($PFAM eq "PF00248"){
        print $_; #die;
    }
    $hash{$PFAM}{'fasta'} = $count;
}
close F;

open F, $cdhit_fasta or die $!;
while(<F>){
    chomp;
    next if length $_  <2;
    my ($pfam,$count) = split /:/;
    $pfam =~ m/(PF[0-9]+)/;
    my $PFAM = $1;
    $hash{$PFAM}{'cdhit'} = $count;

}
close F;

foreach my $pfam(sort {$hash{$a}{'fasta'} <=> $hash{$b}{'fasta'}} keys %hash){
    if(length $pfam <2){
        next
        ;
    }
    my $count = $hash{$pfam}{'fasta'};
    my $fasta = $hash{$pfam}{'cdhit'};
   my $difference = $count - $fasta;
    if($count == 0){
        print "Count for $pfam is $count \n";
        die;

        $count =1;
    }
    my $percentage =  ($difference/$count ) * 100; #l* 100;

    print join "\t", $pfam,$count,$fasta,$difference,$percentage;
    print "\n";
}
