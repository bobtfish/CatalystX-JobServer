use strict;
use warnings;
use Test::More;
use Test::Exception;
use AnyEvent;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

use CatalystX::JobServer::JobRunner::Forked;
use TestJob;

{
    package TestJobRunner;
    use Moose;

    extends 'CatalystX::JobServer::JobRunner::Forked';

    with 'TestMethodCalledWithin' => {
        method => 'job_finished',
    };

    __PACKAGE__->meta->make_immutable;
}
my $jobs = TestJobRunner->new();

ok $jobs;

my $workerstate = $jobs->workers->[0];
ok $workerstate;
my $pid = $workerstate->pid;

ok kill(0, $pid), 'Child PID started';

is $jobs->jobs_running_count, 0;
$jobs->run_job('{"__CLASS__": "TestJob"}');
is $jobs->jobs_running_count, 1;
$jobs->test_job_finished_called;
is $jobs->jobs_running_count, 0;

__END__
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
is $cb_val->job, '{"__CLASS__": "TestJob"}';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

$cb_val = '';

$jobs->run_job('{"__CLASS__": "TestJob"}', sub { $cv->send; $cb_val = shift; });
$cv->recv;
isa_ok $cb_val, 'CatalystX::JobServer::Job::Finished';
is $cb_val->job, '{"__CLASS__": "TestJob"}';
ok $cb_val->ok;
ok $cb_val->finish_time;
ok $cb_val->start_time;

done_testing;
