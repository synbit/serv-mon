package vPAN::APC;
use strict;
use warnings;
use Data::Dump qw(dump);

sub new {
    my ($class) = @_;
    my $self = {};

    bless($self, $class);
    return $self;
}

sub apc {
    my ($i, $apcstats); 
    my @apcout;

    @apcout = split('\n', `/sbin/apcaccess`);

    for($i=0; $i<=$#apcout; $i++) {
	my @temp = split(/\s*:\s*/, $apcout[$i]);
	$apcstats->{"$temp[0]"} = $temp[1];
    }

    return $apcstats;
}

1;
