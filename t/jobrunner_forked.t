use strict;
use warnings;
use Test::More;
use AnyEvent;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use CatalystX::JobServer::JobRunner::Forked;
use TestJob;

my $jobs = CatalystX::JobServer::JobRunner::Forked->new(
);

ok $jobs;

my $pid = (keys %{ $jobs->_workers })[0];

ok kill(0, $pid), 'Child PID started';

my $cb_val;
$jobs->_do_run_job(TestJob->new->freeze, sub { $cb_val = shift; });
is $cb_val, sprintf(q{{"__CLASS__":"TestJobReturn","pid":%s}}, $pid);

$cb_val = '';

$jobs->_do_run_job(TestJob->new->freeze, sub { $cb_val = shift; });
is $cb_val, sprintf(q{{"__CLASS__":"TestJobReturn","pid":%s}}, $pid);

done_testing;
