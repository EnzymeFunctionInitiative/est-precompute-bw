#!/usr/bin/env perl

# Summary: Configuration variables for the pipeline on bluewaters
# Author: Boris Sadkhin
# Date: August 5, 2014
# Modified: March 30, 2015
package Config;
use strict;

our %config;


my $base_dir   = "/u/sciteam/sadkhin/est-precompute-bw-52";
my $scratch_data = "/u/sciteam/sadkhin/scratch/release52";


$config{'base_dir'}       = "$base_dir";
$config{'lists_dir'}  = "$base_dir/scripts/lists";
$config{'scratch_data'} = "$scratch_data";


sub getPath{
    return $config{$_[0]};

}
