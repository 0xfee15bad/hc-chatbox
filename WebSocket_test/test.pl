use HTTP::Daemon;
use Protocol::WebSocket;

my $d = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 6666,
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
                if ($c->recv($buf, 1024))
                {
                    my $frame = $hs->build_frame(buffer => $buf);
                    while (defined(my $message = $frame->next))
                    {
                        print '-> ' . $message . "\n";
                        $c->send($hs->build_frame(buffer => ':^)/')->to_bytes());                        
                    }
                }
            }
        }
    }
    $c->close();
    undef($c);
}