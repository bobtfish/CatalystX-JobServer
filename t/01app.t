#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'CatalystX::JobServer::Web' }
use Catalyst::Engine::HTTP;
CatalystX::JobServer::Web->engine(Catalyst::Engine::HTTP->new);

ok( request('/')->is_success, 'Request should succeed' );
ok( request('/model/JobState/inspect')->is_success );
ok( request('/model/ComponentMap/inspect')->is_success );
ok( request('/model/MessageQueue/inspect')->is_success );

done_testing();
