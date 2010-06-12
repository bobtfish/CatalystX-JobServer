package CatalystX::JobServer::LogWriter;
use CatalystX::JobServer::Moose;
use MooseX::Types::Path::Class qw/ File /;
use MooseX::Types::Moose qw/ Int /;

has output_file => (
    is => 'ro',
    required => 1,
    isa => File,
    coerce => 1,
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
    traits => ['Counter'],
    handles => {
        "_inc_messages_logged"   => 'inc',
    },
);

method BUILD { $self->fh }

method consume_message ($message, $publisher) {
    $self->fh->write($message);
    $self->_inc_messages_logged;
}

__PACKAGE__->meta->make_immutable;
