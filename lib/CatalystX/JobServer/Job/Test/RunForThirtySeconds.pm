package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use CatalystX::JobServer::Moose;
use AnyEvent;
use Data::UUID;
use MooseX::Types::Moose qw/ Num Str /;
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::StatusLine';
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::CompletionEstimate';
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::RunJob';

with 'CatalystX::JobServer::Role::Storage';

method exchange_name { 'jobs' }

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

has message => (
    is => 'ro',
    default => 'Hello there',
    traits => ['Serialize'],
);

has depth => (
    is => 'ro',
    default => 1,
    traits => ['Serialize'],
);

method run ($cb) {
    for (1..10) {
        sleep int($self->val);
        $cb->(StatusLine->new(status_info => $self->message . ", this is loop iteration $_", uuid => $self->uuid));
        $cb->(CompletionEstimate->new(step_count => 10, steps_taken => $_, uuid => $self->uuid));
    }
    $cb->(RunJob->new(job => __PACKAGE__->new( depth => $self->depth + 1, val => 1, message => "No: " . ($self->depth + 1) . " set" ), uuid => $self->uuid))
        if (rand(10) > 3);
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
