package CatalystX::JobServer::MessageQueue;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Int Bool HashRef ArrayRef Str /;
use Try::Tiny;
use MooseX::Types::Structured qw/ Dict Optional /;
use AnyEvent;
use Carp qw/ croak confess /;
use aliased 'Net::RabbitFoot';
use Data::Dumper;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();

with 'CatalystX::JobServer::Role::Storage';

our $VERBOSE = 0;

has mq => (
    is => 'ro',
    isa => RabbitFoot,
    lazy => 1,
    init_arg => undef,
    predicate => '_has_mq',
    builder => '_build_mq',
    clearer => '_clear_mq',
    handles => [qw/
        open_channel
    /],
);

has host => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    default => 'localhost',
    traits => [qw/ Serialize /],
);

has port => (
    isa => Int,
    is => 'ro',
    default => '5672',
    traits => [qw/ Serialize /],
);

foreach my $name (qw/ user pass /) {
    has $name => (
        isa => NonEmptySimpleStr,
        is => 'ro',
        default => 'guest',
    );
}

has vhost => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    default => '/',
    traits => [qw/ Serialize /],
);

my $rf = RabbitFoot->new(
    verbose => $VERBOSE,
)->load_xml_spec(
    Net::RabbitFoot::default_amqp_spec(),
);

method _build_mq {
    my $conn;
    try {
        $conn = $rf->connect(
           on_close => sub {
                 warn(sprintf("RabbitMQ connection to %s:%s closed!\n", $self->host, $self->port));
                 $self->_clear_mq;
             },
             on_failure => sub {
                 die(sprintf("Connection to RabbitMQ on %s:%s failed!\n" , $self->host, $self->port));
                 return;
             },
             map { $_ => $self->$_ } qw/ host port user pass vhost /,
        );
    }
    catch {
        # FIXME - Retry?
        die(sprintf("Could not connect to Rabbit MQ server on %s:%s - error $_\n", $self->host, $self->port));
    };
    return $conn;
}


sub BUILD { shift->mq; }

sub DEMOLISH {
    my ($self) = shift;
    $self->_mq->drain_writes(1)
        if $self->_has_mq;
    $self->_clear_mq;
}

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

CatalystX::JobServer::MessageQueue - Abstraction over RabbitMQ for CatalystX::JobServer

=head1 SYNOPSIS

    Model::MessageQueue:
        class: "CatalystX::JobServer::MessageQueue"
        args:
            port: 5672
            host: localhost
            vhost: /
            user: guest
            pass: guest

=head1 DESCRIPTION

Creates the specified channels, exchanges, queues and bindings in RabbitMQ.

Messages recieved in each channel wil be dispatched into other services within the application
and results are published to RabbitMQ.

=cut
