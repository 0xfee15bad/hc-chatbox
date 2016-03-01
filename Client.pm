use HTTP::Response;


use Message;

package Client
{
    sub new
    {
        my $invocant = shift;
        my $class = ref($invocant) || $invocant;
        my %args = @_;
        my $self =
        {
            '_sockets' =>
            {
                0 => $args{socket}
            },
            '_rCB' => $args{read_cb},
            '_wCB' => $args{write_cb},
            '_dCB' => $args{disconnect_cb},
            '_messageQueue' => [],
            '_watchers' => {}
        };
        return (defined($self->{_sockets}{0})) ? bless($self, $class) : undef;
    }
    
    sub init
    {
        my $self = shift;
        
        my ($sockIdx) = @_;
        $sockIdx = 0 if (!defined($sockIdx));

        $self->{_watchers}{$sockIdx * 2} = AE::io($self->getFh($sockIdx), 0, sub
        {
            $self->handleRead($sockIdx);
        }) if ($self->{_rCB});

        $self->{_watchers}{$sockIdx * 2 + 1} = AE::io($self->getFh($sockIdx), 1, sub
        {
            $self->handleWrite($sockIdx);
        }) if ($self->{_wCB});
    }
    
    sub addSocket
    {
        my $self = shift;
        
        my ($newSocket) = @_;
        my $i;
        for ($i = 0; defined($self->{_sockets}{$i}); ++$i) {}
        $self->{_sockets}{$i} = $newSocket;
        $self->init($i);
    }
    
    sub handleRead
    {
        my $self = shift;

        my ($sockIdx) = @_;
        if (my $r = $self->getFh($sockIdx)->get_request())
        {
            if ($r->method eq 'GET')
            {
                $self->{_rCB}($self->getFd($sockIdx));
            }
        }
        elsif ($self->{_dCB})
        {
            delete $self->{_watchers}{$sockIdx * 2};
            delete $self->{_watchers}{$sockIdx * 2 + 1};
            if (keys %{$self->{_sockets}} == 0)
            {
                $self->{_dCB}($self->getFd($sockIdx));
            }
            else
            {
                delete $self->{_sockets}{$sockIdx};
            }
        }
    }
    
    sub handleWrite
    {
        my $self = shift;

        my ($sockIdx) = @_;
        if (@{$self->{_messageQueue}} > 0)
        {
            my $res = HTTP::Response->new(200);
            $res->content(shift(@{$self->{_messageQueue}}));
            $self->getFh($sockIdx)->send_response($res);
            $self->{_wCB}($self->getFd($sockIdx));
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
        
        my ($sockIdx) = @_;
        return $self->{_sockets}{$sockIdx};
    }
    
    sub getFd
    {
        my $self = shift;
        
        my ($sockIdx) = @_;
        return fileno($self->getFh($sockIdx));
    }
    
    sub DESTROY
    {
        my $self = shift;
    }
}1;