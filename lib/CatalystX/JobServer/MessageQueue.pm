package CatalystX::JobServer::MessageQueue;
use Moose;
use Method::Signatures::Simple;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Int Bool /;
use aliased 'Net::RabbitFoot';
use Try::Tiny;
use namespace::autoclean;

has mq => (
    is => 'ro',
    isa => RabbitFoot,
    lazy_build => 1,
    handles => [qw/
        open_channel
    /],
);

method BUILD {
    $self->mq
}

has host => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    default => 'localhost',
);

has port => (
    isa => Int,
    is => 'ro',
    default => '5672',
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
);

has verbose => (
    isa => Bool,
    is => 'ro',
    default => 0,
);

method _build_mq {
    my $rf;
    try {
        $rf = RabbitFoot->new(
            verbose => $self->verbose,
        )->load_xml_spec(
            Net::RabbitFoot::default_amqp_spec(),
        )->connect(
           map { $_ => $self->$_ } qw/ host port user pass vhost /
        );
    }
    catch {
        die(sprintf("Could not connect to Rabbit MQ server on %s:%s - error $_\n", $self->host, $self->port));
    };
    return $rf;
}

__PACKAGE__->meta->make_immutable;
