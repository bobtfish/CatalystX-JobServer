use strict;
use warnings;
use Test::More;

{
    package A::Role;
    use MooseX::Role::WithOverloading;
    no Moose::Role;
}
{
    package A::Class;
    use Moose;

    has foo => ( is => 'rw', init_arg => undef );
    has bar => ( is => 'rw', default => 0);
    has baz => ( is => 'rw', default => 0, init_arg => undef );
    has quux => ( is => 'rw', default => sub { 0 }, init_arg => undef );
    has moo => ( is => 'rw', builder => '_build_moo', init_arg => undef );
    sub _build_moo { 0 }
    has goo => ( is => 'rw', default => 0, init_arg => undef, lazy => 1 );
    has boo => ( is => 'rw', builder => '_build_boo', init_arg => undef, lazy => 1 );
    sub _build_boo { 0 }
}

use Moose::Util;

my $i = A::Class->new();
$i->$_(42) for qw/foo bar baz quux moo goo boo/;

Moose::Util::apply_all_roles($i, 'A::Role');

foreach (qw/foo bar goo boo/) {
    is $i->$_, 42;
}

TODO: {
    local $TODO = 'Moose bug';
    foreach (qw/baz quux moo/) {
        is $i->$_, 42;
    }
}

done_testing;
