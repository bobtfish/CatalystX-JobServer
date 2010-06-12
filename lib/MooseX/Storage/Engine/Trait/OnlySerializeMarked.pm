package MooseX::Storage::Engine::Trait::OnlySerializeMarked;
use CatalystX::JobServer::Moose::Role;

around map_attributes => sub {
    my ($orig, $self, $method_name, @args) = @_;
    map {
        $self->$method_name($_, @args)
    } grep {
        # Only include our special attribute :)
        $_->does('CatalystX::JobServer::Meta::Attribute::Trait::Serialize')
    } ($self->_has_object ? $self->object : $self->class)->meta->get_all_attributes;
};

around collapse_object => sub {
    my ($orig, $self, @args) = @_;
    my $data = $self->$orig(@args);
    $data->{__CLASS__} = $self->object->catalyst_component_name
        if $self->object->can('catalyst_component_name')
            && $self->object->catalyst_component_name;
    return $data;
};

1;
