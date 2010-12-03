package CatalystX::JobServer::JobRunner::Forked::WorkerState;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use MooseX::Types::Moose qw/ HashRef Int CodeRef Bool Str /;
use MooseX::Types::ISO8601 qw/ ISO8601DateTimeStr /;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Util qw/ close_all_fds_except /;
use namespace::autoclean;
use CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Job::Running;
use DateTime;
use JSON qw/ decode_json encode_json /;
use Coro; # For killing dead processes after timeout.
use aliased 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus::Complete';
use Try::Tiny;
use POSIX ();
use namespace::autoclean;
no warnings 'syntax'; # "Statement unlikely to be reached"

with 'CatalystX::JobServer::Role::Storage';

foreach (qw/ ae write read sigchld/) {
    has "_${_}_handle" => (
        is => 'rw',
        clearer => "_clear_${_}_handle",
        init_arg => undef,
    );
}

has pid => (
    is => 'rw',
    isa => Int,
    clearer => "_clear_pid",
    init_arg => undef,
    traits => ['Serialize'],
);

has working_on => (
    isa => HashRef,
    is => 'rw',
    clearer => "_clear_working_on",
    init_arg => undef,
    traits => ['Serialize'],
);

has worker_started_at => (
    isa => ISO8601DateTimeStr,
    coerce => 1,
    is => 'rw',
    clearer => "_clear_worker_started_at",
    init_arg => undef,
    traits => ['Serialize'],
);

has respawn => (
    isa => Bool,
    is => 'rw',
    clearer => "_clear_respawn",
    init_arg => undef,
    traits => ['Serialize'],
);

sub free { ! shift->working_on }

# FIXME - Callback role
has job_finished_cb => (
    isa => CodeRef,
    is => 'ro',
    predicate => '_has_job_finished_cb',
);

has update_status_cb => (
    isa => CodeRef,
    is => 'ro',
    predicate => '_has_update_status_cb',
);

method job_finished ($output) {
    my $working_on = $self->working_on;
    $self->_clear_working_on;
    try {
        $self->job_finished_cb->(encode_json($working_on), $output)
            if $self->_has_job_finished_cb;
    }
    catch {
        require Data::Dumper;
        warn("Caught exception finishing working: $_ working_on was " . Data::Dumper::Dumper($working_on));
    };
}

has respawn_every => (
    is => 'ro',
    predicate => '_has_respawn_every',
    isa => Int,
    traits => ['Serialize'],
);

has _respawn_every_timer => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        AnyEvent->timer(
            after => $self->respawn_every,
            interval => $self->respawn_every + int(rand($self->respawn_every/10)) - $self->respawn_every/20,
            cb => sub {
                $self->respawn(1);
                # Do not kill worker when it's running a job already, respawn = 1
                # will recycle it when the job is finished
                $self->spawn_new_worker unless $self->working_on;
            },
        );
    },
    init_arg => undef,
);

method BUILD {
    $self->_spawn_worker_if_needed;
    $self->_respawn_every_timer
        if $self->_has_respawn_every;
}

method DEMOLISH {
    # Quit all our workers
    kill 15, $self->pid
        if $self->pid;
}

method run_job ($job) {

    confess("Already working!") if $self->working_on;

    $self->_spawn_worker_if_needed;

    $self->working_on(decode_json($job));
    $self->_write_handle->syswrite("\x00" . $job . "\xff");
}

method spawn_new_worker {
    $self->__on_error($self->_ae_handle, undef, 'parent caused restart');
}

method kill_worker {
    $self->__on_error($self->_ae_handle, undef, 'parent killed ' . ($self->free ? 'was free' : 'was busy'));
}

method update_status ($data) {
    $self->update_status_cb->($self->working_on, $data) if $self->_has_update_status_cb;
}

method __on_error ($hdl, $fatal, $msg) {
    $self->_clear_respawn;

    my $pid = $self->pid;
    my $error = "got error from child $pid, destroying handle: $msg\n";
    warn $error;

    kill(15, $pid) if (kill 0, $pid);
    $hdl->destroy if $hdl;
    close($self->_write_handle) if $self->_write_handle;
    $self->_clear_write_handle;
    close($self->_read_handle) if $self->_read_handle;
    $self->_clear_read_handle;
    $self->_clear_pid;
    $self->_clear_ae_handle;
    if ($self->working_on) {
        $self->job_finished($error);
    }
    $self->_clear_working_on;
    $self->_clear_worker_started_at;
    $self->_clear_sigchld_handle;

    async {
        my $cv = AnyEvent->condvar;
        my $w = AnyEvent->timer( after => 10, cb => sub {
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

method __on_read ($hdl) {
    my $buf = $hdl->{rbuf};
    $hdl->{rbuf} = '';
    while ( $self->get_json_from_buffer(\$buf, sub {
        my $data = shift;
        unless (ref($data) eq 'HASH' && $data->{__CLASS__}) {
            warn("Found crap in the output stream: " . $data);
            return;
        }
        Class::MOP::load_class($data->{__CLASS__});
        $data = $data->{__CLASS__}->unpack($data);
        if ($data->is_complete) {
            $self->job_finished($data);
            $self->spawn_new_worker if $self->respawn;
        }
        else {
            $self->update_status($data);
        }
    })) { 1 }
}

method _spawn_worker_if_needed {
    return if $self->_write_handle;
    my ($to_r, $to_w) = portable_pipe;
    my ($from_r, $from_w) = portable_pipe;
    if (!$to_r or !$to_w or !$from_r or !$from_w) {
        Carp::confess("Ran out of filehandles trying to spawn sub process");
    }
    my $pid = fork;
    if (!defined $pid) {
        undef $to_r;
        undef $to_w;
        undef $from_r;
        undef $from_w;
        if ($! == &Errno::EAGAIN) {
            Carp::confess("CAUGHT EXCEPTION - FORK ERROR: EAGAIN");
        }
        elsif ($! == &Errno::ENOMEM) {
            Carp::confess("CAUGHT EXCEPTION - FORK ERROR: ENOMEM");
        }
        else {
            Carp::confess("CAUGHT EXCEPTION - FORK ERROR: unknown ($!)");
        }
    }
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
        $self->_sigchld_handle(AnyEvent->child(
            pid => $pid,
            cb => sub {
                $self->__on_error($self->_ae_handle, undef, 'Caught SIGCHLD');
            },
        ));
        $self->worker_started_at(DateTime->now);
        return $pid;
    }
    elsif ($pid == 0) {
        # child
        try {
            close( $to_w );
            close( $from_r );
            close( STDOUT );

            open( STDOUT, '>&', fileno($from_w) )
                    or croak("Can't reset stdout: $!");
            open( STDIN, '<&', fileno( $to_r ) )
                    or croak("Can't reset stdin: $!");
            close_all_fds_except(0, 2, 1);
            $| = 1;
            my @cmd = $^X;
            foreach my $lib (@INC) {
                push(@cmd, '-I', $lib);
            }
            push (@cmd, '-MCatalystX::JobServer::JobRunner::Forked::Worker');
            push(@cmd, '-e', 'CatalystX::JobServer::JobRunner::Forked::Worker->new->run');
            exec( @cmd );
        }
        catch {
            warn("Caught exception in sub-process running worker: $_");
            POSIX::_exit(255);
        };
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
