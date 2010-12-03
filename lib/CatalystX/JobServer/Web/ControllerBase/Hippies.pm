package CatalystX::JobServer::Web::ControllerBase::Hippies;
use CatalystX::JobServer::Moose;
use Try::Tiny;
use Scalar::Util qw/ refaddr /;
use JSON qw/ decode_json /;
use MooseX::Types::Moose qw/ HashRef /;

BEGIN { extends 'Catalyst::Controller' }

with qw/
    CatalystX::JobServer::Web::Role::Hippie
    CatalystX::JobServer::Role::MessageQueue::BindsQueues
/;

__PACKAGE__->config(
    action => {
        hippie => {
            Chained => [ 'find' ],
        }
    },
);

has pipes => (
    is => 'ro',
    isa => HashRef,
    traits => ['Hash'],
    default => sub { {} },
    handles => {
        
    },
);

sub find : Chained('/base') PathPart('hippies') CaptureArgs(1) {
    my ($self, $c, $keys) = @_;
    my @keys = split /,/, $keys;
    $c->stash( keys => \@keys );
}

sub view : Chained('find') PathPart('') Args(0) {}

sub hippie_init {
    my ($self, $c, $env) = @_;
    my $h = $env->{'hippie.handle'};
    try {
    warn("Init");
    my $mq = $c->model('MessageQueue');
    warn("MQ");
    my $ch = $mq->mq->{_ar}->open_channel(
        on_success => sub {
            my $ch = shift;
            warn("Channel");
            $ch->declare_queue(
                auto_delete => 1,
                exclusive => 1,
                on_success => sub {
                    my $queue_frame = shift->method_frame;
                    warn("queue");
                    my @tasks = ([sub { warn("Start consumer"); $ch->consume(
                        on_consume => sub {
                            my $message = shift;
                            print $message->{deliver}->method_frame->routing_key,
                            ': ', $message->{body}->payload, "\n";
                            $h->send_msg(decode_json($message->{body}->payload));
                        },
                    )}, sub {}]);
                    foreach my $routing_key ('#') {
                        unshift(@tasks, [sub {
                            $ch->bind_queue(
                                queue => $queue_frame->queue,
                                exchange => 'firehose',
                                routing_key => $routing_key,
                                on_success => shift,
                                on_failure => sub { warn("Failed to bind") },
                            )},
                            sub {
                                my $bind_frame = shift->method_frame;
                                die Dumper($bind_frame) unless blessed $bind_frame and $bind_frame->isa('Net::AMQP::Protocol::Queue::BindOk');
                                warn("Bind");
                            }
                        ]);
                    }
                    my $work; $work = sub {
                        return unless scalar @tasks;
                        my $task = shift(@tasks);
                        my ($do, $success) = @$task;
                        warn("Do $do success $success");
                        $do->(sub { $success->(@_); $work->() });
                    };
                    $work->();
                },
                on_failure => sub { warn("Failed to declare queue") },
            );
        },
        on_failure => sub { warn("Failed to open channel")},
    );
    $self->pipes->{refaddr($h)} = $ch;
} catch { warn $_; };
}

sub hippie_error {
    my ($self, $c, $env) = @_;
    warn("Error");
    my $h = $env->{'hippie.handle'};
    my $ch = $self->pipes->{refaddr($h)};
    return unless $ch;
    $ch->close(
        on_success => sub {
            delete $self->pipes->{refaddr($h)};
        },
        on_failure => sub {
            delete $self->pipes->{refaddr($h)};
        }
    );
}


__PACKAGE__->meta->make_immutable;
1;
