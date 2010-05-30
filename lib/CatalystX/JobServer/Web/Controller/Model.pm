package CatalystX::JobServer::Web::Controller::Model;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

sub base : Chained('/base') PathPart('model') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $name) = @_;
    my $component = $c->components->{'CatalystX::JobServer::Web::Model::' . $name}
        or $c->detach('/error404');
    $c->stash(component => $component);
}

sub inspect : Chained('find') PathPath('') Args(0) {
    my ($self, $c) = @_;
    my $component = $c->stash->{component};
    if ($component->can('pack') && $component->can('clone')) {
        $c->stash(data => $component->clone);
    }
}

__PACKAGE__->meta->make_immutable;
