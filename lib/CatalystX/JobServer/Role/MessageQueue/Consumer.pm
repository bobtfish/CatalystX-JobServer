package CatalystX::JobServer::Role::MessageQueue::Consumer;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Bool /;
use Scalar::Util qw/ refaddr /;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

requires 'consume_message';

after BUILD => sub {
    shift->build_messagequeue_consumer;
};

has _have_built_consumer => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

method build_messagequeue_consumer {
    return if $self->_have_built_consumer;
    $self->_have_built_consumer(1);
    $self->_channel->consume(
        on_consume => sub {
            my $message = shift;
            $self->consume_message($message);
        },
        consumer_tag => refaddr($self),
    )
}

method cancel_messagequeue_consumer {
    $self->_channel->cancel(
        consumer_tag => refaddr($self),
    );
    $self->_have_built_consumer(0);
}

1;
