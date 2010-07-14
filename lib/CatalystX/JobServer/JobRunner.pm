package CatalystX::JobServer::JobRunner;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Int ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use MooseX::Types::Set::Object;
use aliased 'CatalystX::JobServer::Job::Running';
use aliased 'CatalystX::JobServer::Job::Finished';
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

before _add_running => sub { shift->_inc_running_job_count };
after _remove_running => sub { shift->_dec_running_job_count };

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

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
    $self->_remove_running($job);
    Finished->new(job => $job)->finalize;
}

sub job_failed {
    my ($self, $job, $error) = @_;
    Finished->new(job => $job, ok => 0)->finalize;
}

sub run_job {
    my ($self, $job, $return_cb) = @_;
    Carp::confess("No return_cb") unless $return_cb;
    my $running_job = Running->new(job => $job, return_cb => $return_cb);
    $self->_add_running($running_job);
#    warn("do_run_job " . Dumper ($running_job));
    $self->_do_run_job($running_job);
}

requires '_do_run_job';

1;

=head1 NAME

CatalystX::JobServer::JobRunner - Role providing some of the implementation for a job worker.

=head1 SYNOPSIS

See L<CatalystX::JobServer::JobRunner::Forked>.

=cut

