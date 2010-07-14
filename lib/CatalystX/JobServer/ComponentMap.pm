package CatalystX::JobServer::ComponentMap;
use CatalystX::JobServer::Moose;
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

# FIX - Structured error which can be dealt with restfully
sub unpack { Carp::confess("Unsupported") }

1;

=head1 NAME

CatalystX::JobServer::ComponentMap - Map to the configured components in the application.

=head1 SYNOPSIS

    You see an instance of this class serialized when you hit L<http://localhost:5000/>.
    
    E.g.
    {
       "ComponentMap" : {
          "routing_key" : ":model:inspect:ComponentMap",
          "uri" : "http://localhost:5000/model/ComponentMap"
       },
       "FireHoseLog" : {
          "routing_key" : ":model:inspect:FireHoseLog",
          "uri" : "http://localhost:5000/model/FireHoseLog"
       },
       "MessageQueue" : {
          "routing_key" : ":model:inspect:MessageQueue",
          "uri" : "http://localhost:5000/model/MessageQueue"
       },
       "ForkedJobRunner" : {
          "routing_key" : ":model:inspect:ForkedJobRunner",
          "uri" : "http://localhost:5000/model/ForkedJobRunner"
       }
    }

=cut
