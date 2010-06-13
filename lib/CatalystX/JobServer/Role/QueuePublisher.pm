package CatalystX::JobServer::Role::QueuePublisher;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Code /;

has publish_message_callback => (
    isa => Code,
    is => 'ro',
    required => 1,
);

sub publish_message {
    my ($self, $channel_name, $message) = @_;
    $self->publish_message_callback->($channel_name, $message);
}

1;
