package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner::Job::ByUUID;
use CatalystX::JobServer::Moose;

BEGIN { extends 'Catalyst::Controller' }
with 'CatalystX::JobServer::Web::Role::Hippie';

sub base : Chained('/model/forkedjobrunner/job/base') PathPart('byuuid') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $job_uuid) = @_;
    my $job_model = $c->model('ForkedJobRunner');
    my $job = $job_model->jobs_by_uuid->{$job_uuid}
        or $c->detach('/error404');
    $c->stash(
        job => $job,
        job_uuid => $job_uuid,
        job_model => $job_model,
    );
}

sub display : Chained('find') PathPart('') Args(0) {
    my ($self, $c) = @_;
}

sub hippie_init {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    my $job = $c->stash->{job};
    $h->send_msg($job->pack);
    $c->stash->{job_model}->register_listener($c->stash->{job_uuid}, $h);
}

sub hippie_error {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    my $job = $c->stash->{job};
    $c->stash->{job_model}->remove_listener($c->stash->{job_uuid}, $h);
}

__PACKAGE__->meta->make_immutable;
1;
