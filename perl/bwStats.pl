#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use Sys::Hostname;
use DBI;
use Config::Simple;
$|=1;

sub getBW {

    my @cmd_output;
    my @data;
    my $counter;

    @cmd_output = split('\n', `/usr/bin/ifstat -w -i eth0,lo 1 1`);
    @data = split(/\s+/, $cmd_output[2]);
# Remove elements which are empty strings:
    foreach my $key(@data) {
	unless(length($key)) {
	    shift @data;
	}
    }
# Adding zero to cast "0.00" to number 0.00:
    $counter = {
	'eth0_in' => $data[0] + 0,
	'eth0_out' => $data[1] + 0,
	'lo_in' => $data[2] + 0,
	'lo_out' => $data[3] + 0,
    };
    print dump($counter) . "\n";

    saveToMySQL($counter);
}
getBW();

sub saveToMySQL {

    my $counter = shift;
    my $config = new Config::Simple('Config/stats.conf');
    my $dsn = $config->param('dsn');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');
    my $hostname = hostname;
    chomp($hostname);

    my $dbo = DBI->connect("$dsn","$uname","$passwd") or die ("Couldn't connect to database: '$dsn'\n");

    my $stm = <<'SQL';
	INSERT INTO eulinx.server_bandwidth(srv_id,srv_name,lo_in,lo_out,eth0_in,eth0_out,last_check)
	VALUES(?,?,?,?,?,?,NOW());
SQL

    my $stm_bw = $dbo->prepare($stm);

    $stm_bw->execute($srv_id,$hostname,$counter->{'lo_in'},$counter->{'lo_out'},$counter->{'eth0_in'},$counter->{'eth0_out'})
	or die("Couldn't execute statement:\n$stm");

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
