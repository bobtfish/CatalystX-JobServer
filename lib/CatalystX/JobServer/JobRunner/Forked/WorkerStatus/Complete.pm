package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete;
use CatalystX::JobServer::Moose;

method is_complete { 1 }

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

__PACKAGE__->meta->make_immutable;
1;
