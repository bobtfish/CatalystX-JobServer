package CatalystX::JobServer::Web::Script::Server;
use CatalystX::JobServer::Moose;
use CatalystX::JobServer ();
use Twiggy::Server;
use Plack::App::URLMap;
use Plack::App::File;
use Plack::App::Cascade;
use Try::Tiny;
use MooseX::Types::Common::Numeric qw/PositiveInt/;
use MooseX::Types::Moose qw/ Str Bool /;
use Catalyst::Utils ();
use namespace::autoclean;

with 'Catalyst::ScriptRole';

has debug => (
    traits        => [qw(Getopt)],
    cmd_aliases   => 'd',
    isa           => Bool,
    is            => 'ro',
    documentation => q{Force debug mode},
);

has host => (
    traits        => [qw(Getopt)],
    cmd_aliases   => 'h',
    isa           => Str,
    is            => 'ro',
    # N.B. undef (the default) means we bind on all interfaces on the host.
    documentation => 'Specify a hostname or IP on this host for the server to bind to',
);

has port => (
    traits        => [qw(Getopt)],
    cmd_aliases   => 'p',
    isa           => PositiveInt,
    is            => 'ro',
    default       => sub {
        Catalyst::Utils::env_value(shift->application_name, 'port') || 5000
    },
    documentation => 'Specify a different listening port (to the default port 5000)',
);

sub _run_application {
    my $self = shift;
    my $app = $self->application_name;

    local $ENV{CATALYST_DEBUG} = 1
            if $self->debug;

    Class::MOP::load_class($app);

    # Can $::TERMINATE->throw to exit :)
    $::TERMINATE = AnyEvent->condvar;
    $::RUNNING = AnyEvent->condvar;

    my $map = Plack::App::URLMap->new;

    $map->map('/static' => Plack::App::Cascade->new(
        apps => [
            eval { require Web::Hippie::App::JSFiles; 1; } ? Web::Hippie::App::JSFiles->new->to_app : (),
            Plack::App::File->new(
                root => $app->path_to(qw/root static/)
            )->to_app,
        ]
    ));

    $map->map('/' => sub { CatalystX::JobServer::Web->run(@_) });

    my $server = Twiggy::Server->new(
        host => $self->host,
        port => $self->port,
    );
    $server->register_service($map->to_app);

    $::RUNNING->send;
    $::TERMINATE->recv;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut
