package vPAN::Iostats;
use strict;
use warnings;
use Data::Dump qw(dump);

sub new {

    my ($class) = @_;
    my $self = {};

    bless($self, $class);
    return $self;
}

sub iostat {

    my ($self) = @_;

    my (@cmd_output, @counters, @devices);
    my ($dev_num, $num_counters);
    my $io = {};

    @cmd_output = split('\n', `/usr/bin/iostat -d`);
    @cmd_output = @cmd_output[2..$#cmd_output];
    push(@counters, split(/\s+/, $cmd_output[0]));
    shift @counters;
    splice(@counters, 3);
    shift @cmd_output;

# Number of counters:
    $num_counters = $#counters;

# Number of devices:
    $dev_num = $#cmd_output;

    for(my $i=0; $i<=$dev_num; $i++) {

	my @data = split(/\s+/, $cmd_output[$i]);
	$devices[$i] = $data[0];
	shift @data;
	splice(@data, 3);

	my %metrics = ();

	for(my $c=0; $c<=$num_counters; $c++) {
	    # This is the inner hash (needs pushing into $io later):
	    $metrics{$counters[$c]} = $data[$c]*1;
	}

	$io->{$devices[$i]} = \%metrics;
    }

    return $io or die help();
}

sub help{
    my $msg = <<'EOF';
---- vPAN::Iostat (v0.0.1) ----
The class expects device name and a counter.

Counter list:
	'tps' (transactions per second),
	'kB_read/s' (Bytes read pes second),
	'kB_wrtn/s' (Bytes written per second)

Usage examples:
	my $var = new vPAN::Iostat;
    	my $stat = $var->iostat();
	my $sda_tps = $stat->{'sda'}{'tps'};
	my $help = $stat->help();
	print $help;
EOF
}

1;
