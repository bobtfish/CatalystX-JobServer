package CatalystX::JobServer::JobState;
use Moose;
use MooseX::Types::Moose qw/ Int ArrayRef Str /;
use AnyEvent::Util qw/ fork_call /;
use Moose::Autobox;
use MooseX::Types::Set::Object;
use MooseX::Storage::Engine;
use namespace::autoclean;

MooseX::Storage::Engine->add_custom_type_handler(
    'Set::Object' =>
        expand => sub {},
        collapse => sub {
            my @members = $_[0]->members;
            MooseX::Storage::Engine->find_type_handler( ArrayRef )->{collapse}->( \@members );
        },
);

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
    $self->_add_running($job);
    fork_call {
        $job->run;
    }
    sub {
        $self->_remove_running($job);
        $self->_delete_forked_worker;
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

