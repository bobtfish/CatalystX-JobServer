package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner::Job;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/forkedjobrunner/base') PathPart('job') CaptureArgs(0) {}





__PACKAGE__->meta->make_immutable;
1;