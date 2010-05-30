package CatalystX::JobServer::MessageQueue;
use Moose;
use Method::Signatures::Simple;
use MooseX::Types::Moose qw/ NonEmptySimpleStr Int Bool /;
use namespace::autoclean;

has mq => (
    isa => 'Net::RabbitFot',
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

method _build__mq {
    my $rf = Net::RabbitFoot->new(
        verbose => $self->verbose,
    )->load_xml_spec(
        Net::RabbitFoot::default_amqp_spec(),
    )->connect(
       map { $_ => $self->$_ } qw/ host port user pass vhost /
    );
   return $rf;
}

__PACKAGE__->meta->make_immutable;
