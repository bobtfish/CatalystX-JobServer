package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use MooseX::Types::Moose qw/ HashRef Int /;
use AnyEvent;
use AnyEvent::Handle;
use Coro;
use namespace::autoclean;
use CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Job::Running;

with 'CatalystX::JobServer::JobRunner';

has num_workers => (
    isa => Int,
    is => 'ro',
    default => 5,
    traits => ['Serialize'],
);

has _workers => (
    isa => ArrayRef,
    is => 'ro',
    default => sub { [], },
);

has _hit_max => (
    is => 'rw',
);

foreach (qw/ write read /) {
    has '_' . $_ . '_handles' => (
        isa => HashRef,
        is => 'ro',
        default => sub { {} },
    );
}

sub BUILD {
    my $self = shift;
    my $n = $self->num_workers;
    $self->_spawn_worker for (1..$n);
}

sub _first_free_worker {
    my ($self) = @_;
    (grep { ! $self->_workers->{$_} } keys %{ $self->_workers })[0];
}

sub _do_run_job {
    my ($self, $job) = @_;

    # Ensure we have enough workers already running
    my $n_workers_short = $self->num_workers - scalar(keys %{$self->_workers});
    if ($n_workers_short > 0) {
        warn("Short of workers, spawning $n_workers_short");
        for (1..$n_workers_short) {
            $self->_spawn_worker();
        }
    }

    # This is fairly subtle, we need to block if we have too many jobs.
    # Here is how it works:
    #  - Find a free worker (where the value for the PID is undef)
    #  - Set value to true before re-entering event loop (so worker PID is claimed).
    #  - If there are no free workers then setup a condvar and recv on it
    #  - Every job which finishes should reset it's freeness state (before the event loop),
    #    then if there is a jobs waiting convar, grab it, clear it, send on it..
    #    (like that, so that if the next thread that runs hits max workers (again),
    #     it will set a _new_ condvar)
    my $pid;
    do {
        $pid = $self->_first_free_worker;
        if (!$pid) {
            warn("Hit max number of concurrent workers, num workers: " . $self->num_workers . " num running " . scalar(keys %{$self->_workers}));
            $self->_hit_max(AnyEvent->condvar);
            $self->_hit_max->recv;
        }
    } while (!$pid);
    my $from_r = $self->_read_handles->{$pid};
    my $to_w = $self->_write_handles->{$pid};
    $self->_workers->{$pid} = $job;
#    warn Data::Dumper::Dumper($job);
    $to_w->syswrite("\x00" . $job . "\xff");
}


__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::JobRunner::Forked - Class providing persistent perl job worker processes.

=head1 DESCRIPTION

Maintains a pool of L<CatalystX::JobServer::JobRunner::Forked::Worker> processes, which are sent
jobs and which return results.

=cut
