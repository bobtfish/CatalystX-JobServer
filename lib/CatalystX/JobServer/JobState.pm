package CatalystX::JobServer::JobState;
use Moose;
use MooseX::Types::Moose qw/ Int /;
use namespace::autoclean;

with 'CatalystX::JobServer::Role::HasCoro';

sub _async { sub {
    my $self = shift;
}}

has max_forked_workers => (
    is => 'rw',
    isa => Int,
    default => 3,
);

__PACKAGE__->meta->make_immutable;
1;

