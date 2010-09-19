package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner::Job::ByUUID;
use CatalystX::JobServer::Moose;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/forkedjobrunner/job/base') PathPart('by_uuid') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $jobname) = @_;
    $c->model('ForkedJobRunner')->jobs_registered->flatten;
}

sub display : Chained('find') PathPart('') Args(0) {
    my ($self, $c) = @_;
}


__PACKAGE__->meta->make_immutable;
1;
