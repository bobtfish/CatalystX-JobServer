package CatalystX::JobServer::Web;
use Moose;
use Coro;
use AnyEvent;
use MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    +CatalystX::JobServer::Web::Plugin::ModelsFromConfig
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    name => 'CatalystX::JobServer::Web',
    disable_component_resolution_regex_fallback => 1,
    'CatalystX::DynamicComponent::ModelsFromConfig' => {
        include => '^(MessageQueue|JobState)$',
    },
    'Model::MessageQueue' => {
        class => 'CatalystX::JobServer::MessageQueue',
    },
);

__PACKAGE__->setup();
__PACKAGE__->setup_engine('PSGI');
=head1 NAME

CatalystX::JobServer::Web - Catalyst based application

=head1 SYNOPSIS

    script/catalystx_jobserver_web_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<CatalystX::JobServer::Web::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Tomas Doran

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
