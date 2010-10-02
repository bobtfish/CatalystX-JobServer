package CatalystX::JobServer::JobRunner::Forked::WorkerState;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use MooseX::Types::Moose qw/ HashRef Int /;
use AnyEvent;
use AnyEvent::Handle;
use Coro;
use namespace::autoclean;
use CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Job::Running;
use DateTime;

foreach (qw/ ae write read /) {
    has "_${_}_handle" => (
        is => 'rw',
        clearer => "_clear_${_}_handle"
    );
}

foreach (qw/ pid working_on worker_started_at respawn /) {
    has $_ => (
        is => 'rw',
        clearer => "_clear_${_}",
    );
}

sub free { ! shift->working_on }

has respawn_every => (
    is => 'ro',
    predicate => '_has_respawn_every',
    isa => Int,
);

has _respawn_every_timer => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        AnyEvent−>timer(
            after => $self->respawn_every,
            interval => $self->respawn_every,
            cb => sub {
                $self->respawn(1);
                # Do not kill worker when it's running a job already, respawn = 1
                # will recycle it when the job is finished
                $self->spawn_new_worker unless $self->working_on;
            },
        );
    },
);

sub BUILD {
    my $self = shift;
    $self->_spawn_worker;
    $self->_respawn_every_timer
        if $self->_has_respawn_every;
}

sub DEMOLISH {
    my $self = shift;
    # Quit all our workers
    kill 15, $self->pid;
}

sub run_job {
    my ($self, $job) = @_;

    $self->_spawn_worker_if_needed;

    $self->working_on($job);
#    warn Data::Dumper::Dumper($job);
    $self->_write_handle->syswrite("\x00" . $job . "\xff");
}

sub spawn_new_worker {
    my $self = shift;
    $self->__on_error($self->_ae_handle, undef, 'parent caused restart');
}

sub __on_error {
    my ($self, $hdl, $fatal, $msg) = @_;
    my $pid = $self->pid;
    warn "got error from child $pid, destroying handle: $msg\n";

    kill(15, $pid) if (kill 0, $pid);
    $hdl->destroy;
    $self->_clear_write_handle;
    $self->_clear_read_handle;
    $self->_clear_pid;
    $self->_clear_ae_handle;
    $self->_clear_working_on;
    $self->_clear_worker_started_at
    $self->_clear_respawn;

    async {
        my $cv = AnyEvent->condvar;
        my $w = AnyEvent->timer( after => 1, cb => sub {
            if (kill 0, $pid) {
                warn "Child $pid did not gracefully close, killing hard!";
                kill 9, $pid;
            }
            $self->_spawn_worker_if_needed; # And try spawning a new one..
            $cv->send;
        });
        $cv->recv;
    };
}

sub __on_read {
    my ($self, $hdl) = @_;
    my $buf = $hdl->{rbuf};
    $hdl->{rbuf} = '';
#               warn("PARENT HANDLE DID READ");
    while ( $self->get_json_from_buffer(\$buf, sub {
        my $running = $self->working_on;
#                   warn("GOT FINISHED JOB " . Data::Dumper::Dumper($running));
        $self->job_finished($running, shift);
        $self->spawn_new_worker if $self->respawn;
    }) { 1 }
}

sub _spawn_worker_if_needed {
    my ($self) = @_;
    return if $self->_write_handle;
    my ($to_r, $to_w) = portable_pipe;
    my ($from_r, $from_w) = portable_pipe;
    my $pid = fork;
    if ($pid != 0) {
        # parent
        close( $to_r );
        close( $from_w );
        $self->pid($pid);
        $self->_write_handle($to_w);
        $self->_read_handle($from_r);
        $self->_ae_handle(
            AnyEvent::Handle->new(
                fh => $from_r,
                on_error => sub { __on_error($self, @_) },
                on_read => sub { __on_read($self, @_) },
            )
        );
        $self->worker_started_at(DateTime->now);
        return $pid;
    }
    elsif ($pid == 0) {
        # child
        close( $to_w );
        close( $from_r );
        close( STDOUT );

        open( STDOUT, '>&', fileno($from_w) )
                    or croak("Can't reset stdout: $!");
        open( STDIN, '<&', fileno( $to_r ) )
                    or croak("Can't reset stdin: $!");
        $| = 1;
        my @cmd = $^X;
        foreach my $lib (@INC) {
            push(@cmd, '-I', $lib);
        }
        push (@cmd, '-MCatalystX::JobServer::JobRunner::Forked::Worker');
        push(@cmd, '-e', 'CatalystX::JobServer::JobRunner::Forked::Worker->new->run');
        exec( @cmd );
    }
}

with 'CatalystX::JobServer::Role::BufferWithJSON';

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::JobRunner::Forked::WorkerState - Class providing persistent perl job worker processes.

=head1 DESCRIPTION

Maintains a pool of L<CatalystX::JobServer::JobRunner::Forked::Worker> processes, which are sent
jobs and which return results.

=cut
