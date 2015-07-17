#!/usr/bin/env perl
use strict;
open F, 'list' or die $!;
my $dir = shift @ARGV;
die "Need base_dir " unless $dir;
my $count =0;
my %hash;
while(my $unit = <F>){
	chomp $unit;
	print $count++,"\n";;
	my $base_dir = "$dir/$unit";
	my $blast = "$base_dir/1out/$unit.blast";
	my $out1 = "$base_dir/1out/1.out";
	my $out2 = "$base_dir/1out/2.out";
	my @plots = qw(r_hist_edges.png  r_hist_length.png  r_quartile-perid.png  r_quartile_align.png);
	my @list = qw(40 45 50 55 60 65 70 75 80 85 90 95 98 100);
	my @xgmml;
	foreach my $pid(@list){
		push @xgmml, "$base_dir/xgmml/$unit-$pid.xgmml";        
	}
	push @xgmml, "$base_dir/xgmml/$unit.full.xgmml";

	if (-s $out1 && -s $out2) {
		my $plots = 0;
		foreach my $plot(@plots){
			if (-s "$base_dir/plots/$plot") {
				$plots++
			}
			else{
	#			print "$base_dir/plots/$plot does not exist\n";
			}

		}
		print "Checking xgmml\n";
		my $xgmml_count = 0; 
		foreach my $xgmml(@xgmml){
			if (-s $xgmml) {
				$xgmml_count++;
			}
			else{
				print "$xgmml does not exist\n";
			}
		}
		print "xgmml_count = $xgmml_count\n";
	
		my $error_message;
		#if ($plots != 4) {
		#	$error_message .= "Missing Quartiles (Generated $plots of 4)";
		#}
		if ($xgmml_count != 15) {
			$error_message .= "Missing XGMML (Generated $xgmml_count of 15)";
		}
		if ($error_message) {
			print "$unit\t$error_message\n";
		}
		else{
			print "$unit\tComplete\n";
		}
	}
	else{
		if ( ! -s $out1) {
			print "$out1 does not exist\n";        
			next;
		}
		elsif(! -s $out2){
			print "$out2 does not exist\n";
			next;
		}
	}
}
