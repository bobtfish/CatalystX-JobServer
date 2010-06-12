package CatalystX::JobServer::Role::QueueListener;
use CatalystX::JobServer::Moose::Role;
use JSON qw/ decode_json /;

requires 'act_on_message';

sub consume_message {
    my ($self, $message, $publisher) = @_;
    print $message->{deliver}->method_frame->routing_key,
        ': ', $message->{body}->payload, "\n";
    # FIXME - deal with not being able to unserialize
    my $data = decode_json($message->{body}->payload);
    my $class = $data->{__CLASS__}; # FIXME - Deal with bad class.
    unless ($class) {
        return;
    }
    my $object = $class->unpack($data);
    $self->act_on_message($object, $publisher);
}


1;
