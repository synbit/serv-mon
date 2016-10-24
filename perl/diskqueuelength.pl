#!/usr/bin/perl
use strict;
use warnings;
use Storable qw(store retrieve);
use feature qw(say);

=pod

References:
[1]. https://www.kernel.org/doc/Documentation/ABI/testing/procfs-diskstats
[2]. http://www.xaprb.com/blog/2010/01/09/how-linux-iostat-computes-its-results/
[3]. http://blog.serverfault.com/2010/07/06/777852755/

=cut

my $state_file = "/tmp/check_nrpe_cw_diskstats";

sub getCoeff {
    my ($device, $currentData, $storedData) = @_;

    my $measure_1 = $storedData->{'stats'}{$device}{'weightedMilliSpentDoingIo'};
    my $timestamp_1 = $storedData->{'unixtime'};

    my $measure_2 = $currentData->{'stats'}{$device}{'weightedMilliSpentDoingIo'};
    my $timestamp_2 = $currentData->{'unixtime'};

    # Operations in progress (in the queue or being serviced) for our sampling interval.
    # "Business coefficient" is the best description I came up with :(
    # In plain words: proportion of time having pending or doing IO
    my $coef = ($measure_2 - $measure_1) / (1000 * ($timestamp_2 - $timestamp_1));
    return $coef;
}

sub getServicingTime {
    my ($device, $currentData, $storedData) = @_;

    my $measure_1 = $storedData->{'stats'}{$device}{'milliSpentDoingIo'};
    my $timestamp_1 = $storedData->{'unixtime'};

    my $measure_2 = $currentData->{'stats'}{$device}{'milliSpentDoingIo'};
    my $timestamp_2 = $currentData->{'unixtime'};

    my $milliSpentDoingIo = ($measure_2 - $measure_1) / (1000 * ($timestamp_2 - $timestamp_1));
    return $milliSpentDoingIo;
}

sub diskstats {
        my @columnNames = qw(
        majorBlockVer
        minorBlockVer
        deviceName
        readsCompleted
        readsMerged
        sectorsRead
        milliSpentReading
        writesCompleted
        writesMerged
        sectorsWritten
        milliSpentWriting
        ioInProgress
        milliSpentDoingIo
        weightedMilliSpentDoingIo
    );

    my $data = {
	'unixtime' => time(),
	'stats' => {}
    };

    open(DISK_STATS, "/proc/diskstats");

    while(<DISK_STATS>) {
	s/(^\s+)|(\s+$)//g;
	my @lineData = split(/\s+/, $_);

	my $parsed_row = {};

	for(keys(@columnNames)) {
	    $parsed_row->{$columnNames[$_]} = $lineData[$_];
	}

	#next unless $parsed_row->{'deviceName'} =~ /^(sd[a-z]|md[0-9]+)$/;
	# Raid devices don't report weightedMilliSpentDoingIo:
	next unless $parsed_row->{'deviceName'} =~ /^(sd[a-z])$/;

	$data->{'stats'}->{$parsed_row->{'deviceName'}} = $parsed_row;
    }

    close(DISK_STATS);

    return $data;
}

my $currentData = diskstats();

unless (-e $state_file) {
    store($currentData, $state_file) or die("Unable to create file '$state_file'");
    say "OK - first time this has been executed";
    exit 0;
}

my $storedData = retrieve($state_file);
store($currentData, $state_file) or die("Unable to create file '$state_file'");

my $perfdata = "";
foreach(sort keys($currentData->{'stats'})) {
    $perfdata .= "$_"."_queuePlusServicing=".getCoeff($_, $currentData, $storedData).";"."$_"."_servicing=".getServicingTime($_, $currentData, $storedData).';';
}

say "OK - |". $perfdata;
exit 0;

