package CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Moose;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use MooseX::Types::Moose qw/ Bool HashRef /;
use JSON;
use namespace::autoclean;

with 'CatalystX::JobServer::Role::Storage';

# FIXME - Gross, use a TC?
around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;
    my $args = $self->$orig(@args);
    $args->{job} = from_json($args->{job}) unless ref($args->{job});
    return $args;
};

has job => (
    isa => HashRef,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

has ok => (
    isa => Bool,
    is => 'ro',
    default => 1,
    traits => ['Serialize'],
);

has finish_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
    traits => ['Serialize']
);

method finalize { }

__PACKAGE__->meta->make_immutable;

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut

