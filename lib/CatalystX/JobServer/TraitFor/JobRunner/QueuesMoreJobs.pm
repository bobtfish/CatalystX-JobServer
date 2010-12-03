package CatalystX::JobServer::TraitFor::JobRunner::QueuesMoreJobs;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use JSON qw/ encode_json /;
use CatalystX::JobServer::Utils qw/ hostname /;

with qw/
    CatalystX::JobServer::Role::MessageQueue::Publisher
/;


before update_status => sub {
    my ($self, $job, $data) = @_;
    return unless $data->{__CLASS__} eq 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::RunJob';
    warn("GOT A QUEUED JOB");
    my $new_job = $data->{job};
    Class::MOP::load_class($new_job->{__CLASS__});
    my $instance = $new_job->{__CLASS__}->unpack($new_job);
    $self->publish_message(encode_json($new_job), sprintf("job.%s.enqueue", hostname()), $instance->exchange_name);
    warn("Enqueued job " . encode_json($new_job) . " to " . $instance->exchange_name);
};

1;
