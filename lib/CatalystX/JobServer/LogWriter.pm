package CatalystX::JobServer::LogWriter;
use CatalystX::JobServer::Moose;
use MooseX::Types::Path::Class qw/ File /;
use MooseX::Types::Moose qw/ Int Object /;
use AnyEvent;

with 'CatalystX::JobServer::Role::Storage';

has output_file => (
    is => 'ro',
    required => 1,
    isa => File,
    coerce => 1,
    traits => ['Serialize'],
);

has fh => (
    is => 'ro',
    lazy => 1,
    default => sub { shift->output_file->openw },
);

has messages_logged => (
    init_arg => undef,
    lazy => 1, # FIXME Moose bug
    isa => Int,
    is => 'ro',
    default => 0,
    traits => ['Counter', 'Serialize'],
    handles => {
        "_inc_messages_logged"   => 'inc',
    },
);

has _flush_pending => (
    is => 'rw',
);

method BUILD { $self->fh }

method consume_message ($message, $publisher) {
    my $payload = $message->{body}->payload;
    $payload .= "\n" unless $payload =~ /\n$/;
    my $write = $message->{deliver}->method_frame->routing_key . ': ' . $payload;
#    print $message->{deliver}->method_frame->routing_key,
#        ': ', $payload;
    $self->fh->write($write);
    if (!$self->_flush_pending) {
        $self->_flush_pending(AnyEvent->timer(after => 1, cb => sub { $self->_flush_pending(undef); $self->fh->flush; }));
    }
    $self->_inc_messages_logged;
}

__PACKAGE__->meta->make_immutable;
