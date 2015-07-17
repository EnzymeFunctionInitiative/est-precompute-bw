#!/usr/bin/env perl
use strict;
use File::Basename;
my $dirs = shift @ARGV;
open F, $dirs or die $!;
my @list_of_families;
mkdir('/tmp');
while(my $dir_dir = <F>){
	my @dirs = split / /, $dir_dir;
	my $family = basename($dirs[0]);
	chop $dirs[0];
	my $command = "cp $dirs[0]/fasta/$family.cdhit.fa* /tmp";
	print $command,"\n";
	system($command);
}
close F;
