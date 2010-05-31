use strict;
use warnings;
use Test::More;
use Test::Exception;

use Moose::Util qw/apply_all_roles/;

{
    package BaseClass;
    use Moose;
    use MooseX::MethodAttributes;
    no Moose;
}

{
    package AClass;
    use Moose;
    BEGIN { extends 'BaseClass' }
    sub foo : Bar {}

    no Moose;
}

{
    package Role1;
    use Moose::Role;
    our $called = 0;
    sub pack { $called++ }
    no Moose::Role;
}

{
    package Role2;
    use Moose::Role;

    our $called = 0;
    around pack => sub {
        my ($orig, $self, @rest) = @_;
        $called++;
        $self->$orig(@rest);
    };
    no Moose::Role;
}

{
    package BClass;
    use Moose;
    BEGIN { extends 'AClass' };

    sub moo : Quux {}

    ::lives_ok { with qw/Role1 Role2/ };
}

{
    package CClass;
    use Moose;
    BEGIN { extends 'AClass' };

    sub moo : Quux {}
}

#use CatalystX::JobServer::Web::Controller::Root;
#my $i = CatalystX::JobServer::Web::Controller::Root->new;
my $c = CClass->new;
lives_ok { apply_all_roles($c, qw/Role1 Role2/) };

foreach my $i (BClass->new, $c) {
    $Role1::called = $Role2::called = 0;
    can_ok $i, 'pack' and $i->pack;
    is $Role1::called, 1;
    is $Role2::called, 1;
    is_deeply(
        $i->meta->find_method_by_name('foo')->attributes,
        [(q{Bar})],
    );
    is_deeply(
        $i->meta->find_method_by_name('moo')->attributes,
        [(q{Quux})],
    );
}

done_testing;
