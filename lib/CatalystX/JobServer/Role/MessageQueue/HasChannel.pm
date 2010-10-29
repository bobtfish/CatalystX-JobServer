package CatalystX::JobServer::Role::MessageQueue::HasChannel;
use CatalystX::JobServer::Moose::Role;

has message_queue_model => (
    is => 'ro',
);

has _channel => (
    is => 'ro',
    lazy => 1,
    default => sub {
        shift->message_queue_model->open_channel;
    }
);

1;
