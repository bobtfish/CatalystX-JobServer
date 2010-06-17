#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use aliased 'CatalystX::JobServer::Web';
use Plack::Runner;
use Coro;
use AnyEvent;
use Plack::App::URLMap;
use Plack::App::File;
use Plack::App::Cascade;
use Try::Tiny;

# Can $::TERMINATE->throw to exit :)
our $TERMINATE = AnyEvent->condvar;
our $RUNNING = AnyEvent->condvar;

my $map = Plack::App::URLMap->new;

$map->map('/static' => Plack::App::Cascade->new(
    apps => [
        eval { require Web::Hippie::App::JSFiles } ? Web::Hippie::App::JSFiles->new->to_app : (),
        Plack::App::File->new(
            root => CatalystX::JobServer::Web->path_to(qw/root static/)
        )->to_app,
    ]
));

$map->map('/' => sub { CatalystX::JobServer::Web->run(@_) });

my $app = sub { CatalystX::JobServer::Web->run(@_) };
my $runner = Plack::Runner->new(server => 'Corona', env => 'deployment');
$runner->parse_options(@ARGV);
async {
    $runner->run($app);
};

$RUNNING->send;
$TERMINATE->recv;

1;
