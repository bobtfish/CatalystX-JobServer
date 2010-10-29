package CatalystX::JobServer::Role::MessageQueue::Consumer;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Bool /;
use Scalar::Util qw/ refaddr /;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

requires 'consume_message';

after BUILD => sub {
    shift->build_consumer;
};

has _have_built_consumer => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

method build_consumer {
    warn("BUILD CONSUMER FOR $self");
    return if $self->_have_built_consumer;
    $self->_have_built_consumer(1);
    $self->_channel->consume(
        on_consume => sub {
            my $message = shift;
            $self->consume_message($message);
        },
        consumer_tag => ref($self),
    )
}

method cancel_consumer {
    $self->_channel->cancel( sub { warn("Cancelled queue"); $self->_have_built_consumer(0); },
        consumer_tag => refaddr($self),
    );
}

1;
