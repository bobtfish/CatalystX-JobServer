package CatalystX::JobServer::Role::Storage;
use Moose::Role;
use JSON::XS;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();
use namespace::autoclean;

has catalyst_component_name => (
    is => 'ro',
    writer => '_set_catalyst_component_name',
);

sub freeze {
    my $self = shift;
    JSON::XS->new->pretty(shift)->encode($self->pack);
}

around 'pack' => sub {
    my ($orig, $self, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, 'OnlySerializeMarked');
    $self->$orig(%args);
};

around 'unpack' => sub {
    my ($orig, $self, $data, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, 'OnlySerializeMarked');
    $self->$orig($data, %args);
};

1;
