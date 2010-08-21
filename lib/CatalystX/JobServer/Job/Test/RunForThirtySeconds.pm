package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use CatalystX::JobServer::Moose;
use AnyEvent;
use MooseX::Types::Moose qw/ Int /;

with 'CatalystX::JobServer::Role::Storage';

has val => (
    isa => Int,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

method run {
    sleep 30;
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
