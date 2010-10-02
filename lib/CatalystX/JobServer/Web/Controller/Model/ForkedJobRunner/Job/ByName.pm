package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner::Job::ByName;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/forkedjobrunner/job/base') PathPart('by_name') CaptureArgs(0) {}

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

sub list : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(JSON::XS->new->pretty(1)->encode({
        map { $_ => $c->uri_for_action('/model/forkedjobrunner/display_job', [$_])->as_string } $self->jobs_by_name
    }));
}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $jobname) = @_;
    $c->model('ForkedJobRunner')->jobs_registered->flatten;
}

sub display : Chained('find') PathPart('') Args(0) {
    my ($self, $c) = @_;
}


__PACKAGE__->meta->make_immutable;
1;