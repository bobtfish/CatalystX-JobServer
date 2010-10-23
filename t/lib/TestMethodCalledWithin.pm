package TestMethodCalledWithin;
use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw/ Int Str /;
use namespace::autoclean;

parameter method => (
    isa      => Str,
    required => 1,
);

parameter within => (
    isa => Int,
    default => '3',
);

role {
    my $p = shift;

    my $name = $p->method;
    my $timeout = $p->within;

    my $callback_name = "${name}_iscalled_callback";

    with 'CatalystX::JobServer::Role::CallbackWrapper' => {
        wrap => $name,
        wrap_type => 'after',
        callback_name => $callback_name,
    };

    my ($cv, $timer);

    around BUILDARGS => sub {
        my ($orig, $self, @args) = @_;
        my $args = $self->$orig(@args);
        $args->{$callback_name} = sub {
            undef $timer;
            $cv->send if $cv;
        };
        return $args;
    };

    method "test_${name}_called" => sub {
        my $self = shift;
        $cv = AnyEvent->condvar;
        $timer = AnyEvent->timer( after => $timeout, cb => sub { $cv->croak("timed out waiting for $name") });
        ::lives_ok { $cv->recv } "$name called";
        undef $cv;
    };

};


1;
