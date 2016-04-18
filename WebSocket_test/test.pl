use HTTP::Daemon;
use Protocol::WebSocket;
use POSIX;

my $d = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 80,
    ReuseAddr => 1
) || die 'Couldn\'t create the server';

while (my $c = $d->accept())
{
    if (my $r = $c->get_request())
    {
        if ($r->method eq 'GET')
        {
            my $hs = Protocol::WebSocket::Handshake::Server->new;
            my $frame;
            
            $hs->parse($r->as_string());
            if ($hs->is_done)
            {
                $c->send_response(HTTP::Response->parse($hs->to_string()));
                my $buf;
                while ($c->sysread($buf, 2048))
                {
                    my $frame = $hs->build_frame(buffer => $buf);
                    while (defined(my $message = $frame->next))
                    {
                        if ($frame->is_close())
                        {
                            my $content = $hs->build_frame(type => 'close')->to_bytes();
                            $c->syswrite($content, length($content));
                            $c->close();
                        }
                        elsif ($frame->is_text())
                        {
                            print '-> ' . $message . "\n";
                            ##
                            my $content = $hs->build_frame(buffer => 'Hello there, I\'m the server :^)/')->to_bytes();
                            my $oBytes = length($content);
                            my $rBytes = $oBytes;
                            print 'Sending frame of ' . $rBytes . " bytes\n";
                            while ($rBytes > 0) # simulates partial writes
                            {
                                my $toSend = ceil($rBytes / 2);
                                $c->syswrite($content, $toSend);
                                print ' | ' if ($rBytes < $oBytes);
                                print $toSend;
                                $content = substr($content, $toSend);
                                $rBytes -= $toSend;
                            }
                            print "\n";
                        }
                    }
                }
            }
        }
    }
}