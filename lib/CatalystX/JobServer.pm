package CatalystX::JobServer;
use strict;
use warnings;
use EV ();
use Coro ();
use AnyEvent ();

our $VERSION = '0.000001';

1;

=head1 NAME

CatalystX::JobServer - Multi protocol asynchronous job server

=head1 SYNOPSIS

CatalystX::JobServer is an AMQP and JSON based job and event server.

You configure sets of AMQP exchanges, queues and bindings, and set these up to dispatch
recieved messages into the application. What services are run by the application
(and where replies are sent) is also configured.

Various services (such as, for example, a job worker pools, or a message writer which writes
recieved messages to disk) can be setup within your instance (again, fully from config).

Traits can be applied to these services to add additional functionality (for example serializing
the service state and sending it to a queue regularly).

The application also listens on a port for HTTP requests, and allows you to browse the application
state, or (using L<Web::Hippie>) get a persistent pipe which regularly updates you with the state.

=head1 QUICK START

    Install RabbitMQ on your machine.

    Start RabbitMQ with the default user/password.

    Install the dependencies listed in Makefile.PL (note that Plack and Web::Hippie need to
    come from my github forks right now).

    Run CATALYST_DEBUG=1 ./script/catalystx_jobserver.psgi

    Point your browser at http://localhost:5000

    Look at catalystx_jobserver_web.yml and start playing.

=head1 DESCRIPTION

=head1 TODO

B<Documentation> - Please yell at me with questions and suggest places where the documentation
isn't clear, I know this needs work ;)

B<Fireing jobs from the web> - One of the main applications I want to do with this is to
be able to set off a job with an AMQP message from one web hit, then get the status as the
job is running using Hippie. This is currently not implemented (but will be soon).

=head1 SEE ALSO

L<CatalystX::JobServer::Web>, L<Net::RabbitFoot>, L<http://www.slideshare.net/bobtfish/real-time-systemperformancemon>.

=head1 AUTHOR

Tomas Doran

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
