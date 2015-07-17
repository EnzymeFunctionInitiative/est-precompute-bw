#!/usr/bin/env perl
use strict;
use File::Slurp;
use File::Basename;
my $dirname = dirname(__FILE__);
my @bins = @ARGV;

die "Input a bin" unless defined @ARGV;

my %missing;
my $count = 0;
my @missing;
foreach my $bin(@bins){
	my $file = "$dirname/lists/pfam/blast/$bin";
	my @lines = read_file($file);
	print "About to open $file\n";
	my $count = 0;
	print "About to check " . scalar @lines . " entries\n";
	foreach my $line(@lines){
		if($count++ % 5000 == 0){
			print STDERR "check $count entries so far!\n";
		}

		my ($dir,$query) = split " ", $line;
		my $filename = basename($query);
		my $dir = dirname(dirname(dirname($query)));
		my $blast = "$dir/blast/$filename.blast";
		if(! -s $blast){
			print STDERR "Missing $blast\n";
			push @missing, $blast;
		}
	}
	print "About to print missing entries for $file (". scalar @missing .") to blast_check/$bin \n";
	print join "\n", @missing;
	mkdir('blast_check');
	open F ,">blast_check/$bin" or die $!;
	print F join "\n", @missing;
}
