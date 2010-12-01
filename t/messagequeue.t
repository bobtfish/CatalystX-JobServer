use strict;
use warnings;
use Test::More;

use CatalystX::JobServer::MessageQueue;

my $mq = CatalystX::JobServer::MessageQueue->new();
ok $mq, 'Have mq';

ok $mq->_has_mq;
ok $mq->mq;
ok $mq->_has_mq;

done_testing;
