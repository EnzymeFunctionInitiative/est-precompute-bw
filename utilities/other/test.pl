#!/usr/bin/env perl
use strict;
 use File::Basename;

#version 0.1, the make it work version
#eventually will be merged into step_s.1-chopblast
#version 0.8.5 Changed the blastfile loop from foreach to while to reduce memory
#version 0.9.1 After much thought, this step of the program will remain seperate
#version 0.9.1 Renamed blastreduce.pl from step_2.2-filterblast.pl
#version 0.9.2 Modifiied to accept 6-10 digit accessions

my $dir = shift @ARGV;
if(! $dir || ! -s $dir){
        die "$dir does not exist";
}
my $unit = basename($dir);
print "About to create 1.out for $unit\n";

die;

