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

    has job_finished_cv => (
        is => 'ro',
        lazy => 1,
        default => sub { AnyEvent->condvar },
        clearer => 'clear_job_finished_cv',
    );

    after job_finished => sub {
        my $self = shift;
        do { $self->job_finished_cv->send; $self->clear_job_finished_cv; }
            if $self->job_finished_cv;
    };

    __PACKAGE__->meta->make_immutable;
}
my $jobs = TestJobRunner->new();

ok $jobs;

my $workerstate = $jobs->workers->[0];
ok $workerstate;
my $pid = $workerstate->pid;

ok kill(0, $pid), 'Child PID started';

my $timer = AnyEvent->timer( after => 5, cb => sub { $jobs->job_finished_cv->croak("timed out"); });
is $jobs->jobs_running_count, 0;
$jobs->run_job('{"__CLASS__": "TestJob"}');
is $jobs->jobs_running_count, 1;
lives_ok { $jobs->job_finished_cv->recv };
undef $timer;
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
