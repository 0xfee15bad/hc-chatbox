use HTTP::Response;

use Message;

package Client
{
    sub new
    {
        my $invocant = shift;
        my $class = ref($invocant) || $invocant;
        my ($socket) = @_;
        my $self = {
            '_socket' => $socket
        };
        return bless($self, $class);
    }
    
    sub init
    {
        my $self = shift;
        AE::io($self->getFd(), 0, \$self->handeRead);
    }
    
    sub handeRead
    {
        my $self = shift;
        print $self->getFd() . " =)\n";
    }
    
    sub handeWrite
    {
        my $self = shift;
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
}1;