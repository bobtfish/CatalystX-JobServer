package CatalystX::JobServer::JobRunner::Forked::Worker;
use CatalystX::JobServer::Moose;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
#use MooseX::Types::Moose qw/ ArrayRef /;
use JSON;
use Try::Tiny;
use IO::Handle;
use IO::Select;
use POSIX qw( EAGAIN );

$SIG{INT} = \&Carp::cluck;

method run {
    STDOUT->autoflush(1);
    my $buf;
    my $io = IO::Handle->new;
    unless ($io->fdopen(fileno(STDIN), "r")) {
       confess "Could not open a handle on STDIN";
    }
    $io->blocking(0);
    my $s = IO::Select->new();
    $s->add($io);
    while (1) {
        my ($ready) = $s->can_read(10);
        next unless $ready;
        my ($this, $bytes);
        while ($bytes = $ready->sysread($this, 4096)) {
            $buf .= $this;
            $this = '';
            while ($self->get_json_from_buffer(
                   \$buf, sub { $self->json_object(shift) })
               ) { 1; } # Call as many times as we have JSON
        }
        confess("Got EOF from parent: $!") if (!defined $bytes && $! != EAGAIN);
        sleep 1; # FIXME - Cheesy hack!
    }
}

method json_object ($json) {
    my ($instance, $ret);
    my $class = try {
        my $data = from_json($json);
        my $running_class = to_LoadableClass($data->{__CLASS__})
            or die("Coud not load class " . $data->{__CLASS__});
        $instance = $running_class->unpack($data);
    }
    catch {
        warn "CAUGHT EXCEPTION INFLATING: $_ dieing..";
        exit 1;
    };
    try {
        $ret = $instance->run;
    }
    catch {
        warn "CAUGHT EXCEPTION RUNNING: $_ dieing..";
        exit 1;
    };
    try {
#        warn("IN WORKER DONE");
        print "\x00" . $ret->freeze . "\xff";
    }
    catch {
        warn "CAUGHT EXCEPTION FREEZING RESPONSE: $_ dieing..";
        exit 1;
    };
}

with 'CatalystX::JobServer::Role::BufferWithJSON';

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::JobRunner::Forked::Worker - Class providing a worker which listens on STDIN and replies on STDOUT.

=head1 DESCRIPTION

When run enters an infinte loop. Will wait on STDIN for a JSON message, unserialize it,
load the class as defined by the top level C<__CLASS__> element (ala L<MooseX::Storage>), call
C<< $class->unpack($data) >>, followed by C<< $class->run >>.

Expects this to return an object which can be serialized by calling C<< $return->freeze >>

=cut
