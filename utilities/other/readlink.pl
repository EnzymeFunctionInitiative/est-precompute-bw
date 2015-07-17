#!/usr/bin/env perl
while(<>){
    print `readlink -f $_`;
}
