use HTTP::Response;

package Message
{
    sub new
    {
        my $invocant = shift;
        my $class = ref($invocant) || $invocant;
        my $self = {
            '_response' => HTTP::Response->new(200)
        };
        $self = bless($self, $class);
        $self->formatResponse(@_);
        return $self;
    }
    
    sub _formatResponse
    {
        my $self = shift;
        my %arg = { @_ };
        $self->getResponse()->content($arg{user} . ' : ' . $arg{message});
    }
    
    sub getResponse
    {
        my $self = shift;
        return $self->{_response};
    }
}1;