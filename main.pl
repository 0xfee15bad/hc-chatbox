#!/usr/bin/env perl

use strict;
use warnings;
#
use HTTP::Daemon;
use AnyEvent;
use AnyEvent::Strict;
#
use Client;

my %clients;

sub handle_read
{
    my ($client_fd) = @_;
    print "Read event from " . $client_fd . "\n";
    $clients{$client_fd}->scheduleMessage('Hello ' . $client_fd . ' 8' . ('='x(rand(15) + 1)) . 'D');
}

sub handle_write
{
    my ($client_fd) = @_;
    print "Write event from " . $client_fd . "\n";
}

sub handle_disco
{
    my ($client_fd) = @_;
    delete $clients{$client_fd};
}

my $sSock = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 6666,
    ReuseAddr => 1
) || die 'Couldn\'t create the server';

my $cv = AE::cv;

my $sWatcher = AE::io($sSock, 0, sub {
	if (my $socket = $sSock->accept())
	{
        ($clients{fileno($socket)} = Client->new(
            socket => $socket,
            read_cb => \&handle_read,
            write_cb => \&handle_write,
            disconnect_cb => \&handle_disco
        ))->init();
	}
});

$cv->recv;