#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw(dump);
use Config::Simple;
use DBI;
use feature qw(say);
use vPAN::APC;
$|=1;

getPower();

sub getPower {
    my ($load, $watts, $power);

    my $apc = new vPAN::APC;
    my $stat = $apc->apc();

    $load =$stat->{'LOADPCT'};
    $load =~ s/\s*[A-z].*//g;
    $watts = $load*7/sqrt(2);

    $power->{'load%'} = $load;
    $power->{'watts'} = $watts;

    saveToMySQL($power);
}

sub saveToMySQL {

    my ($power) = @_;
    print dump($power);

}
