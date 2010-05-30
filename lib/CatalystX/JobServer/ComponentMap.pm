package CatalystX::JobServer::ComponentMap;
use Moose;
use MooseX::Storage;
use MooseX::Types::Moose qw/ CodeRef HashRef /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
use namespace::autoclean;

has uri_for_model => (
    isa => CodeRef,
    is => 'ro',
    required => 1,
);

has routing_key_for_model => (
    isa => CodeRef,
    is => 'ro',
    required => 1,
);

foreach my $name (qw/ instance_queue_name instance_uri_path /) {
    has $name => (
        isa => NonEmptySimpleStr,
        is => 'ro',
        required => 1,
    );
}

with qw/
    MooseX::Clone
    CatalystX::JobServer::Role::Storage
/;

has components => (
    isa => HashRef,
    is => 'ro',
    required => 1,
);


sub pack {
    my $self = shift;
    my %data;
    foreach my $component_name (keys %{$self->components}) {
        $component_name =~ s/^CatalystX::JobServer::Web::Model:://;
        $data{$component_name} = {
            uri => $self->uri_for_model->($component_name),
            routing_key => $self->routing_key_for_model->($component_name),
        };
    }
    return \%data;
}

sub unpack { Carp::confess("Unsupported") }

1;
