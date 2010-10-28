package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/base') PathPart('forkedjobrunner') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(component => $c->model('ForkedJobRunner'));
}

#sub index : Chained('base') PathPart('') Args(0) {}

sub add_worker : Chained('base') PathPart('add_worker') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{component}->add_worker;
    $c->res->redirect($c->uri_for_action('/model/inspect', ['forkedjobrunner']));
}

sub add_worker_POST {}

sub remove_worker : Chained('base') PathPart('remove_worker') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{component}->remove_worker;
    $c->res->redirect($c->uri_for_action('/model/inspect', ['forkedjobrunner']));
}

sub remove_worker_POST {}

__PACKAGE__->meta->make_immutable;
1;
