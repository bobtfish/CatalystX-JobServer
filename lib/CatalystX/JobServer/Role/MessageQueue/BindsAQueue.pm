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

=head1 NAME

CatalystX::JobServer::Role::MessageQueue::BindsAQueue

=head1 DESCRIPTION

Role for components which cause a single queue to be bound to a single exchange with a single routing key.

=head1 ATTRIBUTES

=head2 bind_routing_key

Defaults to C<#>, which is a wildcard

=head1 CONSUMES

=over

=item L<CatalystX::JobServer::Role::MessageQueue::BindsQueues>

=item L<CatalystX::JobServer::Role::MessageQueue::DeclaresExchange>

=item L<CatalystX::JobServer::Role::MessageQueue::DeclaresQueue>

=back

=cut
