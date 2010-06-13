package CatalystX::JobServer::JobRunner;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Int ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use MooseX::Types::Set::Object;
use aliased 'CatalystX::JobServer::Job::Running';
use aliased 'CatalystX::JobServer::Job::Finished';
use namespace::autoclean;

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

before _add_running => sub { shift->_add_running_job_count };
after _remove_running => sub { shift->_dec_running_job_count };

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

sub BUILD {
    my $self = shift;
    foreach my $job (@{ $self->jobs_registered }) { # Horrible
        Class::MOP::load_class($job);
    }
}

with 'CatalystX::JobServer::Role::QueueListener';

sub act_on_message {
    my ($self, $message, $publisher) = @_;
    $self->run_job($message, $publisher);
}

sub job_finished {
    my ($self, $job, $output, $return_cb) = @_;
    $self->_remove_running($job);
    $return_cb->(Finished->new(job => $job));
}

sub job_failed {
    my ($self, $job, $error, $return_cb) = @_;
    $return_cb->(Finished->new(job => $job, ok => 0));
}

sub run_job {
    my ($self, $job, $return_cb) = @_;
    $job = Running->new(job => $job);
    $self->_add_running($job);
    $self->_do_run_job($job, $return_cb);
}

requires '_do_run_job';

1;
