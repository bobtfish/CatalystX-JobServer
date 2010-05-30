package CatalystX::JobServer::Job::Test::RunForThirtySeconds;

sub run {
    sleep 30;
    return 303;
}

1;
