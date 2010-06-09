package CatalystX::JobServer::Moose;
use strict;
use warnings;

use Moose ();
use Moose::Autobox;
use Method::Signatures::Simple ();
use Moose::Util::TypeConstraints ();
use Moose::Autobox ();

sub import {
    my $class = shift;
    my $into = caller;
    do_import($into, 'Moose');
}

sub do_import {
    my $into = shift;
    my @also = @_;

    ( $import, $unimport, $init_meta ) = Moose::Exporter->build_import_methods(
        into => $into,
        also => [ @also, 'Moose::Util::TypeConstraints' ],
    );

    Method::Signatures::Simple->import( into => $into );
    Moose::Autobox->import( into => $into );
    $class->$import({into => $into});
    namespace::autoclean->import(-cleanee => $into);
}

1;
