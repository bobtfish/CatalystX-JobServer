package CatalystX::JobServer::Role::MessageQueue::DeclaresExchange;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Bool /;
use Moose::Util::TypeConstraints;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

has exchange_name => (
    is => 'ro',
    required => 1,
    isa => NonEmptySimpleStr,
);

has exchange_type => (
    is => 'ro',
    isa => enum([qw/ topic direct fanout /]),
    default => 'topic',
);

has exchange_durable => (
    is => 'ro',
    isa => Bool,
    default => 1,
);

has _exchange => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        warn("ABOUT TO DECLARE EXCHANGE");
        my $exch_frame = $self->_channel->declare_exchange(
            type => $self->exchange_type,
            durable => $self->exchange_durable,
            exchange => $self->exchange_name,
        )->method_frame;
        confess "Failed to setup exchange exchange " . Dumper($exch_frame)
            unless blessed $exch_frame and $exch_frame->isa('Net::AMQP::Protocol::Exchange::DeclareOk');
    }
);

1;
