package CatalystX::JobServer::Web::ControllerBase::ForkedJobRunner;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

has model_name => (
    is => 'ro',
    required => 1,
);

sub base : Chained('/model/base') PathPart('forkedjobrunner') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(component => $c->model($self->model_name));
}

#sub index : Chained('base') PathPart('') Args(0) {}

sub add_worker : Chained('base') PathPart('add_worker') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{component}->add_worker;
    $c->res->redirect($c->uri_for_action('/model/inspect', [$c->stash->{component_name}]));
}

sub add_worker_POST {}

sub remove_worker : Chained('base') PathPart('remove_worker') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{component}->remove_worker;
    $c->res->redirect($c->uri_for_action('/model/inspect', [$c->stash->{component_name}]));
}

sub remove_worker_POST {}

sub by_name : Chained('base') PathPart('by_name') CaptureArgs(0) {}

has jobs_by_name => (
    isa => HashRef,
    lazy => 1,
    traits => ['Hash'],
    handles => {
        jobs => 'keys',
        find_job_meta => 'get',
    },
    default => sub { return {
       map { $_ => $_ } shift->_application->model('ForkedJobRunner')->jobs_registered->flatten
    };},
);

sub by_name_list : Chained('by_name') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(JSON::XS->new->pretty(1)->encode({
        map { $_ => $c->uri_for_action('/model/forkedjobrunner/display_job', [$_])->as_string } $self->jobs_by_name
    }));
}

sub display : Chained('by_name') PathPart('') Args(0) {
    my ($self, $c) = @_;
}

sub by_uuid : Chained('base') PathPart('by_uuid') CaptureArgs(0) {}

sub by_uuid_list : Chained('by_uuid') PathPart('') Args(0) {
    my ($self, $c) = @_;
    if ($c->req->parameters->{uuid}) {
        $c->res->redirect($c->uri_for($self->action_for('find_by_uuid'), [ $c->req->parameters->{uuid} ]));
    }
    $c->stash(
        uuids => [ map { $_->working_on->{uuid} } grep { $_->working_on } $c->stash->{component}->workers->flatten ],
        template => 'forkedjobrunner/by_uuid_list.tt',
    );
}

sub find_by_uuid : Chained('by_uuid') PathPart('') CaptureArgs(1) {
    my ($self, $c, $job_uuid) = @_;
    my $job_model = $c->stash->{component};
    my (@jobs, @job_uuids);
    foreach my $uuid (split /,/, $job_uuid) {
        next unless exists $job_model->jobs_by_uuid->{$uuid};
        push(@jobs, $job_model->jobs_by_uuid->{$uuid});
        push(@job_uuids, $uuid);
    }
    $c->detach('/error404')
        unless scalar @jobs;

    my $path = $c->uri_for($self->action_for('display_by_uuid'), $c->req->captures)->path;
    $path =~ s{/$}{};
    $c->stash(
        jobs => \@jobs,
        job_uuids => \@job_uuids,
        job_model => $job_model,
        hippie_path => $path,
    );
}

sub display_by_uuid : Chained('find_by_uuid') PathPart('') Args(0) {}

with 'CatalystX::JobServer::Web::Role::Hippie';

__PACKAGE__->config(
    action => {
        hippie => {
            Chained => [ 'find_by_uuid' ],
        }
    },
);

sub hippie_init {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    foreach my $uuid (@{$c->stash->{job_uuids} }) {
        $c->stash->{job_model}->register_listener($uuid, $h);
    }
}

sub hippie_error {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    my $job = $c->stash->{job};
    foreach my $uuid (@{$c->stash->{job_uuids} }) {
        $c->stash->{job_model}->remove_listener($uuid, $h);
    }
}


__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut
