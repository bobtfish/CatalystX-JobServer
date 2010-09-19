package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use JSON::XS;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/base') PathPart('ForkedJobRunner') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') Args(0) {}


__PACKAGE__->meta->make_immutable;
1;
