#!/usr/bin/env perl
use strict;

my %hash;


open F, 'cdhit_counts' or die $!;
while(<F>){
        chomp;
        $_ =~ /(PF[0-9]{5})/;
        my $pfam = $1;
        my @line = split /:/, $_;
        $hash{$pfam}{'cdhit'} = $line[1];
}
close F;
open F, 'counts' or die $!;
while(<F>){
        chomp;
        $_ =~ /(PF[0-9]{5})/;
        my $pfam = $1;
        my @line = split /:/, $_;
        $hash{$pfam}{'fasta'} = $line[1];
}
close F;

foreach(keys %hash){
        print "$_\t$hash{$_}{'fasta'}\t$hash{$_}{'cdhit'}\n";


}

