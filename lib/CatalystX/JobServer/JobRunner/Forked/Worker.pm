package CatalystX::JobServer::JobRunner::Forked::Worker;
use CatalystX::JobServer::Moose;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use MooseX::Types::Moose qw/ Int /;
use JSON;
use Try::Tiny;
use IO::Handle;
use IO::Select;
use POSIX qw( EAGAIN );
use Scalar::Util qw/ blessed /;
use CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete;

my $argc_top = 0;
foreach my $type (qw/ before after /) {
    my $argc = $argc_top++;
    has "eval_${type}_job" => (
        is => 'ro',
        default => sub {
            my $codestring = $ARGV[$argc];
            my $closure = defined($codestring) ? eval "sub { Try::Tiny::try {" . $codestring . "}; };" : sub {};
            die("Could not compile $codestring - failed with excpetion $@")
                unless $closure;
            return $closure;
        },
    );
}

has ppid => (
    isa => Int,
    is => 'ro',
    required => 1,
);

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
        exit 0 if (!kill 0, $self->ppid);
    }
}

method json_object ($data) {
    $0 = 'perl jobserver_worker [starting job]';
    my ($instance, $ret);
    my $running_class;
    my $class = try {
        $data->{interactive} = 0;
        $running_class = to_LoadableClass($data->{__CLASS__})
            or die("Coud not load class " . $data->{__CLASS__});
        $instance = $running_class->unpack($data);
    }
    catch {
        warn "CAUGHT EXCEPTION INFLATING: $_ dieing..";
        exit 1;
    };
    $0 = "perl jobserver_worker [running $running_class]";
    $self->eval_before_job->();
    try {
        my $cb = sub { my $to_send = shift; try { print "\x00" . $to_send->freeze . "\xff" } catch { warn "Caught exception freezing status message: $_"} };
        $ret = $instance->run($cb);
    }
    catch {
        warn "CAUGHT EXCEPTION RUNNING: $_ dieing..";
        exit 1;
    };
    my $ok = ! ! $ret;
    try {
        my %p = ( ok => $ok );
        $p{uuid} = $instance->uuid if (try { $instance->uuid });
        my $complete = CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete->new( %p );
#        warn("IN WORKER DONE");
        print "\x00" . $complete->freeze . "\xff";
    }
    catch {
        warn "CAUGHT EXCEPTION FREEZING RESPONSE: $_ dieing..";
        exit 1;
    };
    $self->eval_after_job->();
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
