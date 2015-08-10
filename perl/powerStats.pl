#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw(dump);
use Sys::Hostname;
use Config::Simple;
use DBI;
use feature qw(say);
use vPAN::APC;
$|=1;

getPower();

sub getPower {
    my ($load, $watts);
    my $apc = new vPAN::APC;
    my $stat = $apc->apc();
    print dump($stat)."\n";
    $load =$stat->{'LOADPCT'};
    $load =~ s/\s*[A-z].*//g;
    $watts = $load*7/sqrt(2);
    say "LOAD: $load";
    say "WATTS: $watts";
}

