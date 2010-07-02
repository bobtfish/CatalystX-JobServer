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

method run {
    my $cv = AnyEvent->condvar;
    my $timer = AnyEvent->timer(after => 3, cb => sub { $cv->send });
    $cv->recv;
    return $self;
}

__PACKAGE__->meta->make_immutable;
1;
