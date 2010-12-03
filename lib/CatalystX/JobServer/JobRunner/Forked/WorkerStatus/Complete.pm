package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ Bool /;

method is_complete { 1 }

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

has ok => (
    is => 'ro',
    isa => Bool,
    required => 1,
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
