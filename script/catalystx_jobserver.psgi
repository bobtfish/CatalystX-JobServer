#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use aliased 'CatalystX::JobServer::Web';
use Plack::Runner;
use Coro;
use AnyEvent;

my $app = sub { CatalystX::JobServer::Web->run(@_) };
my $runner = Plack::Runner->new(server => 'Corona', env => 'deployment');
$runner->parse_options(@ARGV);
async {
    $runner->run($app);
};
AnyEvent->condvar->recv;
1;
