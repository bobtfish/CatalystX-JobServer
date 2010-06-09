use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin qw/$Bin/;

use Module::Pluggable search_dirs => ["$Bin/../lib"], search_path => ['CatalystX::JobServer'];
use Class::MOP;

my @modules = __PACKAGE__->plugins;

ok scalar(@modules), 'Have some modules';
foreach my $module (@modules) {
    lives_ok { Class::MOP::load_class($module) } "Load $module";
    ok ! $module->can('has'), "$module is clean";
}

done_testing;
