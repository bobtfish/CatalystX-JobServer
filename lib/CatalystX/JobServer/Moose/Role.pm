package CatalystX::JobServer::Moose::Role;
use strict;
use warnings;

use CatalystX::JobServer::Moose ();

sub import {
    my $class = shift;
    my $into = caller;
    CatalystX::JobServer::Moose::do_import($into, 'Moose::Role');
}

1;
