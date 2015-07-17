#!/usr/bin/env perl
# Wrapper script to call quartiles
# Author: Boris Sadkhin
# Date August 7, 2014
use strict;
use File::Basename;
my $dirname = dirname(__FILE__);
use lib "$dirname/include/";
use List::MoreUtils qw(uniq);
use File::Basename;
use File::Path;

#Include dir
my $include_dir = "$dirname/include/plots";
my $rScript = "$include_dir/Rgraphs.pl.bak";

#Setup directories
my $dir = shift;
die "Input a directory" unless (-s $dir);

my $unit_name = basename($dir);

my $plots_dir = "$dir/transfer";
mkdir($plots_dir);
my $rdata_dir = "$dir/rdata/tmp";
my $tabfiles_dir = "$dir/rdata";

mkpath($rdata_dir);
mkpath($tabfiles_dir);

#Set up filepaths
my $fasta = "$dir/fasta/$unit_name.fa.renamed";
my $blast = "$dir/1out/$unit_name.1out.demultiplexed";
die "$fasta not found\n" unless (-s $fasta);
die "$blast not found\n" unless (-s $blast);
my $edges = "$tabfiles_dir/edges.tab";
my $lengths = "$tabfiles_dir/lengths.tab";
my $frac = "0.99";

my $count = 0;
foreach my $plot(qw(r_hist_edges.png r_hist_length.png r_quartile-perid.png r_quartile_align.png)){
	if(-s "$plots_dir/$plot"){
		$count++;
	}
}
if($count ==4){
	die "$unit_name already completed, all plots generated\n";
}
if($count == 0){
	my $call = "$rScript -blastout=$blast -edges=$edges -length=$lengths -rdata=$rdata_dir -fasta=$fasta -incfrac=$frac";
	print "$call\n";
	system("echo $call > $rdata_dir/../call");
	my $call = system($call) / 256;
	

}
else{
	print "No need to run `Rgraphs.pl`, we have the outputs from it already. We only need to run the R scripts\n";
}

unless(-s "$rdata_dir/maxyal"){
	die "Cannot find $rdata_dir/maxyal";
}
else{
	print "Found $rdata_dir/maxyal\n";
}


my $FIRST=`ls $rdata_dir/perid*| head -1`;
chomp($FIRST=`head -1 $FIRST`);
my $LAST=`ls $rdata_dir/perid*| tail -1`;
chomp($LAST=`head -1 $LAST`);
chomp(my $MAXALIGN = `cat $rdata_dir/maxyal`);

print "first=$FIRST last=$LAST max=$MAXALIGN\n";



#Set up calls
chdir("$rdata_dir../");
my $quart_align = "Rscript   $include_dir/quart-align.r $rdata_dir $plots_dir/r_quartile_align.png $FIRST $LAST $MAXALIGN";
unless(-s "$plots_dir/r_quartile_align.png"){
	print "Generating $quart_align\n";
	system($quart_align);
}
else{
	print "$quart_align already exists\n";
}
my $quart_perid = "Rscript   $include_dir/quart-perid.r $rdata_dir $plots_dir/r_quartile-perid.png $FIRST $LAST $MAXALIGN";
unless(-s "$plots_dir/r_quartile-perid.png"){
	print "Generating $quart_perid \n";
	system($quart_perid);
}
else{
	print "$quart_perid already exists\n";
}

my $hist_length = "Rscript   $include_dir/hist-length.r $lengths $plots_dir/r_hist_length.png ";
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



