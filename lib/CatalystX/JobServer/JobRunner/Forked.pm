package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use MooseX::Types::Moose qw/ HashRef Int /;
use AnyEvent::Handle;
use namespace::autoclean;
use CatalystX::JobServer::Job::Finished;
use CatalystX::JobServer::Job::Running;

with 'CatalystX::JobServer::JobRunner';

has num_workers => (
    isa => Int,
    is => 'ro',
    default => 5,
    traits => ['Serialize'],
);

has _workers => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

has _hit_max => (
    is => 'rw',
);

foreach (qw/ write read /) {
    has '_' . $_ . '_handles' => (
        isa => HashRef,
        is => 'ro',
        default => sub { {} },
    );
}

sub BUILD {
    my $self = shift;
    my $n = $self->num_workers;
    $self->_spawn_worker for (1..$n);
}

sub DEMOLISH {
    my $self = shift;
    # Quit all our workers
    kill 15, $_ for keys %{ $self->_workers };
}

sub _first_free_worker {
    my ($self) = @_;
    (grep { ! $self->_workers->{$_} } keys %{ $self->_workers })[0];
}

sub _do_run_job {
    my ($self, $job) = @_;

    # This is fairly subtle, we need to block if we have too many jobs.
    # Here is how it works:
    #  - Find a free worker (where the value for the PID is undef)
    #  - Set value to true before re-entering event loop (so worker PID is claimed).
    #  - If there are no free workers then setup a condvar and recv on it
    #  - Every job which finishes should reset it's freeness state (before the event loop),
    #    then if there is a jobs waiting convar, grab it, clear it, send on it..
    #    (like that, so that if the next thread that runs hits max workers (again),
    #     it will set a _new_ condvar)
    my $pid;
    do {
        $pid = $self->_first_free_worker;
        if (!$pid) {
            $self->_hit_max(AnyEvent->condvar);
            $self->_hit_max->recv;
        }
    } while (!$pid);
    my $from_r = $self->_read_handles->{$pid};
    my $to_w = $self->_write_handles->{$pid};
    $self->_workers->{$pid} = $job;
#    warn Data::Dumper::Dumper($job);
    $to_w->syswrite("\x00" . $job->job . "\xff");
}

sub _spawn_worker {
    my ($self) = @_;
    my ($to_r, $to_w) = portable_pipe;
    my ($from_r, $from_w) = portable_pipe;
    my $pid = fork;
    if ($pid != 0) {
        # parent
        close( $to_r );
        close( $from_w );
        $self->_workers->{$pid} = 0;
        $self->_write_handles->{$pid} = $to_w;
        $self->_read_handles->{$pid} = $from_r;
        # EWW, FIXME, USE ATTRIBUTE
        $self->{__hdl}{$pid} = AnyEvent::Handle->new(
           fh => $from_r,
           on_error => sub {
              my ($hdl, $fatal, $msg) = @_;
              warn "got error $msg\n";
              $hdl->destroy;
           },
           on_read => sub {
               my ($hdl) = @_;
               my $buf = $hdl->{rbuf};
               $hdl->{rbuf} = '';
#               warn("PARENT HANDLE DID READ");
               while ( $self->get_json_from_buffer(\$buf, sub {
                   my $running = $self->_workers->{$pid};
                   $self->_workers->{$pid} = 0;
                   if (my $cv = $self->_hit_max) {
                       $self->_hit_max(undef);
                       $cv->send;
                   }
#                   warn("GOT FINISHED JOB " . Data::Dumper::Dumper($running));
                   $self->job_finished($running, shift);
                }))
                { 1; }
           },
        );
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

method json_object ($json) {
    warn("PARENT GOT BACK: $json");
}

with 'CatalystX::JobServer::Role::BufferWithJSON';

__PACKAGE__->meta->make_immutable;
1;
