package CatalystX::JobServer::Role::MessageQueue::Consumer;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Bool /;
use Scalar::Util qw/ refaddr /;
use Data::Dumper;
use Try::Tiny qw/ try catch /;

with 'CatalystX::JobServer::Role::MessageQueue::HasChannel';

requires 'consume_message';

after BUILD => sub {
    my $self = shift;
    # Cheesy hack to avoid races in Net::RabbitFoor
    my $t; $t = AnyEvent->timer( after => 1, cb => sub { undef $t; $self->build_messagequeue_consumer });
};

has _have_built_consumer => (
    is => 'rw',
    isa => Bool,
    default => 0,
);

method build_messagequeue_consumer {
    return if $self->_have_built_consumer;
    $self->_have_built_consumer(1);
    $self->_channel->{arc}->consume(
        on_consume => sub {
            my $message = shift;
            try {
                $self->consume_message($message);
            }
            catch {
                warn("Error in consume_message callback: $_");
            };
        },
        consumer_tag => refaddr($self),
        on_success => sub {
            $self->_have_built_consumer(1);
        },
        on_failure => sub {
            Carp::cluck("Failed to start message consumer in $self response " . Dumper(@_));
        },
    );
}

method cancel_messagequeue_consumer {
    return unless $self->_have_built_consumer;
    $self->_channel->{arc}->cancel( # Use the nonblocking interface directly as we'll likely be called from callbacks
        consumer_tag => refaddr($self),
        on_success => sub {
            $self->_have_built_consumer(0);
        },
        on_failure => sub {
            Carp::cluck("Failed to cancel message consumer in $self response " . Dumper(@_));
        },
    );
}

1;
