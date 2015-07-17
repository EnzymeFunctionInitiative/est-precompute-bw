#!/usr/bin/env perl
use strict;

if(`pwd` =~/pfam/){
	open F, 'list_of_pf' or die $!;
	
	my %hash;
	my @png = "
	while(<F>){
		my $quartiles_dir = "$_/transfer/";
		(-s "$quartiles_dir/png")
		{
			
		}
		if(-s $_/transfer/	
	}

}
