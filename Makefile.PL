#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'CatalystX-JobServer-Web';
all_from 'lib/CatalystX/JobServer/Web.pm';

requires 'Catalyst::Runtime' => '5.80022';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
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
requires 'MooseX::Types::Common::String';
requires 'MooseX::Types';
requires 'MooseX::MethodAttributes' => '0.22';
requires 'Catalyst::Model::Adaptor';
requires 'Catalyst::Component::InstancePerContext';
requires 'CatalystX::Component::Traits';
requires 'CatalystX::DynamicComponent';
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

install_script glob('script/*.pl');
auto_install;
WriteAll;
