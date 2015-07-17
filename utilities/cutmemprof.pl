#!/usr/bin/env perl
use strict;
use POSIX qw(ceil);
use File::Basename;

my $bin = shift;
my $output_dir = shift ;
if(!-s $output_dir){
	$output_dir = "checkmemory/";
	mkdir($output_dir);
}

my $dir = $ENV{'EST_PRECOMPUTE_SCRIPTS'};
die "Input a bin .. eg. 69000" unless defined $bin;
die "Load EST Module\n" unless defined $dir;


my $list_of_dirs = "$dir/lists/pfam/scheduler.x/$bin";
die unless(-s $list_of_dirs);


my @family_dirs = `cut -f1 -d' ' $list_of_dirs`;

my @files;
foreach my $dir(@family_dirs){
	chomp $dir;
	$dir .= "memprof/blast";
	if(-s $dir){
		my @found = split "\n" , `ls $dir | grep .fa.csv`;
		print "Found @found in $dir\n";
		foreach my $find(@found){
			$find = "$dir/$find";
		}
		push @files, @found;
	}
	else{
	}
}


print "We have " . scalar @files . "in files!\n";

my %hash;
my $count = 0;
foreach my $file(@files){
#memprof-PF13465-420.fa.csv
	my ($mem,$family,$ext) = split /-/, $file;
	print $family,"\t",$count++,"\n";
	my @cut = split "\n", `tail $file | cut -f4 -d ',' `;


	foreach my $cut(@cut){
#		$cut = (ceil($cut/1000)) * 1000;
		push @{$hash{$cut}}, basename($file); 
	}
}

open O ,">$output_dir/$bin.mem" or die $!;
open O2 ,">$output_dir/$bin.mem2" or die $!;
foreach my $cut(sort {$a<=>$b}keys %hash){
	my @arr = @{$hash{$cut}};
	print O "$cut @arr\n";
	foreach my $arr(@arr){
		my ($mem,$fam,$rest) = split /-/, $arr;
		my ($num,$fa,$csv) = split /\./, $rest;
		$arr = $num;
	}
	print O2 "$cut @arr\n";
}
close O;
close O2;
print "Printed to $output_dir/$bin";

sub roundup
{
	my $num = shift;
	my $roundto = shift || 1;

	return int(ceil($num/$roundto))*$roundto;
}
