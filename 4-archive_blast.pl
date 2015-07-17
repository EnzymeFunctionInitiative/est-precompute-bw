#!/usr/bin/env perl
use strict;
use File::Basename;

my $dir = shift;
my $unit = basename($dir);

my $blast_file = "$dir/1out/$unit.cat.blast";
my $out_file = "$dir/archive/$unit.blast.gz";

mkdir("$dir/archive");

die unless (-s $dir);
die unless (-s $blast_file);



if(-s "$out_file"){
	die "$out_file already exists\n";
}
else{
	system("pigz -p 8 -c $blast_file > $out_file.tmp; mv $out_file.tmp $out_file"); 


}
