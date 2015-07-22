#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use vPAN::Iostats;
use Config::Simple;
use DBI;
$|=1;

getIOStats();

sub getIOStats {
    my $iostat = new vPAN::Iostats;
    my $counter = $iostat->iostat();

# Display what we are about to save to MySQL:
    print dump($counter) . "\n";

# Hardcoding the devices (needs fixing):
    my @devices = qw(md0 md1 sda sdb sdc sdd);
    my $devices = \@devices;

# Get TPS for all disks:
    my $md0_tps = $counter->{'md0'}->{'tps'};
    my $md1_tps = $counter->{'md1'}->{'tps'};
    my $sda_tps = $counter->{'sda'}->{'tps'};
    my $sdb_tps = $counter->{'sdb'}->{'tps'};
    my $sdc_tps = $counter->{'sdc'}->{'tps'};
    my $sdd_tps = $counter->{'sdd'}->{'tps'};

# Get kBrps for all disks:
    my $md0_kBrps = $counter->{'md0'}->{'kB_read/s'};
    my $md1_kBrps = $counter->{'md1'}->{'kB_read/s'};
    my $sda_kBrps = $counter->{'sda'}->{'kB_read/s'};
    my $sdb_kBrps = $counter->{'sdb'}->{'kB_read/s'};
    my $sdc_kBrps = $counter->{'sdc'}->{'kB_read/s'};
    my $sdd_kBrps = $counter->{'sdd'}->{'kB_read/s'};

# Get kBwps for all disks:
    my $md0_kBwps = $counter->{'md0'}->{'kB_wrtn/s'};
    my $md1_kBwps = $counter->{'md1'}->{'kB_wrtn/s'};
    my $sda_kBwps = $counter->{'sda'}->{'kB_wrtn/s'};
    my $sdb_kBwps = $counter->{'sdb'}->{'kB_wrtn/s'};
    my $sdc_kBwps = $counter->{'sdc'}->{'kB_wrtn/s'};
    my $sdd_kBwps = $counter->{'sdd'}->{'kB_wrtn/s'};

# Save to MySQL:
    saveToMySQL($md0_tps, $md1_tps, $sda_tps, $sdb_tps, $sdc_tps, $sdd_tps,
		$md0_kBrps, $md1_kBrps, $sda_kBrps, $sdb_kBrps, $sdc_kBrps, $sdd_kBrps,
		$md0_kBwps, $md1_kBwps, $sda_kBwps, $sdb_kBwps, $sdc_kBwps, $sdd_kBwps, $devices);
}

sub saveToMySQL {

    my ($md0_tps, $md1_tps, $sda_tps, $sdb_tps, $sdc_tps, $sdd_tps,
	$md0_kBrps, $md1_kBrps, $sda_kBrps, $sdb_kBrps, $sdc_kBrps, $sdd_kBrps,
	$md0_kBwps, $md1_kBwps, $sda_kBwps, $sdb_kBwps, $sdc_kBwps, $sdd_kBwps, $devices) = @_;

    my $config = new Config::Simple('Config/stats.conf');
    my $db_name = $config->param('db_name');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');

    my $dbo = DBI->connect("dbi:mysql:$db_name", "$uname", "$passwd");

    unless(defined($dbo)) {
	die "Couldn't connect to database: 'db_name'\n";
    }

    my $stm = <<'SQL';
    INSERT INTO eulinx.server_io (
    	srv_id,
    	dev1, dev1_tps, dev1_rps, dev1_wps,
	dev2, dev2_tps, dev2_rps, dev2_wps,
	dev3, dev3_tps, dev3_rps, dev3_wps,
	dev4, dev4_tps, dev4_rps, dev4_wps,
	dev5, dev5_tps, dev5_rps, dev5_wps,
	dev6, dev6_tps, dev6_rps, dev6_wps,
	last_check )
    VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW());
SQL

    my $stm_io = $dbo->prepare($stm);

    unless($stm_io->execute($srv_id,
			    $devices->[0], $md0_tps, $md0_kBrps, $md0_kBwps,
			    $devices->[1], $md1_tps, $md1_kBrps, $md1_kBwps,
			    $devices->[2], $sda_tps, $sda_kBrps, $sda_kBwps,
			    $devices->[3], $sdb_tps, $sdb_kBrps, $sdb_kBwps,
			    $devices->[4], $sdc_tps, $sdc_kBrps, $sdc_kBwps,
			    $devices->[5], $sdd_tps, $sdd_kBrps, $sdd_kBwps) )
    {
	print "Couldn't prepare statement:\n" . $stm;
    }

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";

}
