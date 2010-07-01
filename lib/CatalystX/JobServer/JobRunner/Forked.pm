package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ portable_pipe /;
use AnyEvent::Handle;
use namespace::autoclean;

with 'CatalystX::JobServer::JobRunner';

sub post_fork {
    my ($self, $job) = @_;
}

sub _do_run_job {
    my ($self, $job, $return_cb) = @_;
    my ($to_r, $to_w) = portable_pipe;
    my ($from_r, $from_w) = portable_pipe;
    my $pid = fork;

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

    if ($pid != 0) {
        # parent
        close( $to_r );
        close( $from_w );
        $to_w->syswrite("\x00" . $job . "\xff");
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
    #    if (scalar @_) {
    #        $self->job_finished($job, shift, $return_cb);
    #    }
    #    else {
    #        warn("Job failed, returned " . $@);
    #        $self->job_failed($job, $@, $return_cb);
    #    }
    #};
    $cv->recv;
}

method json_object ($json) {
    warn("PARENT GOT BACK: $json");
}

with 'CatalystX::JobServer::Role::BufferWithJSON';

__PACKAGE__->meta->make_immutable;
1;
