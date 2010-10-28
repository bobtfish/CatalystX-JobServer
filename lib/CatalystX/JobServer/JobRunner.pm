package CatalystX::JobServer::JobRunner;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Int HashRef ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
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

sub _add_running {
    my ($self, $job) = @_;
    $self->_inc_running_job_count;
}
sub _remove_running {
    my ($self, $job) = @_;
    $self->_dec_running_job_count;
}

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

#with 'CatalystX::JobServer::Role::QueueConsumer::LogMessageStructured';
sub consume_message {
    my ($self, $message) = @_;
    $self->run_job($message->{body}->payload);
}

sub job_finished {
    my ($self, $job, $output) = @_;
    my $finished = Finished->new(job => $job);
    $finished->finalize();
    warn("Remove running");
    $self->_remove_running($finished);
}

sub job_failed {
    my ($self, $job, $error) = @_;
    my $finished = Finished->new(job => $job, ok => 0);
    $finished->finalize;
    $self->_remove_running($finished);
}

sub run_job {
    my ($self, $job) = @_;
    my $running_job = Running->new(job => $job);
#    warn("do_run_job " . Dumper ($running_job));
    $self->_do_run_job($job);
    $self->_add_running($running_job);
}

requires '_do_run_job';

1;

=head1 NAME

CatalystX::JobServer::JobRunner - Role providing some of the implementation for a job worker.

=head1 SYNOPSIS

See L<CatalystX::JobServer::JobRunner::Forked>.

=cut

