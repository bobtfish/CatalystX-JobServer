package CatalystX::JobServer::Web::ModelBase::Adaptor;
use CatalystX::JobServer::Moose;
use Moose::Util qw/ find_meta /;

extends 'Catalyst::Model::Adaptor::Base';
with 'CatalystX::Component::Traits' => { -excludes => 'COMPONENT' };

has '+_trait_merge' => (default => 1);

sub mangle_arguments {
    my ($self, $args) = @_;
    return {catalyst_component_name => $self->catalyst_component_name, %$args};
}

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    my $self = $class->next::method($app, @rest);

    $self->_load_adapted_class;

    if ($self->{traits}) {
        my @traits_from_config = $self->_resolve_traits(@{$self->{traits}});
        my $meta = $class->meta->create_anon_class(
            superclasses => [ find_meta($self->{class})->name ],
            roles        => \@traits_from_config,
            cache        => 1,
        );
        # Method attributes in inherited roles may have turned metaclass
        # to lies. CatalystX::Component::Traits related special move
        # to deal with this here.
        $meta = find_meta($meta->name);

        $meta->add_method('meta' => sub { $meta });
        $self->{class} = $meta->name;
    }

    return $self->_create_instance($app);
};

__PACKAGE__->meta->make_immutable;
