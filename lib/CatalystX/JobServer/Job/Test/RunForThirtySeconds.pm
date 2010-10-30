package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use CatalystX::JobServer::Moose;
use AnyEvent;
use Data::UUID;
use MooseX::Types::Moose qw/ Num Str /;
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::StatusLine';
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::CompletionEstimate';

with 'CatalystX::JobServer::Role::Storage';

has val => (
    isa => Num,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

my $d = Data::UUID->new;
has uuid => (
    isa => Str,
    is => 'ro',
    traits => ['Serialize'],
    default => sub {
        $d->to_string($d->create);
    },
);

method run ($cb) {
    for (1..10) {
        sleep 3 + int($self->val);
        $cb->(StatusLine->new("Hello there, this is loop iteration $_"));
        $cb->(CompletionEstimate->new(step_count => 10, steps_taken => $_));
    }
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
