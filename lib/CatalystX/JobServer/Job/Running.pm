package CatalystX::JobServer::Job::Running;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef CodeRef /;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use DateTime;
use JSON;
use namespace::autoclean;

with 'CatalystX::JobServer::Role::Storage';

override BUILDARGS => sub {
    my $args = super();
    $args->{job} = from_json($args->{job}) unless ref($args->{job});
    return $args;
};

has start_time => (
    isa => ISO8601DateTimeStr,
    is => 'ro',
    coerce => 1,
    # FIXME - But with just time()
    default => sub { DateTime->now },
    traits => ['Serialize'],
);

has job => (
    isa => HashRef,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
