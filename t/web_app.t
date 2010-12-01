#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use HTTP::Request::Common;
use JSON qw/ decode_json /;

BEGIN { use_ok 'Catalyst::Test', 'CatalystX::JobServer::Web' }
use Catalyst::Engine::HTTP;
CatalystX::JobServer::Web->engine(Catalyst::Engine::HTTP->new);

foreach my $path (qw[ / /model/forkedjobrunner /model/componentmap /model/messagequeue ]) {
    ok( request($path)->is_success, "Request to $path should succeed" );
    my $res = request(GET($path, Accept => 'application/json' ));
    ok $res->is_success, "Request to $path as JSON should succeed";
    lives_ok { decode_json($res->content) } 'JSON decoded ok';
}

CatalystX::JobServer::Web->model('MessageQueue')->mq->close;

done_testing();
