package CatalystX::JobServer::Web;
use CatalystX::JobServer::Moose;
use Coro;
use AnyEvent;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Sys::Hostname qw/ hostname /;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    +CatalystX::JobServer::Web::Plugin::ModelsFromConfig
    +CatalystX::JobServer::Web::Plugin::AddRolesToComponents
    ConfigLoader
    Static::Simple
/;

extends 'Catalyst';

has instance_queue_name => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    lazy => 1,
    default => sub { 'cxjobserver_' . hostname() . '_' . $$ },
);

has instance_uri_path => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    # FIXME
    lazy => 1,
    default => sub { 'localhost:5000' }
);

has instance_routing_key => (
    isa => Str,
    is => 'ro',
    lazy => 1,
    default => '',
);

__PACKAGE__->config(
    name => 'CatalystX::JobServer::Web',
    disable_component_resolution_regex_fallback => 1,
    'Model::MessageQueue' => {
        class => 'CatalystX::JobServer::MessageQueue',
        args => {
            channels => {
            },
        },
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
