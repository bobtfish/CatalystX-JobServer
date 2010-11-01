package CatalystX::JobServer::Web::Controller::Root;
use CatalystX::JobServer::Moose;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

=head1 NAME

CatalystX::JobServer::Web::Controller::Root - Root Controller for CatalystX::JobServer::Web

=head1 DESCRIPTION

Provides web app wide actions such as the base chain, the index page, the default 404 handler etc.

=head1 METHODS

=head2 index

The root page (/)

=cut

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    #$c->res->header('Content-Type', 'application/json');
    my $cm = $c->model('ComponentMap');
    $c->stash(
        data => $cm,
        component_map_astext => $cm->freeze(1),
    );
}

=head2 default

Standard 404 error page

=cut

sub default : Chained('base') PathPart('') Args {
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

sub end : ActionClass('Serialize') {
    my ($self, $c) = @_;
    $c->stash(json_encoder => $self->action_for('end')->_encoders->{'JSON'}->encoder);
    if (blessed($c->stash->{data})) {
        $c->stash(data => $c->stash->{data}->pack);
    }
}

__PACKAGE__->config(
    default => 'text/html',
    stash_key => 'data',
    map => {
        'text/html' => [ 'View', 'HTML' ],
        'application/json' => [ 'JSON' ],
    },
);

=head1 AUTHOR

Tomas Doran

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
