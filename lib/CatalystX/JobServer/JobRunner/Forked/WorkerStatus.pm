package CatalystX::JobServer::JobRunner::Forked::WorkerStatus;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Undef HashRef Str /;

with 'CatalystX::JobServer::Role::Storage';

has status_info => (
    isa => HashRef | Str | Undef,
    is => 'ro',
);

1;
