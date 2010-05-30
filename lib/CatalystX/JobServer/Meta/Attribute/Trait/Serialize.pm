package CatalystX::JobServer::Meta::Attribute::Trait::Serialize;
use Moose::Role;

sub Moose::Meta::Attribute::Custom::Trait::Serialize::register_implementation { __PACKAGE__ }

no Moose::Role;
1;

