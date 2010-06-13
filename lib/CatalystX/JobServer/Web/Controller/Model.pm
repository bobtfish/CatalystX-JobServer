package CatalystX::JobServer::Web::Controller::Model;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Web::Hippie;

BEGIN { extends 'Catalyst::Controller' };

sub base : Chained('/base') PathPart('model') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $name) = @_;
    my $component = is_NonEmptySimpleStr($name)
        && $c->model($name)
        or $c->detach('/error404');
    $c->stash(component => $component);
}

sub inspect : Chained('find') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $component = $c->stash->{component} or confess("Cannot find ->stash->{component}");
    if ($component->can('pack') && $component->can('clone')) {
        $c->stash(data => $component->clone);
    }
    else {
        $c->detach('/error404');
    }
}

has _hippie => (
    isa => 'Web::Hippie',
    is => 'ro',
    default => sub { Web::Hippie->new },
);

sub hippie : Chained('find') PathPart('_hippie') Args() {
    my ($self, $c, $type, $arg) = @_;

    my $code = $self->_hippie->can("handler_$type");
    $c->detach('/error404') unless ($code); # FIXME 400?

    my $env = $c->req->env;
    local $env->{PATH_INFO} = $env->{PATH_INFO};
    $c->res->body($code->($self->_hippie, $c->req->env, sub {
        my $new_env = shift;
    if ($new_env->{PATH_INFO} eq '/init') {
        my $h = $new_env->{'hippie.handle'};
        my $w; $w = AnyEvent->timer( interval => 1,
                                         cb => sub {
                                             $h->send_msg(
                                                 $c->model('ForkedJobRunner')->pack
                                             );
                                             $w;
                                         });
    }
    }));
}

__PACKAGE__->meta->make_immutable;
1;
