#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use vPAN::Mpstat;
use DBI;
use Config::Simple;
$|=1;

getCPU();

sub getCPU {

    my $mpstat = new vPAN::Mpstat;
    my $counter = $mpstat->cpustat();

# Calculate the totals:
    my $usr = $counter->{'cpu_all'}->{'usr'};
    my $nice = $counter->{'cpu_all'}->{'nice'};
    my $sys = $counter->{'cpu_all'}->{'sys'};
    my $iowait = $counter->{'cpu_all'}->{'iowait'};
    my $irq = $counter->{'cpu_all'}->{'irq'};
    my $soft = $counter->{'cpu_all'}->{'soft'};
    my $steal = $counter->{'cpu_all'}->{'steal'};
    my $guest = $counter->{'cpu_all'}->{'guest'};
    my $idle = $counter->{'cpu_all'}->{'idle'};
    my $total = 100 - $idle;

# For individual CPUs just return the totals:
    my $cpu0_idle = $counter->{'cpu_0'}->{'idle'};
    my $cpu0_total = 100 - $cpu0_idle;
    my $cpu1_idle = $counter->{'cpu_1'}->{'idle'};
    my $cpu1_total = 100 - $cpu0_idle;
    my $cpu2_idle = $counter->{'cpu_2'}->{'idle'};
    my $cpu2_total = 100 - $cpu0_idle;
    my $cpu3_idle = $counter->{'cpu_3'}->{'idle'};
    my $cpu3_total = 100 - $cpu0_idle;

# Save to MySQL:
    saveToMySQL($total, $idle, $usr, $nice, $sys, $iowait,
	$irq, $soft, $steal, $guest, $cpu0_total, $cpu0_idle,
	$cpu1_total, $cpu1_idle, $cpu2_total, $cpu2_idle,
	$cpu3_total, $cpu3_idle);

=pod
    my $help = $mpstat->help();
    print $help;
=cut

}

sub saveToMySQL {

    my ($total, $idle, $usr, $nice, $sys, $iowait, $irq,
	$soft, $steal, $guest, $cpu0_total, $cpu0_idle,
	$cpu1_total, $cpu1_idle, $cpu2_total, $cpu2_idle,
	$cpu3_total, $cpu3_idle) = @_;

    my $config = new Config::Simple('Config/stats.conf');
    my $db_name = $config->param('db_name');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');
    my $hostname = `/bin/hostname`;
    chomp($hostname);
    my $cores = 4;

    my $dbo = DBI->connect("dbi:mysql:$db_name", "$uname", "$passwd");

    unless(defined($dbo)) {
	die "Couldn't connect to database: '$db_name'\n";
    }

    my $stm = <<'SQL';
	INSERT INTO eulinx.server_cpu(srv_id, srv_name, cores, used_total, idle, usr, nice, sys, iowait, irq, soft, steal, guest, cpu0used, cpu0idle, cpu1used, cpu1idle, cpu2used, cpu2idle, cpu3used, cpu3idle, last_check)
	VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NOW());
SQL

    my $stm_cpu = $dbo->prepare($stm);

    unless($stm_cpu->execute($srv_id,$hostname,$cores,$total,$idle,$usr,$nice,$sys,$iowait,$irq,$soft,$steal,$guest,$cpu0_total,$cpu0_idle,$cpu1_total,$cpu1_idle,$cpu2_total,$cpu2_idle,$cpu3_total,$cpu3_idle)) {
	print "Couldn't perpare statement:\n" . $stm;
    }

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";

}
