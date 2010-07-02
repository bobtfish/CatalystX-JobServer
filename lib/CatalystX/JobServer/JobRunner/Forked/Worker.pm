package CatalystX::JobServer::JobRunner::Forked::Worker;
use CatalystX::JobServer::Moose;
use AnyEvent;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
#use MooseX::Types::Moose qw/ ArrayRef /;
use AnyEvent::Handle;
use JSON;
use Try::Tiny;

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
    my ($instance, $ret);
    my $class = try {
        #warn("GOT JOB: '$json'");
        my $data = from_json($json);
        my $class = to_LoadableClass($data->{__CLASS__})
            or die("Coud not load class " . $data->{__CLASS__});
        $instance = $class->unpack($data);
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
