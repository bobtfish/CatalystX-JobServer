package CatalystX::JobServer::Web::Plugin::AddRolesToComponents;
use Moose::Role;

my @roles = qw/
    MooseX::Clone
    MooseX::Storage::Basic
    CatalystX::JobServer::Role::Storage
    MooseX::Storage::Format::JSON
    Log::Message::Structured::Stringify::AsJSON
    Log::Message::Structured
/;
foreach my $role (@roles) {
    Class::MOP::load_class($role);
}

after 'setup_components' => sub {
    my $self = shift;
    foreach my $component_name (keys %{$self->components}) {
        my $component = $self->components->{$component_name};
        warn("Applying roles to instance $component");
         Moose::Util::apply_all_roles($component, 'MooseX::Storage::Basic');
        Moose::Util::apply_all_roles($component, @roles);
        warn("Got back $component and " . $component->can('stringify'));
        $component->_set_catalyst_component_name($component_name);
    }
};

1;
