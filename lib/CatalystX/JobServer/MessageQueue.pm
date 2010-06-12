package CatalystX::JobServer::MessageQueue;
use CatalystX::JobServer::Moose;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Int Bool HashRef ArrayRef Str /;
use Try::Tiny;
use MooseX::Types::Structured qw/ Dict /;
use JSON qw/ decode_json /;
use AnyEvent;
use Coro;
use aliased 'Net::RabbitFoot';
use Data::Dumper;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();

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

method BUILD ($args) {
    my $cv = AnyEvent->condvar;
    async {
        try {
            $self->mq;
            $self->_channel_objects;
    #        for (1..10) {
    #        $self->_channel_objects->{jobs}->publish(
    #             body => CatalystX::JobServer::Job::Test::RunForThirtySeconds->new(retval => rand(808))->freeze,
    #             exchange => 'jobs',
    #             routing_key => '#',
    #         );
    #        }
        }
        catch {
            $cv->croak($_);
        };
        $cv->send;
    };
    $cv->recv;
}

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
        die(sprintf("Could not connect to Rabbit MQ server on %s:%s - error $_\n", $self->host, $self->port));
    };
    return $conn;
}

# Horrible, make these real objects somehow..
has channels => (
    isa => HashRef[Dict[
        exchanges => ArrayRef[HashRef],
        queues => ArrayRef[Dict[
            queue => NonEmptySimpleStr,
            durable => Bool,
            bind => Dict[
                exchange => NonEmptySimpleStr,
                routing_key => Str,
            ],
        ]],
        dispatch_to => NonEmptySimpleStr,
        results_exchange => NonEmptySimpleStr,
        results_routing_key => Str,
    ]],
    is => 'ro',
    required => 1,
    traits => ['Serialize'],
);

has _channel_objects => (
    isa => HashRef,
    is => 'ro',
    lazy_build => 1,
    clearer => '_clear_channel_objects',
);

before '_clear_mq' => sub { Carp::cluck("_clear_mq called"); shift->_clear_channel_objects };

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
};

sub _build__channel_objects {
    my $self = shift;
    my %data;
    foreach my $name (keys %{$self->channels}) {
        my $channel_data = $self->channels->{$name};
        my $channel = $self->mq->open_channel;
        $data{$name} = $channel;
        $self->_inc_no_of_channels_registered;
        $self->_build_exchanges_for_channel($channel, $channel_data->{exchanges});
        $self->_build_queues_for_channel($channel, $channel_data->{queues});
        #warn("GOT DISPATCH TO " . $channel_data->{dispatch_to});
        my $code = CatalystX::JobServer::Web->can('model');
        next unless $code;
        my $dispatch_to = $code->('CatalystX::JobServer::Web', $channel_data->{dispatch_to}); # FIXME - EVIL!!
        $channel->consume(
            on_consume => sub {
                #warn("CONSUME MESSAGE");
                my $message = shift;
                print $message->{deliver}->method_frame->routing_key,
                    ': ', $message->{body}->payload, "\n";
                # FIXME - deal with not being able to unserialize
                my $data = decode_json($message->{body}->payload);
                my $class = $data->{__CLASS__}; # FIXME - Deal with bad class.
                my $job = $class->unpack($data);
                $dispatch_to->run_job($job, $channel_data->{results_exchange}
                    ? sub { $channel->publish(
                     body => shift,
                     exchange => $channel_data->{results_exchange},
                     routing_key => $channel_data->{results_routing_key} . ':' . $class,
                 )} : sub { warn shift; });
            },
        );
    }
    return \%data;
}

sub _build_exchanges_for_channel {
    my ($self, $channel, $exchanges) = @_;
    foreach my $exchange ( @$exchanges ) {
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
    foreach my $queue ( @$queues ) {
        my $binding = delete $queue->{bind};
        my $queue_frame = $channel->declare_queue(
           %$queue
       )->method_frame;
       $queue->{bind} = $binding; # Eww.
       $self->_inc_no_of_queues_registered;
       $self->_build_binding_for_queue($channel, $queue_frame->queue, $binding);
    }
}

sub _build_binding_for_queue {
    my ($self, $channel, $queue_name, $binding) = @_;
    local $binding->{queue} = $queue_name;
    my $bind_frame = $channel->bind_queue(
       %$binding,
    );
    die "Bad bind to queue $queue_name " . Dumper($bind_frame)
            unless blessed $bind_frame->method_frame and $bind_frame->method_frame->isa('Net::AMQP::Protocol::Queue::BindOk');
    $self->_inc_no_of_bindings_registered;
}

sub DEMOLISH {
    my ($self) = shift;
    $self->_mq->drain_writes(1)
        if $self->_has_mq;
    $self->_clear_mq;
}

__PACKAGE__->meta->make_immutable;
