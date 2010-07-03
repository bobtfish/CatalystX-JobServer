package CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Moose;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

extends 'CatalystX::JobServer::Job::Running';

# FIXME - Gross, use a TC?
around BUILDARGS => sub {
    my ($orig, $self, @args) = @_;
    my $args = $self->$orig(@args);
    $args->{running_job} = delete $args->{job};
    $args->{job} = $args->{running_job}->job;
    $args->{start_time} = $args->{running_job}->start_time;
    return $args;
};

has '+return_cb' => (
    lazy => 1,
    default => sub { shift->running_job->return_cb },
);

has ok => (
    isa => Bool,
    is => 'ro',
    default => 1,
    traits => ['Serialize'],
);

has running_job => (
    isa => 'CatalystX::JobServer::Job::Running',
    is => 'ro',
    required => 1,
#    traits => ['Serialize'],
);

has finish_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
    traits => ['Serialize']
);

method finalize { $self->return_cb->($self) }

__PACKAGE__->meta->make_immutable;
