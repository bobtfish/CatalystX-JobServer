package CatalystX::JobServer::Web::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
);

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
