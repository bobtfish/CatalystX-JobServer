use strict;
use warnings;
use Test::More;
use AnyEvent;

use CatalystX::JobServer::JobRunner::Forked;

my $jobs = CatalystX::JobServer::JobRunner::Forked->new(
);

ok $jobs;

my $cb_val;
my $cv = AnyEvent->condvar;
$jobs->_do_run_job('TEXT', sub { $cv->send; $cb_val = shift; warn $cb_val; });
$cv->recv;
is $cb_val, 'RET VALUE';

done_testing;
