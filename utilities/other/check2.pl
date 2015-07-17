#!/usr/bin/env perl
use strict;
open F, 'list' or die $!;
my $base_dir = shift @ARGV;
die "Need base_dir " unless $base_dir;

my %hash;
while(my $unit = <F>){
        chomp $unit;
        my $blast = "$base_dir/$unit/1out/$unit.blast";
        my $out1 = "$base_dir/$unit/1out/1out";
        my $out2 = "$base_dir/$unit";
        my @plots = qw(r_hist_edges.png  r_hist_length.png  r_quartile-perid.png  r_quartile_align.png);
        my @list = qw(40 45 50 55 60 65 70 75 80 85 90 95 98 100);
        my @xgmml;
        foreach my $pid(@list){
                push @xgmml, "$unit-$pid.xgmml";        
        }
        push @xgmml, "$unit.full.xgmml";
        
        if (-s $out1 && -s $out2) {
                my $plots = 0;
                foreach my $plot(@plots){
                        if (-s $plot) {
                             $plots++
                        }
                }
                my $xgmml = 0; 
                foreach my $xgmml(@xgmml){
                        if (-s $xgmml) {
                                $xgmml++;
                        }
                }
               my $error_message;
                if ($plots != 4) {
                        $error_message .= "Missing Quartiles (Generated $plots of 4)";
                }
                if ($xgmml != 15) {
                         $error_message .= "Missing XGMML (Generated $xgmml of 15)";
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
                else if(! -s $out2){
                        print "$out2 does not exist\n";
                        
                }
                
        }
}
