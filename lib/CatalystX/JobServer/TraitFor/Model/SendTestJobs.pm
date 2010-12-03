package CatalystX::JobServer::TraitFor::Model::SendTestJobs;
use CatalystX::JobServer::Moose::Role;
use Coro;
use Try::Tiny qw/ try catch /;
use AnyEvent;

with 'CatalystX::JobServer::Role::MessageQueue::Publisher';

method BUILD {}

after BUILD => sub {
    my ($self, $args) = @_;
    async {
        $::RUNNING->recv if $::RUNNING; # Wait till everything is started.
        try {
            require CatalystX::JobServer::Job::Test::RunForThirtySeconds;
            for (1..10) {
                my $job = CatalystX::JobServer::Job::Test::RunForThirtySeconds->new(val => rand(8));
                warn("Job queued, will be: http://localhost:5000/model/forkedjobrunner/by_uuid/" . $job->uuid . "\n");
                $self->publish_message($job->freeze, 'job.demo.enqueue', $job->exchange_name);
                cede;
            }
        }
        catch {
            $::TERMINATE ? $::TERMINATE->croak($_) : die($_);
        };
    };
};

1;
