package CatalystX::JobServer::Role::MessageQueue::HasChannel;
use CatalystX::JobServer::Moose::Role;

with 'Catalyst::Component::ApplicationAttribute';

has _channel => (
    is => 'ro',
    lazy => 1,
    default => sub {
        shift->_application->model('MessageQueue')->open_channel;
    }
);

1;
