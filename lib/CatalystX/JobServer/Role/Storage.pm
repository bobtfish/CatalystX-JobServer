package CatalystX::JobServer::Role::Storage;
use Moose::Role;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();

has catalyst_component_name => (
    is => 'ro',
    writer => '_set_catalyst_component_name',
);

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
