package vPAN::Mpstat;
use strict;
use warnings;
use Data::Dump qw(dump);

sub new {

    my ($class) = @_;
    my $self = {};

    bless($self, $class);
    return $self;
}

sub cpustat {

    my ($self) = @_;

    my (@mpstat_out, @headers, @all_cpus, @make_array);
    my ($num_cpus, $num_counters);
    my $cpus = {};

    my @cmd_output = split('\n', `/usr/bin/mpstat -P ALL 1 1`);
    @cmd_output = grep(/^Average/, @cmd_output);

    push(@headers, split(/\s+/, $cmd_output[0]));

# We saved the headers, don't need the current 0th element anymore:
    shift @cmd_output;
    splice(@headers, 0, 2);

# Get rid of the '%' sign:
    for(@headers) {
	s/%//g;
    }

# Store the metrics for all CPUs in @all_cpus:
    push(@all_cpus, split(/\s+/, $cmd_output[0]));
    splice(@all_cpus, 0, 2);

# Could store the totals, but it's not accurate anyway.
# The main script can deal with this, so don't need the current 0th element:
    shift @cmd_output;
    $num_cpus = $#cmd_output;
    $num_counters = $#headers;

# Actually, we will need to push this into the final hash, so make one:
    my %totals = ();
    for(my $i=0; $i<=$num_counters; $i++) {
	$totals{$headers[$i]} = $all_cpus[$i];
    }

# Construct the object to be returned to the main:
    for(my $c=0; $c<=$num_cpus; $c++) {

	@make_array = split(/\s+/, $cmd_output[$c]);
	splice(@make_array, 0, 2);
	my %metrics = ();

	for(my $k=0; $k<=$num_counters; $k++) {
	    $metrics{$headers[$k]} = $make_array[$k]*1;
	}

	$cpus->{"cpu_$c"} = \%metrics;
    }
    
# Push into $cpus the %totals:
    $cpus->{'cpu_all'} = \%totals;

    return $cpus or die help();
}

sub help {
    my $msg = <<'EOF';
---- vPAN::Mpstat (v0.0.1) ----
The class expects core number (zero-indexed) and a counter.

Counter list:
	usr, nice, sys, iowait, irq, soft, steal, guest, idle, total

Usage examples:
	my $var = new vPAN::Mpstat;
        my $stat = $var->cpustat();
        my $cpu_idle = $stat->{'cpu_0'}{'idle'};
        my $totals = $stat->{'cpu_all'}{'iowait'};
        my $help = $stat->help();
        print $help;
EOF
}

1;
