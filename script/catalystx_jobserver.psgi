#!/usr/bin/env perl

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('CatalystX::JobServer::Web', 'Server');

1;

=head1 NAME

catalystx_jobserver_.psgi - Catalyst Test Server

=head1 SYNOPSIS

catalystx_jobserver_.psgi [options]

   -d --debug           force debug mode
   -? --help            display this help and exits
   -h --host            host (defaults to all)
   -p --port            port (defaults to 3000)

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run this application.

=head1 AUTHORS

Tomas Doran

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

