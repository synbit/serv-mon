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

getUpsStats();

sub getUpsStats {

    my $ups;
    my $apc = new vPAN::APC;
    my $stat = $apc->apc();
    ($ups->{'status'}) = $stat->{'STATUS'} =~ /(.*)\s+.*/;
    ($ups->{'timeOnBattery'}) = $stat->{'TONBATT'} =~ /(.*)\s+.*/;
    ($ups->{'battCharge'}) = $stat->{'BCHARGE'} =~ /(.*)\s+.*/;
    ($ups->{'temperature'}) = $stat->{'ITEMP'} =~ /([0-9]+(\.[0-9]+)?)\s+.*/;
    ($ups->{'vin'}) = $stat->{'LINEV'} =~ /(.*)\s+.*/;
    ($ups->{'vout'}) = $stat->{'BATTV'} =~ /(.*)\s+.*/;
    ($ups->{'frequency'}) = $stat->{'LINEFREQ'} =~ /(.*)\s+.*/;

    say dump($ups);
    saveToMySQL($ups);
}

sub saveToMySQL {

    my ($ups) = @_;

    my $config = new Config::Simple('Config/stats.conf');
    my $dsn = $config->param('dsn');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $ups_id = $config->param('ups_id');
    my $units = $config->param('ups_attached_units');

    my $dbo = DBI->connect("$dsn","$uname","$passwd") or die ("Couldn't connect to database: '$dsn'\n");

    my $stm = <<'SQL';
    INSERT INTO eulinx.ups_stat(ups_id,status,sec_on_batt,batt_level,temp,vin,vout,fin,last_check)
	VALUES(?,?,?,?,?,?,?,?,NOW());
SQL

    my $stm_ups = $dbo->prepare($stm);

    $stm_ups->execute($ups_id, $ups->{'status'}, $ups->{'timeOnBattery'}, $ups->{'battCharge'}, 
			$ups->{'temperature'}, $ups->{'vin'}, $ups->{'vout'}, $ups->{'frequency'})
	or die("Couldn't execute statement:\n$stm");

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
