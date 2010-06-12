package CatalystX::JobServer::Web::Plugin::AddRolesToComponents;
use CatalystX::JobServer::Moose::Role;

after 'setup_components' => sub {
    my $self = shift;
    foreach my $component_name (keys %{$self->components}) {
        my $component = $self->components->{$component_name};
        $self->_apply_instance_roles($component, $component_name);
    }
};

sub _apply_instance_roles {
    my ($ctx, $component, $component_name) = @_;
    Moose::Util::apply_all_roles($component =>
        'MooseX::Clone',
        'CatalystX::JobServer::Role::Storage',
    );
    $component->_set_catalyst_component_name($component_name);
}

1;
