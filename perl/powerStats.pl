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

    my $apc = new vPAN::APC;
    my $stat = $apc->apc();
    print dump($stat);

}

