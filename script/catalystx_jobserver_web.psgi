use strict;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use CatalystX::JobServer::Web;
use Plack::Runner;

CatalystX::JobServer::Web->setup_engine('PSGI');
my $app = sub { CatalystX::JobServer::Web->run(@_) };
my $runner = Plack::Runner->new(server => 'Corona', env => 'deployment');
$runner->parse_options(@ARGV);
$runner->run($app);


