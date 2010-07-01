use strict;
use warnings;
use Test::More;
use AnyEvent;

use CatalystX::JobServer::JobRunner::Forked;

my $jobs = CatalystX::JobServer::JobRunner::Forked->new(
);

ok $jobs;

my $cb_val;
$jobs->_do_run_job('TEXT', sub { $cb_val = shift; });
is $cb_val, 'RET VALUE';

$cb_val = '';

$jobs->_do_run_job('TEXT', sub { $cb_val = shift; });
is $cb_val, 'RET VALUE';

done_testing;
