package CatalystX::JobServer::Web::Controller::Model;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Web::Hippie;
use AnyEvent;

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
            /;
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

sub hippie_init {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    my $w; $w = AnyEvent->timer(
        interval => 1,
        cb => sub {
            $h->send_msg(
                $c->model('ForkedJobRunner')->pack
            );
            $w;
        }
    );
}

#sub hippie_error {}
#sub hippie_message {}
#sub hippie_new_listener {}

sub observe : Chained('find') Args(0) {
    my ($self, $c) = @_;

    my $uri = $c->uri_for($self->action_for('inspect'), $c->req->captures)->path;
    $c->res->body(q[
    <html>
    <head>
    <title>Hippie demo</title>
    <script src="/static/jquery-1.3.2.min.js"></script>
    <script src="/static/jquery.ev.js"></script>
    <script src="/static/DUI.js"></script>
    <script src="/static/Stream.js"></script>
    <script src="/static/hippie.js"></script>
    <script src="/static/json2.js"></script>
    <script src="/static/dump.js"></script>

    <script>

    function log_it(stuff) {
      $("#log").append(stuff+'<br/>');
    }
    $(function() {
      var hippie = new Hippie( document.location.host + "] . $uri . q[", 5, function() {
                                   log_it("connected");
                                 },
                                 function() {
                                   log_it("disconnected");
                                 },
                                 function(e) {
                                   log_it("got message: " + dump(e));
                                 } );
    });


    </script>
    <link rel="stylesheet" href="/static/screen.css" />
    </head>
    <body>

    <div id="content">

    <div id="log">

    </div>

    </div>
    </body>
    </html>

    ]);

}

__PACKAGE__->meta->make_immutable;
1;
