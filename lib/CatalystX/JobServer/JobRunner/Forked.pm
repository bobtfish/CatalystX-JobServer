package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ ArrayRef HashRef Int /;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use namespace::autoclean;

with 'CatalystX::JobServer::JobRunner';

has num_workers => (
    isa => Int,
    is => 'ro',
    default => 5,
    traits => ['Serialize'],
);

has worker_state_class => (
    isa => LoadableClass,
    is => 'ro',
    coerce => 1,
    default => 'CatalystX::JobServer::JobRunner::Forked::WorkerState',
    handles => {
        _new_worker => 'new',
    }
);

has _workers => (
    isa => ArrayRef,
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        # FIXME weaken self into closure
        return [ map { $self->_new_worker( job_finished_cb => sub {
            my $job = shift;
            my $output = shift;
            $self->job_finished($job, $output);
            $self->_hit_max->send if $self->_hit_max
        }) } 1..$self->num_workers ], },
);

has _hit_max => (
    is => 'rw',
    clearer => '_clear_hit_max',
    predicate => '_has_hit_max',
);

sub BUILD {
    my $self = shift;
    $self->_workers;
}

sub _first_free_worker {
    my ($self) = @_;
    (grep { $_->free } @{ $self->_workers })[0];
}

sub _do_run_job {
    my ($self, $job) = @_;

    # This is fairly subtle, we need to block if we have too many jobs.
    # Here is how it works:
    #  - Find a free worker (where the value for the PID is undef)
    #  - Set value to true before re-entering event loop (so worker PID is claimed).
    #  - If there are no free workers then setup a condvar and recv on it
    #  - Every job which finishes should reset it's freeness state (before the event loop),
    #    then if there is a jobs waiting convar, grab it, clear it, send on it..
    #    (like that, so that if the next thread that runs hits max workers (again),
    #     it will set a _new_ condvar)
    my $worker;
    do {
        $worker = $self->_first_free_worker;
        if (!$worker) {
            warn("Hit max number of concurrent workers, num workers: " . $self->num_workers . " num running " . scalar(grep { ! $_->free } @{$self->_workers}));
            $self->_hit_max(AnyEvent->condvar)
                unless $self->_has_hit_max;
            $self->_hit_max->recv;
            $self->_clear_hit_max;
        }
    } while (!$worker);

#    warn Data::Dumper::Dumper($job);
    $worker->run_job($job);
}


__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::JobRunner::Forked - Class providing persistent perl job worker processes.

=head1 DESCRIPTION

Maintains a pool of L<CatalystX::JobServer::JobRunner::Forked::Worker> processes, which are sent
jobs and which return results.

=cut
