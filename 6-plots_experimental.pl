#!/usr/bin/env perl
# Wrapper script to call quartiles
# Author: Boris Sadkhin
# Date August 7, 2014
use strict;
use FindBin;
use List::MoreUtils qw(uniq);
use lib "$FindBin::Bin/include/";
use File::Basename;

require 'config.pl';


#Include dir
my $include_dir = "$FindBin::Bin/include/plots";
my $rScript = "$include_dir/Rgraphs.pl";

#Setup directories
my $base_dir    		 = Config::getPath('base_dir');
my $dir = shift;
die "Input a directory" unless (-s $dir);
my $unit_name = basename($dir);
my $plots_dir = "$dir/plots";
mkdir($plots_dir);

#Set up filepaths
my $fasta = "$dir/fasta/$unit_name.fa";
my $blast = "$dir/1out/2.out";
if(!-s $fasta){
	die "$fasta not found\n";
}
if(!-s $blast){
	die "$blast not found\n";
}


my $rdata = "$plots_dir/rdata";
my $edges = "$plots_dir/edges.tab";
my $length_histogram = "$plots_dir/lengths.tab";
my $frac = "0.99";
system("mkdir -p $rdata");

my $count = 0;
foreach my $plot(qw(r_hist_edges.png r_hist_length.png r_quartile-perid.png r_quartile_align.png)){
	if(-s "$plots_dir/$plot"){
		$count++;
	}
}
if($count ==4){
	die "$unit_name already completed, all plots generated\n";
}


my $call = "$rScript -blastout=$blast -edges=$edges -length=$length_histogram -rdata=$rdata -fasta=$fasta -incfrac=$frac";


print "$call\n";
#system($call);


print "$rdata/perid*\n";

unless(-s "$rdata/maxyal"){
	die "Cannot find $rdata/maxyal";
}

my $FIRST;
my $LAST;
my $MAXALIGN;
chomp(my $file_count = `ls $rdata | wc -l`);;
print "Count = $file_count\n";
if($file_count > 2 ){
	print "$file_count > 2\n";
	chomp($FIRST    = `head -1 \`ls $rdata/perid*| head -1 \` `);
	chomp($LAST     = `head -1 \`ls $rdata/perid*| tail -1 \` `);
}


chomp($MAXALIGN = `head -1 $rdata/maxyal`);
print "first=$FIRST last=$LAST max=$MAXALIGN\n";

#Set up calls
chdir("$rdata../");
my $quart_align = "Rscript   $include_dir/quart-align.r $rdata $plots_dir/r_quartile_align.png $FIRST $LAST $MAXALIGN";
unless(-s "$plots_dir/r_quartile_align.png"){
	print "Generating $quart_align\n";
	system($quart_align);
}
else{
	print "$quart_align already exists\n";
}
my $quart_perid = "Rscript   $include_dir/quart-perid.r $rdata $plots_dir/r_quartile-perid.png $FIRST $LAST $MAXALIGN";
unless(-s "$plots_dir/r_quartile-perid.png"){
		print "Generating $quart_perid \n";
		system($quart_perid);
}
else{
	print "$quart_perid already exists\n";
}

my $hist_length = "Rscript   $include_dir/hist-length.r $length_histogram $plots_dir/r_hist_length.png ";
unless(-s "$plots_dir/r_hist_length.png"){
	print "Generating $hist_length\n";
	system($hist_length);
}
else{
	print "$plots_dir/r_hist_length.png already exists\n";
}

my $hist_edges  = "Rscript   $include_dir/hist-edges.r  $edges	 	  $plots_dir/r_hist_edges.png ";
unless(-s "$plots_dir/r_hist_edges.png"){
	print "Generating $hist_edges\n";
	system($hist_edges);
}
else{
	print "$plots_dir/r_hist_edges.png already exists\n";
}



