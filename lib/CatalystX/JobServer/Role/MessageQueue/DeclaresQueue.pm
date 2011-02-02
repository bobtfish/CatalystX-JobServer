package CatalystX::JobServer::Role::MessageQueue::DeclaresQueue;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use MooseX::Types::Moose qw/ Bool /;
use Moose::Util::TypeConstraints;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

has queue_name => (
    is => 'ro',
    isa => NonEmptySimpleStr,
    predicate => '_has_queue_name',
    lazy => 1,
    default => sub {
        shift->_queue->queue;
    }
);

# FIXME - Should auto-build from _queue as above
has queue_type => (
    is => 'ro',
    isa => enum([qw/ topic direct fanout /]),
    default => 'topic',
);

# FIXME - Should auto-build from _queue as above
has queue_durable => (
    is => 'ro',
    isa => Bool,
    default => 1,
);

has _queue => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        $self->_channel->declare_queue(
            durable => $self->queue_durable,
            $self->_has_queue_name ? (queue => $self->queue_name) : (),
        )->method_frame;
    }
);

1;
