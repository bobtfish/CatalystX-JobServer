use strict;
use warnings;
use Test::More;

use CatalystX::JobServer::JobRunner::Forked;

my $jobs = CatalystX::JobServer::JobRunner::Forked->new(
);

ok $jobs;

done_testing;
