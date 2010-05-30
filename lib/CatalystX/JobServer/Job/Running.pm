package CatalystX::JobServer::Job::Running;
use Moose;
use MooseX::Types::Moose qw/ Object /;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use DateTime;
use MooseX::Storage;
use namespace::autoclean;

with Storage(engine => 'JSON');

has start_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
);

has job => (
    isa => Object,
    is => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;
1;
