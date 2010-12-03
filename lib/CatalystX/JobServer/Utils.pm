package CatalystX::JobServer::Utils;
use strict;
use warnings;
use Exporter 'import';
use Sys::Hostname ();

use Exporter 'import';

our @EXPORT_OK = qw/
    hostname
/;

my $hostname = Sys::Hostname::hostname();
$hostname =~ s/\..*//;

sub hostname () { $hostname }

1;
