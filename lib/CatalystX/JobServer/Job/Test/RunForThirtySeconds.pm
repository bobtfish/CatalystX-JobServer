package CatalystX::JobServer::Job::Test::RunForThirtySeconds;
use Moose;
use MooseX::Types::Moose qw/ Num /;
use MooseX::Storage;

with Storage(format => 'JSON');

has retval => (
    isa => Num,
    is => 'ro',
    required => 1,
);

sub run {
    sleep 30;
    return 303;
}

1;
