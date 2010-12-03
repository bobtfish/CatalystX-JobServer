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
    traits    => ['Serialize'],
    clearer => '_clear_jobs_running_count',
    lazy => 1,
    builder => '_build_jobs_running_count',
);

method _build_jobs_running_count { 0 }

before 'pack' => sub {
    shift->_clear_jobs_running_count;
};

sub _add_running {
    my ($self, $job) = @_;
    $self->_clear_jobs_running_count;
}
sub _remove_running {
    my ($self, $job) = @_;
    $self->_clear_jobs_running_count;
}

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

method consume_message ($message) {
    $self->run_job($message->{body}->payload);
}

method job_finished ($job, $output){
    my $finished = Finished->new(job => $job, ok => $output->ok);
    $finished->finalize();
    $self->_remove_running($finished);
}

method run_job ($job) {
#    warn("do_run_job " . Dumper ($running_job));
    $self->_do_run_job($job);
}

method update_status ($job, $data) { }

requires '_do_run_job';

with qw/
    CatalystX::JobServer::Role::MessageQueue::BindsAQueue
    CatalystX::JobServer::Role::MessageQueue::Consumer
/;

1;

=head1 NAME

CatalystX::JobServer::JobRunner - Role providing some of the implementation for a job worker.

=head1 SYNOPSIS

See L<CatalystX::JobServer::JobRunner::Forked>.

=cut

