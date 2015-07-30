#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use vPAN::Memstat;
use Config::Simple;
use DBI;
$|=1;

getMemStats();

sub getMemStats {

    my $memstat = new vPAN::Memstat;
    my $counter = $memstat->memstat();

# Display what we are about to save to MySQL:
    print dump($counter) . "\n";

    my $total = $counter->{'MemTotal'};
    my $free = $counter->{'MemFree'};
    my $buffers = $counter->{'Buffers'};
    my $cache = $counter->{'Cached'};
    my $used = $counter->{'Used'};

    saveToMySQL($total, $free, $buffers, $cache, $used);
}

sub saveToMySQL {

    my ($total, $free, $buffers, $cache, $used) = @_;

    my $config = new Config::Simple('Config/stats.conf');
    my $dsn = $config->param('dsn');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');
    my $srv_name = $config->param('srv_name');

    my $dbo = DBI->connect("$dsn", "$uname", "$passwd");

    unless(defined($dbo)) {
	die "Couldn't connect to database: '$dsn'\n";
    }

    my $stm = <<'SQL';
    INSERT INTO eulinx.server_memory (srv_id, srv_name, mem_total, mem_free,
				      mem_buffers, mem_cache, mem_used, last_check )
	VALUES (?, ?, ?, ?, ?, ?, ?, NOW());
SQL

    my $stm_mem = $dbo->prepare($stm);

    unless($stm_mem->execute($srv_id, $srv_name, $total, $free,
			     $buffers, $cache, $used) )
    {
	print "Couldn't prepare statement:\n" .$stm;
    }

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an ctive connection).\n";

}
