package CatalystX::JobServer::Role::QueueConsumer::LogMessageStructured;
use CatalystX::JobServer::Moose::Role;
use JSON qw/ decode_json /;
use Try::Tiny;

with 'CatalystX::JobServer::Role::QueueConsumer';

requires 'act_on_message';

sub consume_message {
    my ($self, $message, $publisher) = @_;

    my $payload = $message->{body}->payload;

    my $data;
    try {
        $data = decode_json($payload);
    }
    catch {
        warn(blessed($self) . "could not decode JSON, error: $_ message $payload\n");
        return;
    };

    my $class = $data->{__CLASS__};

    unless ($class) {
        warn(blessed($self) . " no __CLASS__ in message, cannot unpack: $payload\n");
        return;
    }
    unless (Class::MOP::is_class_loaded($class)) {
        warn(blessed($self) . " class $class not loaded, cannot unpack! ($payload)\n");
        return;
    }

    my $object;
    try {
        $object = $class->unpack($data);
    }
    catch {
        warn(blessed($self) . " class $class threw for ->unpack method: $_ ($payload)\n");
        return;
    };
    $self->act_on_message($object, $publisher);
}

1;

