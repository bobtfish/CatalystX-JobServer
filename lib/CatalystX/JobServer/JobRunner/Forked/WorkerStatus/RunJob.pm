package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::RunJob;
use CatalystX::JobServer::Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw/ HashRef /;

my $job = subtype HashRef, where { 1 }; # FIXME Dict, it needs to have a uuid key
coerce $job, from duck_type([qw/ pack /]), via { $_->pack };

has job => (
    isa => $job,
    is => 'ro',
    required => 1,
    coerce => 1,
    traits => ['Serialize'],
);

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

__PACKAGE__->meta->make_immutable;
1;
