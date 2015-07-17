#!/usr/bin/env perl
use strict;
my $family_type = shift @ARGV;
my $dir = $ENV{'EST_PRECOMPUTE_SCRIPTS'};
die "Input pfam/gene3d/ssf unless " unless defined $family_type;
die "Load EST Module\n" unless defined $dir;

print "Bins are $dir/lists/$family_type/blast\n";
my @bins = split "\n", `ls $dir/lists/$family_type/blast/ | sort -n`;

my @todo;
my @results;
my %hash;

#This is much faster than discovering the files with LS
foreach my $bin(@bins){
#print "About to check $bin\n";
	chomp $bin;
	print "CHecking $dir/lists/pfam/blast/$bin\n";
	my $todo = "$dir/lists/pfam/blast/$bin";
	my $results = "$dir/qsub/$family_type/blast/blast_check/$bin";
	if(-e $results){
		$hash{$bin}{'missing'}= `wc -l $results | cut -f1 -d' '` ;
	}
	else{
		$hash{$bin}{'missing'}= 'Not run';
	}
	$hash{$bin}{'todo'} = `wc -l $todo | cut -f1 -d' '`;
	

}


foreach my $bin(@bins){
	chomp $bin;
	chomp(my $todo = $hash{$bin}{'todo'});
	chomp(my $results = $hash{$bin}{'missing'});
	my $complete = "";
	my $candidate = "";
	if($results ==0 ){
		$complete = " complete ";
	}
	if($results eq 'Not run'){
		$complete = '';
	}
	if(! $results){
		$results = 0;
	}
	my $twenty_percent = .20 * $todo;
	if($results < $twenty_percent && $results != 0){
		$candidate = " candidate[lowernodes] ";
	} 
	my $message = "$bin todo[$todo] missing[$results] $complete $candidate\n"; 
	print $message;
}


