package CatalystX::JobServer::Web::Model::JobState;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CatalystX::JobServer::JobState' );

__PACKAGE__->meta->make_immutable;
1;

