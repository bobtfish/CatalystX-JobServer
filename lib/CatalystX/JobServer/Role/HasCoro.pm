package CatalystX::JobServer::Role::HasCoro;
use Moose::Role;
use Coro;
use namespace::autoclean;

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
