#!/usr/bin/env perl

use strict;
use warnings;

use HTTP::Daemon;
use AnyEvent;
use AnyEvent::Strict;

use Client;

my $sSock = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 6666,
    ReuseAddr => 1
) || die 'Couldn\'t create the server';

my $cv = AE::cv;

my %cSocks;
my %cRWatchers;
my %cWWatchers;
my %clients;

sub client_write
{
    my ($idx) = @_;
    return sub {
		print "[$idx] writing to client\n";
		my $res = HTTP::Response->new(200);
		$res->content('8' . ('='x(rand(15) + 1)) . 'D' . "\n");
		$cSocks{$idx}->send_response($res);
		delete $cWWatchers{$idx};
    };
}

sub client_read
{
    my ($idx) = @_;

    return sub {
		my $r;
		if (my $r = $cSocks{$idx}->get_request())
		{
			if ($r->method eq 'GET')
			{
				$cWWatchers{$idx} = AE::io($cSocks{$idx}, 1, client_write($idx));
			}
		}
		else # socket closed by client
		{
			print "[$idx] connection closed\n";
			delete $cRWatchers{$idx};
			close($cSocks{$idx});
		}
    };
}

my $sWatcher = AE::io($sSock, 0, sub {
	if (my $socket = $sSock->accept())
	{
        $clients{fileno($socket)} = Client->new($socket);
        $clients{fileno($socket)}->init();
#	    $cSocks{fileno($socket)} = $socket;
#	    print "[" . fileno($socket) . "] connection opened from " . $socket->peerhost() . "\n";
	    # works
#        $cRWatchers{fileno($socket)} = AE::io($socket, 0, client_read(fileno($socket)));
	}
});

$cv->recv;