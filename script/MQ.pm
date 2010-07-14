#!/usr/bin/env perl
package MQ;
use Moose::Role;
use Net::RabbitFoot;
use Data::Dumper;
use namespace::autoclean;

with 'MooseX::Getopt';

sub _get_mq {
    my $rf = Net::RabbitFoot->new(
#        verbose => 1,
    )->load_xml_spec(
        Net::RabbitFoot::default_amqp_spec(),
    )->connect(
        host => "localhost",
        port => 5672,
        user => 'guest',
        pass => 'guest',
        vhost => '/',
        on_close => sub {
            die("Closed");
        },
        on_read_failure => sub {
            die("READ FAILED");
        },
        on_failure => sub {
            die("FAIL");
        },
    );
    return $rf;
}

sub _bind_anon_queue_to_firehose {
    my ($self, $ch) = @_;
    my $queue_frame = $ch->declare_queue(
        auto_delete => 1,
        exclusive => 1,
    )->method_frame;
    my $bind_frame = $ch->bind_queue(
        queue => $queue_frame->queue,
        exchange => 'firehose',
        routing_key => '#',
    )->method_frame;
    die Dumper($bind_frame) unless blessed $bind_frame and $bind_frame->isa('Net::AMQP::Protocol::Queue::BindOk');
}


sub _get_channel {
    my ($self, $rf) = @_;
    my $ch = $rf->open_channel();
    warn("Got channel");
    my $exch_frame = $ch->declare_exchange(
        type => 'topic',
        durable => 1,
        exchange => 'firehose',
    )->method_frame;
    warn("Got exchange");
    die Dumper($exch_frame) unless blessed $exch_frame and $exch_frame->isa('Net::AMQP::Protocol::Exchange::DeclareOk');
    return $ch;
}

1;

