package CatalystX::JobServer::Web::Role::Hippie;
use MooseX::MethodAttributes::Role;
use Web::Hippie;
use MooseX::Types::Moose qw/ HashRef CodeRef /;
use namespace::autoclean;

has _hippie => (
    isa => 'Web::Hippie',
    is => 'ro',
    default => sub { Web::Hippie->new },
);

has handlers => (
    isa => HashRef[CodeRef],
    lazy => 1,
    traits => ['Hash'],
    handles => {
        get_handler => 'get',
        has_handler => 'defined'
    },
    default => sub {
        my $self = shift;
        return {
            map {
                $self->can("hippie_$_") ? ("/$_" => $self->can("hippie_$_")) : ()
            }
            qw/
                init
                error
                message
                new_listener
            /
        };
    },
);

sub hippie : Chained('find') PathPart('_hippie') Args() {
    my ($self, $c, $type, $arg) = @_;

    my $code = $self->_hippie->can("handler_$type");
    $c->detach('/error404') unless ($code); # FIXME 400?

    my $env = $c->req->env;
    local $env->{PATH_INFO} = $env->{PATH_INFO};

    $c->res->body($code->($self->_hippie, $c->req->env, sub {
        my $env = shift;
        if ($self->has_handler($env->{PATH_INFO})) {
            $self->get_handler($env->{PATH_INFO})->($self, $c, $env);
        }
    }));
}


1;
