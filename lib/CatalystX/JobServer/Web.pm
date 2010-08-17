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

sub get_config_path {
    my $c = shift;
    my ($path, $extension) = $c->next::method(@_);
    $path =~ s{Web/}{};         # Strip Web/ out of the path, config gets
    return ($path, $extension); # put in the directory above..
}

=head1 NAME

CatalystX::JobServer::Web - Catalyst application part of CatalystX::JobServer

=head1 SYNOPSIS

    script/catalystx_jobserver.psgi

=head1 DESCRIPTION

The top level of the web application. Loads L<Catalyst> and L<Catalyst::Engine::PSGI>.

Loads the config from the config file, and uses L<CatalystX::JobServer::Web::Plugin::ModelsFromConfig>
to load all the application components and L<CatalystX::JobServer::Web::Plugin::AddRolesToComponents>
to massage them.

=head1 SEE ALSO

L<CatalystX::JobServer>.

=head1 AUTHOR

Tomas Doran

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
