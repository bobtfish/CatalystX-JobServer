package App::TailRabbit;
use Moose;
use MooseX::Getopt;
use Net::RabbitFoot;
use Data::Dumper;
use MooseX::Types::Moose qw/ ArrayRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use AnyEvent;
use YAML qw/LoadFile/;
use File::HomeDir;
use Path::Class qw/ file /;
use namespace::autoclean;

with qw/
    MooseX::Getopt
    MooseX::ConfigFromFile
/;

has exchange_name => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    required => 1,
);

has routing_key => (
    is => 'ro',
    isa => ArrayRef[NonEmptySimpleStr],
    default => sub { [] },
);

has rabbitmq_host => (
    is => 'ro',
    default => 'localhost',
);

has [qw/ rabbitmq_user rabbitmq_pass /] => (
    is => 'ro',
    default => 'guest',
);

sub get_config_from_file {
    my ($class, $file) = @_;
    return LoadFile($file) if (-r $file);
    return {};
}

has 'configfile' => (
    default => file(File::HomeDir->my_data(), ".tailrabbit.yml")->stringify,
    is => 'bare',
);

my $rf = Net::RabbitFoot->new(
#        verbose => 1,
)->load_xml_spec(
    Net::RabbitFoot::default_amqp_spec(),
);

sub _get_mq {
    my $self = shift;
    $rf->connect(
        host => $self->rabbitmq_host,
        port => 5672,
        user => $self->rabbitmq_user,
        pass => $self->rabbitmq_pass,
        vhost => '/',
        on_close => sub {
            die("MQ connection closed");
        },
        on_read_failure => sub {
            die("READ FAILED");
        },
        on_failure => sub {
            die("Failed to connect to mq");
        },
    );
    return $rf;
}

sub _bind_anon_queue {
    my ($self, $ch) = @_;
    my $queue_frame = $ch->declare_queue(
        auto_delete => 1,
        exclusive => 1,
    )->method_frame;
    my @keys = @{ $self->routing_key };
    push(@keys, "#") unless scalar @keys;
    foreach my $key (@keys) {
        warn("Bind to $key");
        my $bind_frame = $ch->bind_queue(
            queue => $queue_frame->queue,
            exchange => $self->exchange_name,
            routing_key => $key,
        )->method_frame;
        die Dumper($bind_frame) unless blessed $bind_frame and $bind_frame->isa('Net::AMQP::Protocol::Queue::BindOk');
    }
}

sub _get_channel {
    my ($self, $rf) = @_;
    my $ch = $rf->open_channel();
    my $exch_frame = $ch->declare_exchange(
        type => 'topic',
        durable => 1,
        exchange => $self->exchange_name,
    )->method_frame;
    die Dumper($exch_frame) unless blessed $exch_frame and $exch_frame->isa('Net::AMQP::Protocol::Exchange::DeclareOk');
    return $ch;
}

sub run {
    my $self = shift;
    my $ch = $self->_get_channel($self->_get_mq);
    $self->_bind_anon_queue($ch);
    my $done = AnyEvent->condvar;
    warn("MOO");
    $ch->consume(
        on_consume => sub {
            my $message = shift;
            $self->notify($message);
        },
    );
    $done->recv; # Go into the event loop forever.
}

sub notify {
    my ($self, $message) = @_;
    print $message->{deliver}->method_frame->routing_key,
        ': ', $message->{body}->payload, "\n";
}

__PACKAGE__->meta->make_immutable;
1;

