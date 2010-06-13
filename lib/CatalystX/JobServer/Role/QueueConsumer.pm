package CatalystX::JobServer::Role::QueueConsumer;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Bool /;

requires 'consume_message';

has debug_messages_consumed => (
    isa => Bool,
    is => 'ro',
    default => 0,
);

before consume_message => sub {
    my ($self, $message, $publisher) = @_;

    my $payload = $message->{body}->payload;

    warn blessed($self) .
        ' got: ', $payload, "\n"
        if $self->debug_messages_consumed;
};

1;
