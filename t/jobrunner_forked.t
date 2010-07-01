use strict;
use warnings;
use Test::More;

use CatalystX::JobServer::JobRunner::Forked;

my $jobs = CatalystX::JobServer::JobRunner::Forked->new(
);

ok $jobs;

$jobs->_do_run_job('TEXT', sub { warn("CALLED") });

done_testing;
