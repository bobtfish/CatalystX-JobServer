package CatalystX::JobServer::Role::MessageQueue::Consumer;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

requires 'consume_message';

after BUILD => sub {
    my $self = shift;
    $self->_channel->consume(
        on_consume => sub {
            my $message = shift;
            $self->consume_message($message);
        },
    )
}

1;
