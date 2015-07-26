#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use vPAN::Mpstat;
use Sys::Hostname;
use DBI;
use Config::Simple;
$|=1;

getCPU();

sub getCPU {

    my $mpstat = new vPAN::Mpstat;
    my $counter = $mpstat->cpustat();

# Display what we are about to save into MySQL:
    print dump($counter) . "\n";

# Overall stats for all cores:
    my $totals = delete $counter->{'cpu_all'};

# Get the number of cores after 'cpu_all' key is removed:
    my $cores = keys $counter;

    saveToMySQL($cores,	(100 -  $totals->{'idle'}), $totals, 
		(100 - $counter->{'cpu_0'}->{'idle'}), $counter->{'cpu_0'}->{'idle'},
		(100 - $counter->{'cpu_1'}->{'idle'}), $counter->{'cpu_1'}->{'idle'},
		(100 - $counter->{'cpu_2'}->{'idle'}), $counter->{'cpu_2'}->{'idle'},
		(100 - $counter->{'cpu_3'}->{'idle'}), $counter->{'cpu_3'}->{'idle'}
	);
}

sub saveToMySQL {

    my ($cores, $used, $totals, $cpu0_used, $cpu0_idle,
	$cpu1_used, $cpu1_idle, $cpu2_used, $cpu2_idle,
	$cpu3_used, $cpu3_idle) = @_;

    my $config = new Config::Simple('Config/stats.conf');
    my $dsn = $config->param('dsn');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');
    my $hostname = hostname;

    my $dbo = DBI->connect("$dsn", "$uname", "$passwd") or die("Couldn't connect to database: '$dsn'\n");

    my $stm = <<'SQL';
	INSERT INTO eulinx.server_cpu(srv_id, srv_name, cores, used_total, idle, usr, nice, sys, iowait, irq, soft, steal, guest, cpu0used, cpu0idle, cpu1used, cpu1idle, cpu2used, cpu2idle, cpu3used, cpu3idle, last_check)
	VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW());
SQL

    my $stm_cpu = $dbo->prepare($stm);

    $stm_cpu->execute($srv_id, $hostname, $cores, $used, $totals->{'idle'}, $totals->{'usr'}, $totals->{'nice'}, $totals->{'sys'},
		      $totals->{'iowait'}, $totals->{'irq'}, $totals->{'soft'}, $totals->{'steal'}, $totals->{'guest'},
		      $cpu0_used,$cpu0_idle,$cpu1_used,$cpu1_idle,$cpu2_used,$cpu2_idle,$cpu3_used,$cpu3_idle
	) or die("Couldn't execute statement:\n$stm");

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
