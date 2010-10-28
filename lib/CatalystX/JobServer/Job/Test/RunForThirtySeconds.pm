package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use CatalystX::JobServer::Moose;
use AnyEvent;
use Data::UUID;
use MooseX::Types::Moose qw/ Num Str /;

with 'CatalystX::JobServer::Role::Storage';

has val => (
    isa => Num,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

my $d = Data::UUID->new;
has uuid => (
    isa => Str,
    is => 'ro',
    traits => ['Serialize'],
    default => sub {
        $d->to_string($d->create);
    },
);

method run {
    sleep 30 + int($self->val);
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
