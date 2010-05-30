package CatalystX::JobServer::Web::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

CatalystX::JobServer::Web::Controller::Root - Root Controller for CatalystX::JobServer::Web

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->res->body($c->model('ComponentMap')->freeze(1));
}

sub list : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my %components;
    foreach my $component_name (keys %{$c->components}) {
        my $component = $c->components->{$component_name};
        warn("Working for $component_name $component fr " . $component->can('freeze') . ' cl ' . $component->can('clone'));
        if ($component->can('freeze') && $component->can('clone')) {
            # Check Catalyst::Component::InstancePerContext
            $components{$component_name} = $component->clone->freeze;
        }
    }

    $c->response->body(
        join("\n", map { '<h1>' . $_ . '</h1>', $components{$_} } keys %components)
    );
}

=head2 default

Standard 404 error page

=cut

sub default : Chained('base') Args {
    my ( $self, $c ) = @_;
    $c->detach('error404');
}

sub error404 : Action {
    my ($self, $c) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : Action {
    my ($self, $c) = @_;
    if ($c->stash->{data}) {
        if (blessed $c->stash->{data}) {
            $c->res->body($c->stash->{data}->freeze(1));
        }
    }
    $c->res->body('No output :(') unless $c->res->body;
}

=head1 AUTHOR

Tomas Doran

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
