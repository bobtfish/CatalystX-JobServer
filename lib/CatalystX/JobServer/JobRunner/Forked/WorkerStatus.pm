package CatalystX::JobServer::JobRunner::Forked::WorkerStatus;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::Storage';

has uuid => (
    is => 'ro',
    traits => ['Serialize'],
);

method is_complete { 0 }

1;
