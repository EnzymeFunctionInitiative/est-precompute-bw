#!/usr/bin/env perl
#Description: Wrapper for xgmml scripts
#Author : Boris Sadkhin
#Date : July, 2014
use strict;
use File::Basename;
use FindBin;

my $dir = shift @ARGV;
my $xgmml_dir = "$dir/xgmml";
if( not defined $dir){
	die "\t\t--usage $0 <path to directory>\n";
}
mkdir("$xgmml_dir");
mkdir("$xgmml_dir/original");
mkdir("$xgmml_dir/multiplexed");

my $unit = basename($dir);;
my $full_xgmml_script = "$FindBin::Bin/include/xgmml/xgmml_100_create.pl";
my $repnode_xgmml_script = "$FindBin::Bin/include/xgmml/xgmml_create_all.pl";

my $title                  = $unit;
my $struct                 = "$dir/struct/$unit.struct";
my $multiplexed_fasta      = "$dir/fasta/$unit.cdhit.fa";
my $full_fasta          = "$dir/fasta/$unit.fa.renamed";
my $multiplexed_blast      = "$dir/1out/1.out";
my $demultiplexed_blast    = "$dir/1out/2.out";

foreach my $requirement($struct,
		$full_fasta, $multiplexed_fasta,
		$multiplexed_blast,$demultiplexed_blast,
		$full_xgmml_script,$repnode_xgmml_script
		){
	if (not -s $requirement){
		die "Missing $requirement\n";
	}
}

foreach my $experiment("original"){
#Generate Rep Nodes
	my @intervals = qw(40 45 50 55 60 65 70 75 80 85 90 95 98 100);
	foreach my $id(@intervals){
		my $decimal = $id / 100;

##2 Types of analysis
## Original - 2.out (demux) + full-fasta
## Reduced - 1.out (mult) + multiplexed_fasta
##Full


		my $xgmml_out_id = "$xgmml_dir/original/$unit-$id.xgmml";
		my $cd_hit = "$dir/cdhit/original/$unit-$id.fa.clstr";
		my $blastin = $demultiplexed_blast; ##2.out
			my $fasta = $full_fasta; ##Full fasta
			if($experiment eq "reduced"){
				$blastin = $multiplexed_blast;
				$fasta = $multiplexed_fasta; 
				$cd_hit = "$dir/cdhit/multiplexed/$unit-$id.fa.clstr";	
				$xgmml_out_id = "$xgmml_dir/multiplexed/$unit-$id.xgmml";
			}		

		unless(-s $cd_hit){
			die "Cannot find $cd_hit\n";
		}

		my $call =
			" $repnode_xgmml_script " .
			" -blast $blastin -fasta $fasta " .
			" -struct $struct -title=\"$title-$id\" ".
			" -output $xgmml_out_id.tmp -cdhit $cd_hit ";

		if(-s "$xgmml_out_id"){
			print "Skipping $id for $unit [$id] , $xgmml_out_id exists \n";
		}
		else{
			print $call,"\n";
			system("$call ; mv $xgmml_out_id.tmp $xgmml_out_id ; " );
			unless (-s $xgmml_out_id){
				unlink($xgmml_out_id); #Remove blank files?
			}
		}
#Generate stats for the network
		generateStats($xgmml_out_id);
	}
}

#Generate Full Network
#
foreach my $experiment("original"){
	print "Generating Full Network for $unit\n";
	my $xgmml_out = "$xgmml_dir/original/$unit-full.xgmml";	
	my $blastin = $demultiplexed_blast; #2.out
		my $fasta = $full_fasta; #.fa

		if($experiment eq "reduced"){
			$fasta = $multiplexed_fasta;#1.out
				$blastin = $multiplexed_blast; #.fa.cdhit
				$xgmml_out = "$xgmml_dir/multiplexed/$unit-full.xgmml";
		}

	my $call = "$full_xgmml_script -blast $blastin -fasta $fasta -struct $struct  -title $title -output $xgmml_out.tmp ";
	if(-s $xgmml_out){
		print "$xgmml_out already exists\n";
	}
	else{
		print "\n$call\n";
		system("$call; mv $xgmml_out.tmp $xgmml_out");
	}
	generateStats($xgmml_out);
}





#Generate stats
sub generateStats{
	my $xgmml = shift;
	my $stats = "$xgmml.stats";


#	if(-s $stats){
#		print "Stats already generated for $xgmml\n";
#		return;
#	}
#	print "about to generate stats for $xgmml\n";


	chomp(my $edges = `LC_ALL=C fgrep -c '<node' $xgmml`);
	chomp(my $nodes = `LC_ALL=C fgrep -c '<edge' $xgmml`);
	chomp(my $size  = `du $xgmml  | cut -f1`);

	unless(defined $edges && defined $nodes && defined $size){
		print "Unable to generate stats for $xgmml\n";
	}

	system("echo '$nodes\t$edges\t$size' > $stats.tmp; mv $stats.tmp $stats");

	print "Generated stats for $xgmml\n";
}


