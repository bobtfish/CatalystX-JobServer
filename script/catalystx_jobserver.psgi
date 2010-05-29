use strict;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use aliased 'CatalystX::JobServer::Web';
use Plack::Runner;
use Coro;
use AnyEvent;

Web->setup_engine('PSGI');
my $app = sub { CatalystX::JobServer::Web->run(@_) };
my $runner = Plack::Runner->new(server => 'Corona', env => 'deployment');
$runner->parse_options(@ARGV);
my $model = Web->model('JobState');
async {
    warn("App scheduled");
    $runner->run($app);
};
async {
    warn("Job thing scheduled");
    $model->running(1);
};
AnyEvent->condvar->recv;

