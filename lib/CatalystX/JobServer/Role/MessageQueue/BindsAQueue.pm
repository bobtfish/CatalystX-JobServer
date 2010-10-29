package CatalystX::JobServer::Role::MessageQueue::BindsAQueue;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Str /;

with qw/
    CatalystX::JobServer::Role::MessageQueue::BindsQueues
    CatalystX::JobServer::Role::MessageQueue::DeclaresExchange
    CatalystX::JobServer::Role::MessageQueue::DeclaresQueue
/;

has bind_routing_key => (
    isa => Str,
    is => 'ro',
    default => '#',
);

before BUILD => sub {
    my $self = shift;
    $self->_exchange;
    $self->_queue;
    $self->bind_queue($self->queue_name, $self->exchange_name, $self->bind_routing_key);
};

1;
