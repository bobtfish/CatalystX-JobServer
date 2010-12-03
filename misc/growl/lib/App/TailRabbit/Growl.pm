package App::TailRabbit::Growl;
use Moose;
use Mac::Growl;
use MooseX::Types::Moose qw/ Bool /;
use namespace::autoclean;

extends 'App::TailRabbit';

has sticky => (
    is => 'ro',
    isa => Bool,
    default => 0,
);

my @names = ("App::TailRabbit::Growl");
my $as_app = 'GrowlHelperApp.app';

before run => sub {
    Mac::Growl::RegisterNotifications($as_app, \@names, [$names[0]], $as_app);
};

sub notify {
    my ($self, $payload, $routing_key, $message) = @_;
    Mac::Growl::PostNotification($as_app, $names[0], '', $payload, $self->sticky, 1);
}

__PACKAGE__->meta->make_immutable;
1;

