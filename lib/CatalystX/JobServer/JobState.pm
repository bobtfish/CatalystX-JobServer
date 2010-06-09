package CatalystX::JobServer::JobState;
use Moose;
use MooseX::Types::Moose qw/ Int ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use Moose::Autobox;
use MooseX::Types::Set::Object;
use aliased 'CatalystX::JobServer::Job::Running';
use aliased 'CatalystX::JobServer::Job::Finished';

use namespace::autoclean;

with 'CatalystX::JobServer::Role::Storage';

has num_forked_workers => (
    is => 'ro',
    isa => Int,
    default => 0,
    traits    => ['Counter', 'Serialize'],
    handles => {
        _add_forked_worker    => 'inc',
        _delete_forked_worker => 'dec',
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

before _add_running => sub { shift->_add_forked_worker(shift) };
after _remove_running => sub { shift->_delete_forked_worker(shift) };

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

sub run_job {
    my ($self, $job, $return_cb) = @_;
    $job = Running->new(job => $job);
    $self->_add_running($job);
    # What happens about many many requets..
    fork_call {
        $job->job->run;
    }
    sub {
        $self->_remove_running($job);
        if (scalar @_) {
            warn("Job ran, returned " . @_);
            $return_cb->(Finished->new(job => $job));
        }
        else {
            warn("Job failed, returned " . $@);
            $return_cb->(Finished->new(job => $job, ok => 0));
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;

