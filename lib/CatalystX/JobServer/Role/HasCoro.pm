package CatalystX::JobServer::Role::HasCoro;
use CatalystX::JobServer::Moose::Role;
use Coro;

requires '_async';

sub BUILD {}
after 'BUILD' => sub {
    my $self = shift;
    my $code = $self->_async;
    async {
        $code->($self);
    };
};

1;
