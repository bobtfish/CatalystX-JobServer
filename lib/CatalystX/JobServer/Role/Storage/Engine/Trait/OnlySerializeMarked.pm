package CatalystX::JobServer::Role::Storage::Engine::Trait::OnlySerializeMarked;
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
    my $class = do { local $@; eval { $self->object->catalyst_component_name } };
    $data->{__CLASS__} = $class if $class;
    return $data;
};

1;
