use strict;
use warnings;
use Test::More;

use CatalystX::JobServer::JobState;

my $jobs = CatalystX::JobServer::JobState->new(
    
);

ok $jobs;

done_testing;
