package CatalystX::JobServer::Utils;
use strict;
use warnings;
use Sys::Hostname ();

our @EXPORT_OK = qw/
    hostname
/;

my $hostname = Sys::Hostname::hostname();
$hostname =~ s/\..*//;

sub hostname () { $hostname }

1;
