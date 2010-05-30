package CatalystX::JobServer::Web;
use Moose;
use Coro;
use AnyEvent;
use MooseX::Types::Moose qw/ Str /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Sys::Hostname qw/ hostname /;
use namespace::autoclean;

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

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    name => 'CatalystX::JobServer::Web',
    disable_component_resolution_regex_fallback => 1,
    'Model::MessageQueue' => {
        class => 'CatalystX::JobServer::MessageQueue',
        args => {
            channels => {
                jobs => {
                    exchanges => [
                        {
                            type => 'topic',
                            durable => 1,
                            exchange => 'jobs'
                        }
                    ],
                    queues => [
                        {
                            queue => 'jobs_queue',
                            durable => 1,
                            bind => {
                                exchange => 'jobs',
                                routing_key => '#',
                            }
                        },
                    ],
                    dispatch_to => 'JobState',
                    results_exchange => 'firehose',
                    results_routing_key => '',
                }
            }
        }
    },
    'Model::JobState' => {
        class => 'CatalystX::JobServer::JobState',
        args => {
            jobs_registered => [
                'CatalystX::JobServer::Job::Test::RunForThirtySeconds',
            ],
        },
    }
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
