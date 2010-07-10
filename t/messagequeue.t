use strict;
use warnings;
use Test::More;

use CatalystX::JobServer::MessageQueue;

my $mq = CatalystX::JobServer::MessageQueue->new(
    channels => {
        test => {
            exchanges => [
                {
                    type => 'topic',
                    durable => 0,
                    exchange => 'testexchange'
                },
            ],
            queues => [
                {
                    queue => 'testqueue',
                    durable => 0,
                    bind => {
                        exchange => 'testexchange',
                        routing_key => '#',
                    },
                },
            ],
            dispatch_to => 'JobState',
            results_exchange => 'test_results',
            results_routing_key => '',
        },
    },
    model_locator_callback => sub { return bless {}, 'SomeModel' },
);
ok $mq, 'Have mq';

ok !$mq->_has_mq;
ok $mq->mq;
ok $mq->_has_mq;

foreach my $name (qw/ channels exchanges queues bindings /) {
    my $attr_name = "no_of_" . $name . "_registered";
    is $mq->$attr_name, 0, "0 $attr_name before connect";
}

done_testing;
