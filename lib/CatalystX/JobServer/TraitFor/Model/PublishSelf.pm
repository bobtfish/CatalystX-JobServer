package CatalystX::JobServer::TraitFor::Model::PublishSelf;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ Int /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use Coro;
use AnyEvent;

with qw/
    CatalystX::JobServer::Role::QueuePublisher
    CatalystX::JobServer::Role::Storage
/;

has publish_self_every => (
    isa => Int,
    is => 'ro',
    traits => ['Serialize'],
    required => 1,
);

has publish_self_to => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    traits => ['Serialize'],
    required => 1,
);

has _publish_timer => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;
        AnyEvent->timer (
            after => $self->publish_self_every,
            interval => $self->publish_self_every,
            cb => sub {
                my $frozen = $self->freeze;
                #warn("Publishing #self from timer\n");
                $self->publish_message($self->publish_self_to, $self->freeze);
            },
        );
    },
    clearer => '_clear_publish_timer',
);

sub BUILD {}
after BUILD => sub {
    Coro::cede; # Try to make it likely we've connected to MQ before we try publishing anything.
    shift->_publish_timer;
};

1;

=head1 NAME

CatalystX::JobServer::TraitFor::Model::PublishSelf - Publishes the serialization of another class to a queue at regular intervals.

=cut
