#!/usr/bin/perl

use strict;
use warnings;
use Data::Dump qw(dump);
use DBI;
use Config::Simple;
$|=1;

getDiskInfo();

sub getDiskInfo {

# WHAT A SHIT WAY OF DOING IT...
    my (@cmd_output, @disk, @temp);
    my $disk_temps = {};

    @cmd_output = split('\n', `/bin/nc 127.0.0.1 7634`);
    @cmd_output = split('\|', $cmd_output[0]);

# Get the devices:
    for(1,6) {
	push (@disk, $cmd_output[$_]);
    }
# Get the temperatures:
    for(3,8) {
	push (@temp, $cmd_output[$_]);
    }
# Construct the hash:
    for(0,1) {
	$disk_temps->{$disk[$_]} = $temp[$_];
    }

    saveToMySQL($disk_temps);
}

sub saveToMySQL {

    my ($data) = @_;

# Display what we are about to store in the DB:
    print dump($data)."\n";

    my $disk1 = (keys $data)[0];
    my $disk1_temp = $data->{$disk1};
    my $disk2 = (keys $data)[1];
    my $disk2_temp = $data->{$disk2};

    my $config = new Config::Simple('Config/stats.conf');
    my $db_name = $config->param('db_name');
    my $uname = $config->param('uname');
    my $passwd = $config->param('passwd');
    my $srv_id = $config->param('srv_id');

    my $dbo = DBI->connect("dbi:mysql:$db_name","$uname","$passwd");

    unless(defined($dbo)) {
	die "Couldn't connect to database: '$db_name'\n";
    }

    my $stm = <<'SQL';
    INSERT INTO eulinx.disk_stat(srv_id, disk1, disk1_temp, disk2, disk2_temp, last_check)
	VALUES(?, ?, ?, ?, ?, NOW());
SQL

    my $stm_disk = $dbo->prepare($stm);

    unless($stm_disk->execute($srv_id, $disk1, $disk1_temp, $disk2, $disk2_temp)) {
	print "Couldn't prepare statement:\n" . $stm;
    }

    $dbo->disconnect() or die "Couldn't disconnect from MySQL (maybe there isn't an active connection).\n";
}
