#!/usr/bin/env perl
use strict;

my %hash;

#Load original

open F, 'before_pfams_counts' or die $!;

while(<F>){
    chomp $_;
    my @line = split /\//, $_;
    my ($rest,$count) = split /:/, $_;
    my $pfam = $line[-2];
    my $clan = $line[-3];

    $hash{$pfam}{'clan'} = $clan;
    $hash{$pfam}{'count'} = $count;

}

close F;

#NEW
open F, 'list_of_fasta' or die $!;
while(<F>){
    chomp $_;
    my @line = split /\//, $_;
    my ($rest,$count) = split /:/, $_;
    my $pfam = $line[-2];
    my $clan = $line[-3];

    if($_ = /\.98\.fa/){
        $hash{$pfam}{'98'} = $count;
    }
    else{
        $hash{$pfam}{'97'} = $count;
    }
}

close F;

foreach my $pfam(sort {$hash{$a} <=> $hash{$b} }keys %hash){

    print "$pfam";
    foreach my $var ( qw(count 97 98) ){
        print "\t",$hash{$pfam}{$var};
    }
    print "\n";



}

