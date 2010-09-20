package CatalystX::JobServer::JobRunner;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Int HashRef ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use MooseX::Types::Set::Object;
use aliased 'CatalystX::JobServer::Job::Running';
use aliased 'CatalystX::JobServer::Job::Finished';
use Scalar::Util qw/ refaddr /;
use namespace::autoclean;
use Data::Dumper;

with 'CatalystX::JobServer::Role::Storage';

has jobs_running_count => (
    is => 'ro',
    isa => Int,
    default => 0,
    traits    => ['Counter', 'Serialize'],
    handles => {
        _inc_running_job_count    => 'inc',
        _dec_running_job_count => 'dec',
    }
);

has jobs_running => (
    isa      => "Set::Object",
    default => sub { Set::Object->new },
    coerce => 1,
    handles  => {
        jobs_running => "members",
        _add_running => "insert",
        _remove_running => "remove",
    },
    traits => ['Serialize'],
);

before _add_running => sub {
    my ($self, $job) = @_;
    $self->_inc_running_job_count;
    if (exists $job->job->{uuid}) {
        $self->_add_job_by_uuid($job->job->{uuid}, $job);
    }
};
after _remove_running => sub {
    my ($self, $job) = @_;
    $self->_dec_running_job_count;
    if (exists $job->job->{uuid}) {
        $self->_remove_job_by_uuid($job->job->{uuid}, $job);
    }
};

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

has jobs_by_uuid => (
    is => 'ro',
    traits    => ['Hash', 'Serialize'],
    isa => HashRef[Running],
    default => sub { {} },
    handles   => {
        _add_job_by_uuid => 'set',
        _remove_job_by_uuid => 'delete',
    },
);

has _jobs_by_uuid_handles => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

before _remove_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    delete $self->_jobs_by_uuid_handles->{$uuid};
};

before _add_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    $self->_jobs_by_uuid_handles->{$uuid} = {};
};

before _remove_running => sub {
    my ($self, $job) = @_;
    if (exists $job->job->{uuid}) {
        warn("Sending messages to handles for " . $job->job->{uuid});
        foreach my $h (values %{$self->_jobs_by_uuid_handles->{$job->job->{uuid}}}) {
            $h->send_msg($job->pack);
        }
    }
};

sub register_listener {
    my ($self, $uuid, $h) = @_;
    return unless exists $self->jobs_by_uuid->{$uuid};
    warn("Added listener");
    $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)} = $h;
}

sub remove_listener {
    my ($self, $uuid, $h) = @_;
    warn("Removed listener");
    delete $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)};
}

#with 'CatalystX::JobServer::Role::QueueConsumer::LogMessageStructured';
sub consume_message {
    my ($self, $message, $publisher) = @_;
    $self->act_on_message($message->{body}->payload, $publisher);
}

sub act_on_message {
    my ($self, $message, $publisher) = @_;
    $self->run_job($message, $publisher);
}

sub job_finished {
    my ($self, $job, $output) = @_;
    my $finished = Finished->new(job => $job);
    $finished->finalize();
    $self->_remove_running($finished);
}

sub job_failed {
    my ($self, $job, $error) = @_;
    my $finished = Finished->new(job => $job, ok => 0);
    $finished->finalize;
    $self->_remove_running($finished);
}

sub run_job {
    my ($self, $job, $return_cb) = @_;
    Carp::confess("No return_cb") unless $return_cb;
    my $running_job = Running->new(job => $job, return_cb => $return_cb);
    $self->_add_running($running_job);
#    warn("do_run_job " . Dumper ($running_job));
    $self->_do_run_job($job);
}

requires '_do_run_job';

1;

=head1 NAME

CatalystX::JobServer::JobRunner - Role providing some of the implementation for a job worker.

=head1 SYNOPSIS

See L<CatalystX::JobServer::JobRunner::Forked>.

=cut

