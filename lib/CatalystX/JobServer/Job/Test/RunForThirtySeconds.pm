package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use Moose;
use MooseX::Storage;

with Storage(format => 'JSON');

sub run {
    sleep 30;
    return 303;
}

1;
