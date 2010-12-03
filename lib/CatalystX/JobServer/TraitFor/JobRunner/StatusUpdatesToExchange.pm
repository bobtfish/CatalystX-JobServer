package CatalystX::JobServer::TraitFor::JobRunner::StatusUpdatesToExchange;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use JSON qw/ encode_json /;
use CatalystX::JobServer::Utils qw/ hostname /;

with qw/
    CatalystX::JobServer::Role::MessageQueue::Publisher
/;

has statusupdates_exchange_name => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    default => sub { shift->exchange_name }, # Same as the default one we declared.
    lazy => 1,
);

foreach my $name (qw/ _add_running _remove_running /) {
    after $name => sub {
        my ($self, $job) = @_;
        my $payload = $job->pack;
        $payload->{uuid} = $payload->{job}->{uuid} if $payload->{job}->{uuid};
        $self->publish_message(encode_json($payload), sprintf("job.%s.lifecycle.%s", hostname(), $payload->{uuid}), $self->statusupdates_exchange_name);
    };
}

before update_status => sub {
    my ($self, $job, $data) = @_;
    $self->publish_message(encode_json($data), sprintf("job.%s.status.%s", hostname(), $job->{uuid}), $self->statusupdates_exchange_name);
};

1;
