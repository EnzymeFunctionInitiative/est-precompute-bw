#!/usr/bin/env perl
use strict;
my $dir = shift;
my $pfam = (split /\// , $dir)[-1];

chomp(my $fasta = `ls $dir/fasta/split | grep fa\$ | wc -l`);
chomp(my $blast = `ls $dir/blast/ | grep blast\$ | wc -l`);

print STDERR "Fasta = $fasta\n";
print STDERR "Blast = $blast\n";
