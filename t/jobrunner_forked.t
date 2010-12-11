use strict;
use warnings;
use Test::More;
use Test::Exception;
use AnyEvent;
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use JSON qw/ encode_json /;

use CatalystX::JobServer::JobRunner::Forked;
use TestJob;

$CatalystX::JobServer::Web::PID = $$;

{
    package TestJobRunner;
    use Moose;

    extends 'CatalystX::JobServer::JobRunner::Forked';

    with 'CatalystX::JobServer::TraitFor::JobRunner::JobsByUUID';
    with 'TestMethodCalledWithin' => {
        method => 'job_finished',
    };

    sub bind_queue {}
    sub _exchange {}
    sub _queue {}
    sub build_messagequeue_consumer {}

    __PACKAGE__->meta->make_immutable;
}
my $jobs = TestJobRunner->new(
    exchange_name => 'foo',
    queue_name => 'bar',
);

ok $jobs;

my $workerstate = $jobs->workers->[0];
ok $workerstate;
my $pid = $workerstate->pid;

ok kill(0, $pid), 'Child PID started';

is $jobs->jobs_running_count, 0;
$jobs->run_job(encode_json({"__CLASS__" => "TestJob", return => 1, exit => 0, uuid => "foo"}));
is $jobs->jobs_running_count, 1;
ok $jobs->jobs_by_uuid->{'foo'};
$jobs->test_job_finished_called;
is $jobs->jobs_running_count, 0;
ok !$jobs->jobs_by_uuid->{'foo'};
is scalar(keys %{ $jobs->jobs_by_uuid }), 0;

$jobs->run_job(encode_json({"__CLASS__" => "TestJob", return => 0, exit => 0, uuid => "bar"}));
is $jobs->jobs_running_count, 1;
ok $jobs->jobs_by_uuid->{'bar'};
$jobs->test_job_finished_called;
is $jobs->jobs_running_count, 0;
ok !$jobs->jobs_by_uuid->{'bar'};
is scalar(keys %{ $jobs->jobs_by_uuid }), 0;

$jobs->run_job(encode_json({"__CLASS__" => "TestJob", return => 1, exit => 1, uuid => "baz"}));
is $jobs->jobs_running_count, 1;
ok $jobs->jobs_by_uuid->{'baz'};
$jobs->test_job_finished_called;
is $jobs->jobs_running_count, 0;
ok !$jobs->jobs_by_uuid->{'baz'};
is scalar(keys %{ $jobs->jobs_by_uuid }), 0;

done_testing;

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
