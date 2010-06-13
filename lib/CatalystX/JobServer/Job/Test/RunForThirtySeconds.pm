package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use CatalystX::JobServer::Moose;
use AnyEvent;
use MooseX::Types::Moose qw/ Num /;

with 'CatalystX::JobServer::Role::Storage';

has retval => (
    isa => Num,
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

sub run {
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(after => 30, cb => sub { $cv->send });
    $cv->recv;
    return 303;
}

__PACKAGE__->meta->make_immutable;
1;
