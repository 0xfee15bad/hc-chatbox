use HTTP::Daemon;
use Protocol::WebSocket;

print "=)/\n";

my $d = HTTP::Daemon->new(
    LocalAddr => '127.0.0.1',
    LocalPort => 6666,
    ReuseAddr => 1
) || die 'Couldn\'t create the server';

while (my $c = $d->accept())
{
    while (my $r = $c->get_request())
    {
        if ($r->method eq 'GET')
        {
            my $hs    = Protocol::WebSocket::Handshake::Server->new;
            my $frame = Protocol::WebSocket::Frame->new;
            
            $hs->parse($r->as_string);
            if ($hs->is_done)
            {
                $c->send_response(HTTP::Response->parse($hs->to_string()));
#                for my $i (0..9)
#                {
#                    print($c, "( ͡°ل͜ ͡°)");
#                }
            }
        }
    }
    $c->close();
    undef($c);
}