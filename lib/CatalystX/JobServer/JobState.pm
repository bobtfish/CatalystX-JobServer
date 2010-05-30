package CatalystX::JobServer::JobState;
use Moose;
use MooseX::Types::Moose qw/ Int ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use Moose::Autobox;
use namespace::autoclean;

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

has jobs_registered => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
    traits => ['Serialize'],
);

sub BUILD {
    my $self = shift;
    foreach my $job (@{ $self->jobs_registered }) {
        Class::MOP::load_class($job);
    }
}

sub run_job {
    my ($self, $job) = @_;
    $self->_add_forked_worker;

    fork_call {
        $job->run;
    }
    sub {
        $self->delete_forked_worker;
        if (scalar @_) {
            warn("Job ran, returned " . shift);
        }
        else {
            warn("Job failed, returned " . $@);
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;

