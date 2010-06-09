package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use Moose;
use MooseX::Types::Moose qw/ Num /;
use namespace::autoclean;

with 'CatalystX::JobServer::Role::Storage';

has retval => (
    isa => Num,
    is => 'ro',
    required => 1,
);

sub run {
    sleep 30;
    return 303;
}

__PACKAGE__->meta->make_immutable;
1;
