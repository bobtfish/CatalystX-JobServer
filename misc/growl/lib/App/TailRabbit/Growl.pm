package App::TailRabbit::Growl;
use Moose;
use Mac::Growl ':all';

extends 'App::TailRabbit';

has sticky => (
    isa => Bool,
    default => 0,
);

my @names = ("App::TailRabbit::Growl");
my $as_app = 'GrowlHelperApp.app';

before run => sub {
    RegisterNotifications($app, \@names, [$names[0]], $as_app);
};

sub notify {
    my ($self, $title, $text) = @_;
    PostNotification($app, $names[0], $title, $text, $self->sticky, 1);
}

__PACKAGE__->meta->make_immutable;
1;

