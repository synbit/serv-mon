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

    my @cores = ();

    for(my $i=0; $i<$cores; $i++) {
	push @cores, {'used' => (100 - $counter->{"cpu_$i"}->{'idle'}), 'idle' => $counter->{"cpu_$i"}->{'idle'}};
    }

# Calculate the used total and push it into the hash reference:
    $totals->{'used'} = (100 - $totals->{'idle'});

    saveToMySQL($totals, \@cores);
}

sub saveToMySQL {

    my ($totals_ref, $cores_ref) = @_;

# Dereference the hash and the array:
    my %totals = %{$totals_ref};
    my @cores = @{$cores_ref};

# Get the number of cores:
    my $num_cores = scalar @cores;

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

    $stm_cpu->execute($srv_id, $hostname, $num_cores, $totals{'used'}, $totals{'idle'}, $totals{'usr'}, $totals{'nice'}, $totals{'sys'},
		      $totals{'iowait'}, $totals{'irq'}, $totals{'soft'}, $totals{'steal'}, $totals{'guest'},
		      $cores[0]->{'used'}, $cores[0]->{'idle'}, $cores[1]->{'used'}, $cores[1]->{'idle'},
		      $cores[2]->{'used'}, $cores[2]->{'idle'}, $cores[3]->{'used'}, $cores[3]->{'idle'}
	) or die("Couldn't execute statement:\n$stm");

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
