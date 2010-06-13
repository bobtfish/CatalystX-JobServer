#!/usr/bin/env perl
use strict;
use inc::Module::Install;
use Module::Install::Catalyst;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'CatalystX-JobServer';
all_from 'lib/CatalystX/JobServer.pm';

requires 'Catalyst::Runtime' => '5.80022';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Moose';
requires 'namespace::autoclean';
requires 'YAML';
requires 'Catalyst::Engine::PSGI';
requires 'Corona' => '0.1004';
requires 'Coro';
requires 'Net::RabbitFoot';
requires 'Log::Message::Structured';
requires 'MooseX::Types::ISO8601';
requires 'MooseX::Clone';
requires 'MooseX::Types::Set::Object';
requires 'MooseX::Storage';
requires 'MooseX::Types::Structured';
requires 'MooseX::Types::Path::Class';
requires 'MooseX::Types::Common::String';
requires 'MooseX::Types';
requires 'MooseX::MethodAttributes' => '0.22';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::Component::InstancePerContext';
requires 'CatalystX::Component::Traits';
requires 'CatalystX::InjectComponent';
requires 'JSON::XS';
requires 'JSON';
requires 'JSON::Any';
requires 'aliased';
requires 'Sys::Hostname';

test_requires 'Test::More' => '0.88';

author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_tests 't/author';
catalyst;

if ($Module::Install::AUTHOR) {
    system("pod2text lib/CatalystX/JobServer.pm > README")
        and die $!;
}

install_script glob('script/*.pl');
auto_install;
WriteAll;
