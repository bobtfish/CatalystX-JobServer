use strict;
use warnings;
use Test::More;
use Test::Exception;

use Moose::Util qw/apply_all_roles/;

{
    package BaseClass;
    use Moose;

    BEGIN { extends qw/Catalyst::Component MooseX::MethodAttributes::Inheritable/; }

    use MooseX::MethodAttributes;
    no Moose;
}

{
    package AClass;
    use Moose;
    extends 'BaseClass';
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
    extends 'AClass';
    ::lives_ok { with qw/Role1 Role2/ };
}

#use CatalystX::JobServer::Web::Controller::Root;
#my $i = CatalystX::JobServer::Web::Controller::Root->new;
foreach my $i (AClass->new, BClass->new) {
    $Role1::called = $Role2::called = 0;
    lives_ok { apply_all_roles($i, qw/Role1 Role2/) };
    can_ok $i, 'pack' and $i->pack;
    is $Role1::called, 1;
    is $Role2::called, 1;
}

done_testing;
