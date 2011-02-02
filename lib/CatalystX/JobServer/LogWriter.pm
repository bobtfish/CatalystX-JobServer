package CatalystX::JobServer::LogWriter;
use CatalystX::JobServer::Moose;
use MooseX::Types::Path::Class qw/ File /;
use MooseX::Types::Moose qw/ Int Object /;
use AnyEvent;
use Fcntl;
use IO::Seekable;

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
    default => sub {
        my $self = shift;
        my $fh = $self->output_file->openw
            or Carp::coness("Cannot open " . $self->output_file . " for writing: $!");
        $fh->seek(0, SEEK_END);
        $fh;
    },
    clearer => '_close_fh',
    handles => {
        _write_fh => 'write',
    },
);

after _write_fh => sub { shift->_schedule_flush };
before _close_fh => sub { shift->_do_flush };

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

has _flush => (
    reader => '_schedule_flush',
    clearer => '_do_flush',
    lazy => 1,
    default => sub {
        my $self = shift;
        AnyEvent->timer(
            after => 1,
            cb => sub { $self->_do_flush },
        );
    },
);

after _do_flush => sub { shift->fh->flush };

has _hup_handler => (
    is => 'ro',
    default => sub {
        my $self = shift;
        AnyEvent->signal (
            signal => 'HUP',
            cb => sub { $self->_close_fh; $self->_fh; },
        );
    },
);

method BUILD { $self->fh }

method consume_message ($message, $publisher) {
    my $payload = $message->{body}->payload;
    $payload .= "\n" unless $payload =~ /\n$/;
    my $write = $message->{deliver}->method_frame->routing_key . ': ' . $payload;
#    print $message->{deliver}->method_frame->routing_key,
#        ': ', $payload;
    $self->_write_fh($write);
    $self->_inc_messages_logged;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::LogWriter - Class to listen for a queue and write the output to a file.

=head1 SYNOPSIS

    Model::FireHoseLog:
        class: "CatalystX::JobServer::LogWriter"
        args:
            output_file: __path_to(firehose.log)__
            
=head1 DESCRIPTION

Logs any messages dispatched to it to a file. Ensures that the file a sync'd to disk once a second
(to ensure that messages are flushed regularly, but without forcing an fsync per line).

Any process with one (or more) of these classes will close and re-open the output log file handles
on SIGHUP. This can (and should) be used after log rotation to force the process to re-open it's log
files (and close those which have been rotated away).

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut
