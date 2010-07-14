package CatalystX::JobServer::Web::Model::ComponentMap;
use CatalystX::JobServer::Moose;
use aliased 'CatalystX::JobServer::ComponentMap';
use namespace::autoclean;

extends 'Catalyst::Model';
with qw/Catalyst::Component::InstancePerContext/;

sub build_per_context_instance {
    my ($self, $ctx) = @_;
    my %components = %{ $ctx->components };
    delete $components{$_}
        for grep { ! /CatalystX::JobServer::Web::Model::/ } keys %components;
    ComponentMap->new(
        components => \%components,
         uri_for_model => sub { $ctx->uri_for_action('/model/inspect', [ shift ] )->as_string },
         routing_key_for_model => sub { $ctx->instance_routing_key . ':model:inspect:' . shift },
         instance_queue_name => $ctx->instance_queue_name,
         instance_uri_path => $ctx->instance_uri_path
    );
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::ComponentMap - Adaptor model class for CatalystX::JobServer::ComponentMap

=cut
