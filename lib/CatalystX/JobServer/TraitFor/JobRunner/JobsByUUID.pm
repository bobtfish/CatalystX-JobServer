package CatalystX::JobServer::TraitFor::JobRunner::JobsByUUID;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ HashRef /;
use aliased 'CatalystX::JobServer::Job::Running';
use Scalar::Util qw/ refaddr /;
use namespace::autoclean;

has jobs_by_uuid => (
    is => 'ro',
    traits    => ['Hash', 'Serialize'],
    isa => HashRef,
    lazy => 1,
    builder => '_build_jobs_by_uuid',
    handles   => {
        _add_job_by_uuid => 'set',
        _remove_job_by_uuid => 'delete',
    },
    clearer => '_clear_jobs_by_uuid',
);

before pack => sub {
    shift->_clear_jobs_by_uuid;
};
method _build_jobs_by_uuid {
    return {
        map { $_->working_on->{uuid}, $_->working_on }
        grep { $_->working_on->{uuid} }
        grep { $_->working_on }
        $self->workers->flatten
    };
}

has _jobs_by_uuid_handles => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

after _add_running => sub {
    my ($self, $job) = @_;
    if (exists $job->job->{uuid}) {
        $self->_add_job_by_uuid($job->{uuid}, $job);
    }
};

after _remove_running => sub {
    my ($self, $job) = @_;
    if (exists $job->job->{uuid}) {
        $self->_remove_job_by_uuid($job->{uuid}, $job);
    }
};

after _remove_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    delete $self->_jobs_by_uuid_handles->{$uuid};
};

after _add_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    $self->_jobs_by_uuid_handles->{$uuid} = {};
};

before _remove_running => sub {
    my ($self, $job) = @_;
    if (exists $job->job->{uuid}) {
        my $data = $job->pack;
        $self->notify_listeners($job->job->{uuid}, $data);
    }
};

before update_status => sub {
    my ($self, $job, $data) = @_;
    $self->notify_listeners($job->{uuid}, $data)
        if $job->{uuid};
};

method notify_listeners ($uuid, $data) {
    return unless exists $self->_jobs_by_uuid_handles->{$uuid};
    $data->{uuid} = $uuid;
    foreach my $h (values %{$self->_jobs_by_uuid_handles->{$uuid}}) {
        $h->send_msg($data);
    }
}

sub register_listener {
    my ($self, $uuid, $h) = @_;
    return unless exists $self->jobs_by_uuid->{$uuid};
    warn("Added listener for $uuid");
    $h->send_msg($self->jobs_by_uuid->{$uuid}->pack);
    $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)} = $h;
}

sub remove_listener {
    my ($self, $uuid, $h) = @_;
    warn("Removed listener for $uuid");
    delete $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)};
}

1;

