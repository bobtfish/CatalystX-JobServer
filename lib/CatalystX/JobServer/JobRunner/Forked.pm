package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ ArrayRef HashRef Int Bool /;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use aliased 'CatalystX::JobServer::Job::Running';
use namespace::autoclean;

has started_at => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 5,
    default => sub { DateTime->now },
    init_arg => undef,
    traits => ['Serialize'],
);

has num_workers => (
    isa => Int,
    is => 'ro',
    default => 1,
    traits => ['Serialize', 'Counter'],
    handles => {
        add_worker => 'inc',
        remove_worker => 'dec',
    },
);

method _build_jobs_running_count {
    scalar(grep { ! $_->free } $self->workers->flatten);
}

has worker_state_class => (
    isa => LoadableClass,
    is => 'ro',
    coerce => 1,
    default => 'CatalystX::JobServer::JobRunner::Forked::WorkerState',
    handles => {
        _new_worker => 'new',
    }
);

has worker_config => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

has workers => (
    isa => ArrayRef,
    is => 'ro',
    writer => '_set_workers',
    lazy => 1,
    default => sub {
        my $self = shift;
        # FIXME weaken self into closure
        return [
            map {
                $self->_new_worker(
                    %{ $self->worker_config },
                    job_finished_cb => sub {
                        $self->job_finished(shift, shift);
                        $self->_try_to_run_queued_jobs;
                    },
                    update_status_cb => sub {
                        my ($job, $data) = @_;
                        $data = $data->pack if blessed($data);
                        $self->update_status($job, $data);
                    },
                )
            }
            1..$self->num_workers
        ];
    },
    traits => ['Serialize'],
);

has waiting => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
    traits => ['Array'],
    handles => {
        _has_jobs_waiting => 'count',
        _push_waiting_job => 'push',
        _get_waiting_job => 'shift',
    },
);

method BUILD {
    $self->workers;
}

after add_worker => sub {
    my $self = shift;
    my $worker = $self->_new_worker;
    push(@{ $self->workers }, $worker);
    $self->_try_to_run_queued_jobs;
};

method can_remove_worker {
    !! $self->_first_free_worker;
}

around remove_worker => sub {
    my ($orig, $self) = @_;
    my @free = grep { $_->free } @{ $self->workers };
    return unless @free;
    $self->$orig;
    my @busy = grep { !$_->free } @{ $self->workers };
    my $dead = pop @free;
    $self->_set_workers([@busy, @free]);
    $dead->kill_worker;
    return $dead;
};

method _first_free_worker {
    (grep { $_->free } @{ $self->workers })[0];
}

sub _do_run_job {
    my ($self, $job) = @_;
    $self->_push_waiting_job($job);
    $self->_try_to_run_queued_jobs;
}

method _try_to_run_queued_jobs {
    while ($self->_has_jobs_waiting) {
        my $worker = $self->_first_free_worker;
        unless ($worker) {
            $self->cancel_messagequeue_consumer;
            last;
        }
        my $job = $self->_get_waiting_job;
        my $running_job = Running->new(job => $job);
        $self->_add_running($running_job);
        $worker->run_job($job);
    }
    $self->build_messagequeue_consumer if (!$self->_has_jobs_waiting && $self->_first_free_worker);
}

has suspend => (
    is => 'rw',
    isa => Bool,
    default => 0,
    trigger => sub {
        my ($self, $val, $old) = @_;
        $self->cancel_messagequeue_consumer if $val;
    },
    traits => ['Serialize'],
);

with 'CatalystX::JobServer::JobRunner';

after _remove_running => sub {
    shift->_try_to_run_queued_jobs;
};

around build_messagequeue_consumer => sub {
    my ($orig, $self, @args) = @_;
    return if $self->suspend;
    $self->$orig(@args);
};

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::JobRunner::Forked - Class providing persistent perl job worker processes.

=head1 DESCRIPTION

Maintains a pool of L<CatalystX::JobServer::JobRunner::Forked::Worker> processes, which are sent
jobs and which return results.

=cut
