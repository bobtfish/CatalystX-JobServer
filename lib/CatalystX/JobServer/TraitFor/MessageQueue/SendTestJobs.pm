package CatalystX::JobServer::TraitFor::MessageQueue::SendTestJobs;
use CatalystX::JobServer::Moose::Role;
use Coro;
use Try::Tiny qw/ try catch /;
use AnyEvent;

method BUILD {}

after BUILD => sub {
    my ($self, $args) = @_;
    async {
        $::RUNNING->recv if $::RUNNING; # Wait till everything is started.
        try {
            $self->mq;
            $self->_channel_objects;
            require CatalystX::JobServer::Job::Test::RunForThirtySeconds;
            for (1..10) {
                my $job = CatalystX::JobServer::Job::Test::RunForThirtySeconds->new(val => rand(808));
                warn("http://localhost:5000/model/forkedjobrunner/job/byuuid/" . $job->uuid . "\n");
                $self->_channel_objects->{jobs}->publish(
                 body => $job->freeze,
                 exchange => 'jobs',
                 routing_key => '#',
             );
            }
        }
        catch {
            $::TERMINATE ? $::TERMINATE->croak($_) : die($_);
        };
    };
};

1;
