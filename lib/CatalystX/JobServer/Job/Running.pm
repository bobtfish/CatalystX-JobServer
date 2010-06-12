package CatalystX::JobServer::Job::Running;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ Object /;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use DateTime;
use namespace::autoclean;

with 'CatalystX::JobServer::Role::Storage';

has start_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
    traits => ['Serialize'],
);

has job => (
    isa => Object,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
