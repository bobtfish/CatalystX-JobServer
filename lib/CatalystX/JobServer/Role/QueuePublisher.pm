package CatalystX::JobServer::Role::QueuePublisher;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ CodeRef /;

has publish_message_callback => (
    isa => CodeRef,
    is => 'ro',
    required => 1,
);

sub publish_message {
    my ($self, $channel_name, $message) = @_;
#    warn("Publish to $channel_name $message");
    $self->publish_message_callback->($channel_name, $message);
}

1;
