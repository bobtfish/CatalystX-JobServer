package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::CompletionEstimate;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ Int Str /;

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

has status_info => (
    isa => Str,
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        printf("%s out of %d complete", $self->steps_taken, $self->step_count);
    },
);

has step_count => (
    is => 'ro',
    isa => Int,
    traits => ['Serialize'],
);

has steps_taken => (
    is => 'ro',
    isa => Int,
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
