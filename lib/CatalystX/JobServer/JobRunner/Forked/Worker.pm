package CatalystX::JobServer::JobRunner::Forked::Worker;
use CatalystX::JobServer::Moose;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
#use MooseX::Types::Moose qw/ ArrayRef /;
use JSON;
use Try::Tiny;
use IO::Handle;
use IO::Select;
use POSIX qw( EAGAIN );
use Scalar::Util qw/ blessed /;
use CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete;

method run {
    $0 = 'perl jobserver_worker [idle]';
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

method json_object ($data) {
    $0 = 'perl jobserver_worker [starting job]';
    my ($instance, $ret);
    my $running_class;
    my $class = try {
        use Data::Dumper;
        warn Dumper($data);
        $running_class = to_LoadableClass($data->{__CLASS__})
            or die("Coud not load class " . $data->{__CLASS__});
        $instance = $running_class->unpack($data);
    }
    catch {
        warn "CAUGHT EXCEPTION INFLATING: $_ dieing..";
        exit 1;
    };
    $0 = "perl jobserver_worker [running $running_class]";
    try {
        my $cb = sub { local $@; eval { print "\x00" . shift->freeze . "\xff" } };
        $ret = $instance->run($cb);
    }
    catch {
        warn "CAUGHT EXCEPTION RUNNING: $_ dieing..";
        exit 1;
    };
    try {
        my $complete = $ret if ($ret && blessed($ret) && $ret->can('is_complete') && $ret->is_complete);
        $complete = CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete->new;
#        warn("IN WORKER DONE");
        print "\x00" . $complete->freeze . "\xff";
    }
    catch {
        warn "CAUGHT EXCEPTION FREEZING RESPONSE: $_ dieing..";
        exit 1;
    };
    $0 = 'perl jobserver_worker [idle]';
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
