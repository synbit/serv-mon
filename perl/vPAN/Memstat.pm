package vPAN::Memstat;
use strict;
use warnings;
use Data::Dump qw(dump);

sub new {
    my ($class) = @_;
    my $self = {};

    bless($self, $class);
    return $self;
}

sub memstat {

    my ($self) = @_;

    my ($total, $free, $buffers, $cached, $used);
    my $mem = {};
    my $source = '/proc/meminfo';

    open(INPUTFILE, $source) or die "Unable to open file: '$source'\n";

    while(<INPUTFILE>) {

	push(my @line, split(/\s+/,$_));

	# Remove the colons from the descriptions in /proc/meminfo :
	$line[0] =~ s/://g;

	if($line[0] =~ /^MemTotal/) {
	    $mem->{$line[0]} = $line[1];
	    $mem->{'MemTotalUnit'} = $line[2];
	}
	elsif($line[0] =~ /^MemFree/) {
	    $mem->{$line[0]} = $line[1];
	    $mem->{'MemFreeUnit'} = $line[2];
	}
	elsif($line[0] =~ /^Buffers/) {
	    $mem->{$line[0]} = $line[1];
	    $mem->{'BuffersUnit'} = $line[2];
	}
	elsif($line[0] =~ /^Cached/) {
	    $mem->{$line[0]} = $line[1];
	    $mem->{'CachedUnit'} = $line[2];
	}
    }

    $used = $mem->{'MemTotal'} - $mem->{'MemFree'} - $mem->{'Buffers'} - $mem->{'Cached'};
    $mem->{'Used'} = $used;

    # Check the units have changed in '/proc/meminfo' :
    for("MemTotalUnit", "MemFreeUnit", "BuffersUnit", "CachedUnit") {
	if($mem->{$_} ne 'kB') {
	    die "'$source' units have changed; '$0' needs to accomodate this...\n";
	}
    }

    $mem->{'UsedUnit'} = 'kB';

    close(INPUTFILE);

    return $mem or die help();
}

sub help {
    my $msg = <<'EOF';
---- vPAN::Memstat (v0.0.1) ----
This module reads memory information from /proc/meminfo.

Usage example:
    my $var = new vPAN::Memstat;
    my $stat = $var->memstat();
    my $help = $stat->help();
    print $help;
EOF
}

1;
