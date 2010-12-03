package CatalystX::JobServer::TraitFor::JobRunner::StatusUpdatesToExchange;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use JSON qw/ encode_json /;
use namespace::autoclean;

with qw/
    CatalystX::JobServer::Role::MessageQueue::Publisher
/;

has statusupdates_exchange_name => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    default => sub { shift->exchange_name }, # Same as the default one we declared.
    lazy => 1,
);

method make_routing_key { '#' }

before update_status => sub {
    my ($self, $job, $data) = @_;
    use Data::Dumper;
    warn("PUBLISH " . Dumper($data));
    $self->publish_message(encode_json($data), $self->make_routing_key($job), $self->statusupdates_exchange_name);
};

1;
