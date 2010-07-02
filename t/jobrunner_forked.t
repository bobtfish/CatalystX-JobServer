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
$jobs->_do_run_job(TestJob->new, sub { $cb_val = shift; });
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
isa_ok $cb_val->job, 'TestJob';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

$cb_val = '';

$jobs->_do_run_job(TestJob->new, sub { $cb_val = shift; });
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
isa_ok $cb_val->job, 'TestJob';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

done_testing;
