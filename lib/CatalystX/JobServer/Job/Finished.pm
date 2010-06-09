package CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Moose;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use MooseX::Types::Moose qw/ Bool /;

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

has ok => (
    isa => Bool,
    is => 'ro',
    default => 1,
);

has running_job => (
    isa => 'CatalystX::JobServer::Job::Running',
    is => 'ro',
    required => 1,
);

has finish_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
    traits => ['Serialize']
);

__PACKAGE__->meta->make_immutable;
