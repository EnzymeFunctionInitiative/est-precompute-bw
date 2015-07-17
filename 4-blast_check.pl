#!/usr/bin/env perl
use strict;
my $family_type = shift @ARGV;
my $dir = $ENV{'EST_PRECOMPUTE_SCRIPTS'};
die "Input pfam/gene3d/ssf unless " unless defined $family_type;
die "Load EST Module\n" unless defined $dir;

my @bins = split "\n", `ls $dir/lists/$family_type/blast/ | sort -n`;

my @todo;
my @results;
my %hash;

foreach my $bin(@bins){
#print "About to check $bin\n";
	chomp $bin;
	my $todo = "$dir/lists/pfam/blast/$bin";
	my $results = "$dir/qsub/$family_type/blast/blast_check/$bin";

#	print `wc -l $todo | cut -f1 -d' ' `;
#	print `wc -l $results | cut -f1 -d ' '`;

	$hash{$bin}{'todo'} = `wc -l $todo | cut -f1 -d' '`;
	$hash{$bin}{'missing'}= `wc -l $results | cut -f1 -d' '` - 1;
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
	my $twenty_percent = .20 * $todo;
	if($results < $twenty_percent && $results != 0){
		$candidate = " candidate[lowernodes] ";
	} 
	my $message = "$bin todo[$todo] missing[$results] $complete $candidate\n"; 
	print $message;
}


