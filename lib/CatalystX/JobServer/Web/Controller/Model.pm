package CatalystX::JobServer::Web::Controller::Model;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;

BEGIN { extends 'Catalyst::Controller' };

sub base : Chained('/base') PathPart('model') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $name) = @_;
    my $component = is_NonEmptySimpleStr($name)
        && $c->model($name)
        or $c->detach('/error404');
    $c->stash(component => $component);
}

sub inspect : Chained('find') PathPath('') Args(0) {
    my ($self, $c) = @_;
    my $component = $c->stash->{component} or confess("Cannot find ->stash->{component}");
    if ($component->can('pack') && $component->can('clone')) {
        $c->stash(data => $component->clone);
    }
    else {
        $c->detach('/error404');
    }
}

__PACKAGE__->meta->make_immutable;
1;
