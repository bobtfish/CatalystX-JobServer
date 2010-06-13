package CatalystX::JobServer::Role::QueueListener;
use CatalystX::JobServer::Moose::Role;
use JSON qw/ decode_json /;
use MooseX::Types::Moose qw/ Bool /;
use Try::Tiny;

requires 'act_on_message';

has debug_messages_consumed => (
    isa => Bool,
    is => 'ro',
    default => 0,
);

sub consume_message {
    my ($self, $message, $publisher) = @_;

    my $payload = $message->{body}->payload;

    warn blessed($self) .
        ' got: ', $payload, "\n"
        if $self->debug_messages_consumed;

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
