package CatalystX::JobServer::JobRunner::Forked::Worker;
use CatalystX::JobServer::Moose;
use AnyEvent;
use AnyEvent::Handle;

method run {
    $|=1;
    my $buf;
    my $cv = AnyEvent->condvar;
    my $hdl = AnyEvent::Handle->new(
       fh => \*STDIN,
       on_error => sub {
          my ($hdl, $fatal, $msg) = @_;
          Carp::cluck "got error $msg\n";
          $hdl->destroy;
          $cv->send;
       },
       on_read => sub {
           my ($hdl) = @_;
           $buf .= $hdl->{rbuf};
           $hdl->{rbuf} = '';
           while ($self->get_json_from_buffer(
               \$buf, sub { $self->json_object(shift) })
           ) { 1; } # Call as many times as we have JSON
       },
    );
    $cv->recv;
}

method json_object ($json) {
#    warn("GOT JOB: $json");
    print "\x00RET VALUE\xff";
}

with 'CatalystX::JobServer::Role::BufferWithJSON';

__PACKAGE__->meta->make_immutable;
1;
