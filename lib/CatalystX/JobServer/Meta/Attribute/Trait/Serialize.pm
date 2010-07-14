package CatalystX::JobServer::Meta::Attribute::Trait::Serialize;
use Moose::Role;

sub Moose::Meta::Attribute::Custom::Trait::Serialize::register_implementation { __PACKAGE__ }

no Moose::Role;
1;

=head1 NAME

CatalystX::JobServer::Meta::Attribute::Trait::Serialize - Make serialization have to be explicit.

=head1 SYNOPSIS

    package CatalystX::JobServer::Some::Class;
    use Moose;
    use namespace::autoclean;

    with 'CatalystX::JobServer::Role::Storage';

    has foo => ( is => 'ro', traits => ['Serialize'] );

=head1 DESCRIPTION

Works in conjunction with L<CatalystX::JobServer::Role::Storage> to provide
something very like L<MooseX::Storage>, but requiring attributes for serialisation
to be white-listed, rather than those which are not to be serialized being black
listed.

=cut
