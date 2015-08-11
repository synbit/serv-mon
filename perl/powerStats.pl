#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dump qw(dump);
use Config::Simple;
use DBI;
use feature qw(say);
use vPAN::APC;
use Sys::Hostname;
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

    print dump($power);
    saveToMySQL($power);
}

sub saveToMySQL {

    my ($power) = @_;
    my $config = new Config::Simple('Config/stats.conf');
    my $dsn = $config->param('dsn');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $ups_id = $config->param('ups_id');
    my $units = $config->param('ups_attached_units');

    my $dbo = DBI->connect("$dsn","$uname","$passwd") or die ("Couldn't connect to database: '$dsn'\n");

    my $stm = <<'SQL';
    INSERT INTO eulinx.ups_power_stat(ups_id,units_attached,load_percent,watts,last_check)
	VALUES(?,?,?,?,NOW());
SQL

    my $stm_power = $dbo->prepare($stm);

    $stm_power->execute($ups_id, $units, $power->{'load%'}, $power->{'watts'})
	or die("Couldn't execute statement:\n$stm");

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
