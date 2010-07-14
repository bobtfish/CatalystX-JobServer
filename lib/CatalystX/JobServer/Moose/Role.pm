package CatalystX::JobServer::Moose::Role;
use strict;
use warnings;

use CatalystX::JobServer::Moose ();

sub import {
    my $class = shift;
    my $into = caller;
    CatalystX::JobServer::Moose::do_import(__PACKAGE__, $into, 'Moose::Role');
}

1;

=head1 NAME

CatalystX::JobServer::Moose::Role - Moose::Role, the way I like it.

=head1 SYNOPSIS

    package CatalystX::JobServer::SomeClass;
    use CatalystX::JobServer::Moose::Role;

=head1 DESCRIPTION

Applies L<Moose::Role>, L<Moose::Util::TypeConstraints>, L<Method::Signatures::Simple>, L<Moose::Autobox>
and L<namespace::autoclean> to the class using it.

=cut
