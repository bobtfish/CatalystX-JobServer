package CatalystX::JobServer::Web::ModelBase::Adaptor;
use Moose;
use Moose::Meta::Role::Composite;
use MooseX::Clone ();
use Log::Message::Structured ();
use Log::Message::Structured::Stringify::AsJSON ();
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor::Base';
with 'CatalystX::Component::Traits' => { excludes => 'COMPONENT' };

sub mangle_arguments {
    my ($self, $args) = @_;
    return {catalyst_component_name => $self->catalyst_component_name, %$args};
}

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    Class::MOP::load_class('CatalystX::JobServer::Role::Storage');
    my $self = $class->next::method($app, @rest);

    $self->_load_adapted_class;
    my $instance = $self->_create_instance($app);

    my @traits_from_config;
    if ($self->{traits}) {
        @traits_from_config = $self->_resolve_traits(@{$self->{traits}});
    }
    my @roles = (@traits_from_config,
        qw/
            MooseX::Clone
            MooseX::Storage::Basic
            CatalystX::JobServer::Role::Storage
            MooseX::Storage::Format::JSON
            Log::Message::Structured::Stringify::AsJSON
            Log::Message::Structured
        /);
    use Data::Dumper;
    local $Data::Dumper::Maxdepth = 2;
    warn Dumper \@roles;

    warn("Applying roles to instance $instance");
    Moose::Util::apply_all_roles($instance, @roles);
    warn("Got back $instance and " . $instance->can('stringify'));
    $instance->_set_catalyst_component_name($class);
    return $instance;
};

__PACKAGE__->meta->make_immutable;
