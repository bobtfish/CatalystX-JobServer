package CatalystX::JobServer::JobState;
use Moose;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

has running => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

__PACKAGE__->meta->make_immutable;
1;

