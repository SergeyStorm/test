#!/usr/bin/perl

use strict;
use warnings;

use AnyEvent;
use AnyEvent::HTTP;
use Time::HiRes qw(time);

$| = 1;

my $cv = AnyEvent->condvar;
my @urls;
my %stat;

while( my $url = <STDIN> ) {
	chomp $url;
	push @urls, $url;
	$stat{ $url }{ 'start' } = time();
	$cv->begin();
	http_get( $url, sub {
		$stat{ $url }{ 'end' } = time();
		my ($result) = @_;
		if ( $result ) {
			print $result."\n";
		}
		$cv->end();
	});
}

$cv->recv();

print "\nDownload completed\n\n";
foreach my $url ( @urls ) {
	my $shift = $stat{ $url }{ 'end' } - $stat{ $url }{ 'start' };
	print $shift."\t$url\n";
}

1;
