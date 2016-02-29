use HTTP::Response;

use Message;

package Client
{
    sub new
    {
        my $invocant = shift;
        my $class = ref($invocant) || $invocant;
        my %args = @_;
        my $self = {
            '_socket' => $args{socket},
            '_rCB' => $args{read_cb},
            '_wCB' => $args{write_cb},
            '_dCB' => $args{disconnect_cb},
            '_messageQueue' => (),
            '_listeners' => ()
        };
        return undef if (!$self->{_socket});
        return bless($self, $class);
    }
    
    sub init
    {
        my $self = shift;
        $self->{_listeners}[0] = AE::io($self->getFh(), 0, sub
        {
            $self->handleRead();
        }) if ($self->{_rCB});
        $self->{_listeners}[1] = AE::io($self->getFh(), 1, sub
        {
            $self->handleWrite();
        }) if ($self->{_wCB});
    }
    
    sub handleRead
    {
        my $self = shift;
        if (my $r = $self->{_socket}->get_request())
        {
            if ($r->method eq 'GET')
            {
                $self->{_rCB}($self->getFd());
            }
        }
        elsif ($self->{_dCB})
        {
            $self->{_dCB}($self->getFd());
        }
    }
    
    sub handleWrite
    {
        my $self = shift;
        if (@{$self->{_messageQueue}} > 0)
        {
            my $res = HTTP::Response->new(200);
            $res->content(shift(@{$self->{_messageQueue}}));
            $self->getFh()->send_response($res);
            $self->{_wCB}($self->getFd());
        }
    }
    
    sub scheduleMessage
    {
        my $self = shift;
        my ($message) = @_;
        push(@{$self->{_messageQueue}}, $message);
    }

    sub getFh
    {
        my $self = shift;
        return $self->{_socket};
    }
    
    sub getFd
    {
        my $self = shift;
        return fileno($self->getFh());
    }
    
    sub DESTROY
    {
        my $self = shift;
        print "[" . $self->getFd() . "] =( /\n";
#        $self->{_socket}->close();
    }
}1;