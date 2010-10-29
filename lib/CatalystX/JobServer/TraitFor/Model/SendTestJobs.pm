package CatalystX::JobServer::TraitFor::Model::SendTestJobs;
use CatalystX::JobServer::Moose::Role;
use Coro;
use Try::Tiny qw/ try catch /;
use AnyEvent;

with 'CatalystX::JobServer::Role::MessageQueue::Publisher';

method BUILD {}

after BUILD => sub {
    my ($self, $args) = @_;
    warn("WIBBLE");
    async {
        $::RUNNING->recv if $::RUNNING; # Wait till everything is started.
        try {
            warn("QUACK");
            require CatalystX::JobServer::Job::Test::RunForThirtySeconds;
            for (1..10) {
                my $job = CatalystX::JobServer::Job::Test::RunForThirtySeconds->new(val => rand(8));
                warn("http://localhost:5000/model/forkedjobrunner/job/byuuid/" . $job->uuid . "\n");
                $self->publish_message($job->freeze);
                cede;
            }
        }
        catch {
            $::TERMINATE ? $::TERMINATE->croak($_) : die($_);
        };
    };
};

1;
