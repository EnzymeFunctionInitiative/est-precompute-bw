#!/usr/bin/env perl
use strict;
open F, 'list_of_pf' or die $!;
while(<F>){
	chomp;
	my $comm = "ln -s ../$_/transfer transfer/$_";
	print "$comm\n";
	system($comm);
	print $.;

}
