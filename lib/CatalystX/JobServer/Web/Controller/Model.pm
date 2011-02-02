package CatalystX::JobServer::Web::Controller::Model;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef CodeRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use AnyEvent;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };
with 'CatalystX::JobServer::Web::Role::Hippie';

sub base : Chained('/base') PathPart('model') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $name) = @_;
    my $component = is_NonEmptySimpleStr($name)
        && $c->model($name)
        or $c->detach('/error404');
    $c->stash(
        component => $component,
        component_name => $name,
    );
}

sub inspect : Chained('find') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $component = $c->stash->{component} or confess("Cannot find ->stash->{component}");
    if ($component->can('pack')) {
        my $data = $component->pack;
        $data->{__CLASS__} = $component->_original_class_name
            if $component->can('_original_class_name');;
        $c->stash(data => $data);
    }
    else {
        $c->detach('/error404');
    }
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

    my $path = $c->uri_for($self->action_for('inspect'), $c->req->captures)->path;
    $path =~ s{/$}{};

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
      var hippie = new Hippie( document.location.host, 5, function() {
                                   log_it("connected");
                                 },
                                 function() {
                                   log_it("disconnected");
                                 },
                                 function(e) {
                                   log_it("got message: " + dump(e));
                                 },
                                 "] . $path . q[" );
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

=head1 NAME

CatalystX::JobServer::Web::Controller::Model - Provides introspection of the models registered in the application via HTTP.

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut
