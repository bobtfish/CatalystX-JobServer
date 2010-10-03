package CatalystX::JobServer::MessageQueue;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Int Bool HashRef ArrayRef Str /;
use Try::Tiny;
use MooseX::Types::Structured qw/ Dict Optional /;
use AnyEvent;
use Coro;
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

my ($build_mq_lock, $conn);
method _build_mq {
# FIXME
#    $build_mq_lock ?
#        do { $build_mq_lock->recv; return $conn }
#      : do { $build_mq_lock = AnyEvent->condvar };
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
#        $build_mq_lock->send;
#        undef $build_mq_lock;
        # FIXME - Retry?
        die(sprintf("Could not connect to Rabbit MQ server on %s:%s - error $_\n", $self->host, $self->port));
    };
#    $build_mq_lock->send;
#    undef $build_mq_lock;
    return $conn;
}

# Horrible, make these real objects somehow..
has channels => (
    isa => HashRef[Dict[
        exchanges => ArrayRef[HashRef],
        queues => Optional[ArrayRef[Dict[
            queue => NonEmptySimpleStr,
            durable => Bool,
            bind => Dict[
                exchange => NonEmptySimpleStr,
                routing_key => Str,
            ],
        ]]],
        dispatch_to => Optional[NonEmptySimpleStr],
        results_exchange => Optional[NonEmptySimpleStr],
        results_routing_key => Optional[Str],
    ]],
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

foreach my $name (qw/ published consumed /) {
    has 'channel_messages_' . $name => (
        isa => HashRef,
        is => 'ro',
        lazy => 1,
        default => sub {
            return { map { $_ => 0 } keys %{ shift->channels } };
        },
        traits => ['Serialize'],
        clearer => '_clear_channel_messages_' . $name,
    );
}

has _channel_objects => (
    isa => HashRef,
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_channel_objects',
);
after _channel_objects => sub {
    my $self = shift;
    $self->channel_messages_published;
    $self->channel_messages_consumed;
};

before '_clear_mq' => sub { shift->_clear_channel_objects };

foreach my $name (qw/ channels exchanges queues bindings /) {
    my $attr_name = "no_of_" . $name . "_registered";
    has "no_of_" . $name . "_registered" => (
        isa => Int,
        is => 'ro',
        lazy => 1, # Hack, needed to avoid bug applying roles to instances in Moose, see test case.
        init_arg => undef,
        default => 0,
        traits => ['Counter', 'Serialize'],
        handles => {
            "_reset_" . $attr_name => 'reset',
            "_inc_" . $attr_name   => 'inc',
        },
    );
}
after '_clear_channel_objects' => sub {
    my $self = shift;
    $self->_reset_no_of_channels_registered;
    $self->_reset_no_of_exchanges_registered;
    $self->_reset_no_of_queues_registered;
    $self->_reset_no_of_bindings_registered;
    $self->_clear_channel_messages_consumed;
    $self->_clear_channel_messages_published;
    $self->_clear_channel_publishers;
};

has _channel_publishers => (
    isa => HashRef,
    default => sub { {} },
    lazy => 1,
    is => 'ro',
    clearer => '_clear_channel_publishers',
);

sub publish_to_channel {
    my ($self, $channel, $message) = @_;
    $self->_channel_objects; # Ensure we have this built (with criticial section locked)
    my $publisher = $self->_channel_publishers->{$channel}
        or croak "Cannot find channel $channel";
    $publisher->($message);
}

with 'CatalystX::JobServer::Role::LocatesModels';

my ($build_channel_objects_lock, %channel_objects);
sub _build__channel_objects {
    my $self = shift;
# FIXME
#    $build_channel_objects_lock ?
#        do { $build_channel_objects_lock->recv; return $conn }
#      : do { $build_channel_objects_lock = AnyEvent->condvar };
    %channel_objects = ();
    foreach my $name (keys %{$self->channels}) {
        #warn("Building channel named $name");
        my $channel_data = $self->channels->{$name};
        my $channel = $self->mq->open_channel;
        $channel_objects{$name} = $channel;
        $self->_inc_no_of_channels_registered;
        $self->_build_exchanges_for_channel($channel, $channel_data->{exchanges});
        my $have_queues = $self->_build_queues_for_channel($channel, $channel_data->{queues});
        #warn("GOT DISPATCH TO " . $channel_data->{dispatch_to});
        my $code = CatalystX::JobServer::Web->can('model');
        # FIXME - For tests
        next unless $code;
        my $publisher = $channel_data->{results_exchange}
            ? sub {
                my $body = shift;
                #warn("Publishing return message $body to ". $channel_data->{results_exchange});
                $channel->publish(
                    body => $body,
                    exchange => $channel_data->{results_exchange},
                    routing_key => $channel_data->{results_routing_key} . ':' . $channel_data->{dispatch_to},
                );
                $self->channel_messages_published->{$name}++;
            }
            : sub { warn shift; };
        $self->_channel_publishers->{$name} = $publisher;
        $channel->consume(
            on_consume => sub {
                my $message = shift;
                my $dispatch_to = $self->locate_model( $channel_data->{dispatch_to} );
                Carp::confess("Cannot find dispatch_to for $name " . $channel_data->{dispatch_to})
                    unless $dispatch_to;
                $dispatch_to->consume_message($message, sub { $self->publish_to_channel($name, shift() ) } );
                $self->channel_messages_consumed->{$name}++;
            },
        )
            if $have_queues;
    }
    #$build_channel_objects_lock->send;
    return {%channel_objects};
}

sub _build_exchanges_for_channel {
    my ($self, $channel, $exchanges) = @_;
    foreach my $exchange ( @$exchanges ) {
        #warn("Building exchange " . $exchange->{exchange});
        my $exch_frame = $channel->declare_exchange(
            %$exchange
        )->method_frame;
        die "Failed to setup exchange $exchange " . Dumper($exch_frame)
            unless blessed $exch_frame and $exch_frame->isa('Net::AMQP::Protocol::Exchange::DeclareOk');
        $self->_inc_no_of_exchanges_registered;
    }
}

sub _build_queues_for_channel {
    my ($self, $channel, $queues) = @_;
    my $count = 0;
    foreach my $queue ( @$queues ) {
        $count++;
        my $binding = delete $queue->{bind};
        #warn("Building queue " . $queue->{queue});
        my $queue_frame = $channel->declare_queue(
           %$queue
       )->method_frame;
       $queue->{bind} = $binding; # Eww.
       $self->_inc_no_of_queues_registered;
       $self->_build_binding_for_queue($channel, $queue_frame->queue, $binding);
    }
    return $count;
}
use Data::Dumper;
sub _build_binding_for_queue {
    my ($self, $channel, $queue_name, $binding) = @_;
    local $binding->{queue} = $queue_name;
    #warn("Binding " . Dumper($binding));
    my $bind_frame = $channel->bind_queue(
       %$binding,
    );
    die "Bad bind to queue $queue_name " . Dumper($bind_frame)
            unless blessed $bind_frame->method_frame and $bind_frame->method_frame->isa('Net::AMQP::Protocol::Queue::BindOk');
    $self->_inc_no_of_bindings_registered;
}

sub BUILD { shift->_channel_objects }

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
            channels:
                jobs:
                    exchanges:
                        - type: topic
                          durable: 1
                          exchange: jobs
                    queues:
                        - queue: jobs_queue
                          durable: 1
                          bind:
                            exchange: jobs
                            routing_key: "#"
                    dispatch_to: ForkedJobRunner
                    results_exchange: firehose
                    results_routing_key: ""
                firehose:
                    exchanges:
                        - type: topic
                          durable: 1
                          exchange: firehose
                    queues:
                        - queue: firehose_log
                          durable: 1
                          bind:
                              exchange: firehose
                              routing_key: "#"
                    dispatch_to: FireHoseLog
                    results_exchange: firehose
                    results_routing_key: ""

=head1 DESCRIPTION

Creates the specified channels, exchanges, queues and bindings in RabbitMQ.

Messages recieved in each channel wil be dispatched into other services within the application
and results are published to RabbitMQ.

=cut
