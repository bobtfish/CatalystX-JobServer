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

my ($cv, $cb_val) = (AnyEvent->condvar);
$jobs->run_job('{"__CLASS__": "TestJob"}', sub { $cv->send; $cb_val = shift; });
$cv->recv;
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
is $cb_val->job, '{"__CLASS__": "TestJob"}';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

$cb_val = '';
$cv = AnyEvent->condvar;

$jobs->run_job('{"__CLASS__": "TestJob"}', sub { $cv->send; $cb_val = shift; });
$cv->recv;
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
is $cb_val->job, '{"__CLASS__": "TestJob"}';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

done_testing;
