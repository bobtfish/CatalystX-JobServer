package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::StatusLine;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ Str /;

method is_complete { 0 }

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

has status_info => (
    isa => Str,
    is => 'ro',
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
