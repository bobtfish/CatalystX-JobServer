package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use MooseX::Types::Moose qw/ HashRef Int /;
use AnyEvent::Handle;
use namespace::autoclean;

with 'CatalystX::JobServer::JobRunner';

sub post_fork {
    my ($self, $job) = @_;
}

has num_workers => (
    isa => Int,
    is => 'ro',
    default => 1,
);

has workers => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

foreach (qw/ write read /) {
    has $_ . '_handles' => (
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

sub _do_run_job {
    my ($self, $job, $return_cb) = @_;

    my $pid = (keys %{ $self->workers })[0];
    my $from_r = $self->read_handles->{$pid};
    my $to_w = $self->write_handles->{$pid};
    $to_w->syswrite("\x00" . $job . "\xff");

    my $cv = AnyEvent->condvar;
    my $hdl = AnyEvent::Handle->new(
       fh => $from_r,
       on_error => sub {
          my ($hdl, $fatal, $msg) = @_;
          warn "got error $msg\n";
          $hdl->destroy;
          $cv->send;
       },
       on_read => sub {
           my ($hdl) = @_;
           my $buf = $hdl->{rbuf};
           $hdl->{rbuf} = '';
           while ($self->get_json_from_buffer(\$buf, $return_cb)) { 1; }
       },
    );
    #if (scalar @_) {
    #    $self->job_finished($job, shift, $return_cb);
    #}
    #else {
    #    warn("Job failed, returned " . $@);
    #    $self->job_failed($job, $@, $return_cb);
    #}
    $cv->recv;
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
        $self->workers->{$pid} = 0;
        $self->write_handles->{$pid} = $to_w;
        $self->read_handles->{$pid} = $from_r;
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
