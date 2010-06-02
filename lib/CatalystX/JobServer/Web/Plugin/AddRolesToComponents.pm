package CatalystX::JobServer::Web::Plugin::AddRolesToComponents;
use Moose::Role;

my @roles = (
    'MooseX::Clone',
    'MooseX::Storage::Basic',
    'CatalystX::JobServer::Role::Storage',
    'Log::Message::Structured::Stringify::AsJSON',
    'Log::Message::Structured' => { excludes => [qw/ freeze /]},
);
foreach my $role (@roles) {
    Class::MOP::load_class($role) unless ref $role;
}

after 'setup_components' => sub {
    my $self = shift;
    foreach my $component_name (keys %{$self->components}) {
        my $component = $self->components->{$component_name};
        $self->_apply_instance_roles($component, $component_name);
    }
};

sub _apply_instance_roles {
    my ($ctx, $component, $component_name) = @_;
    Moose::Util::apply_all_roles($component, @roles);
    $component->_set_catalyst_component_name($component_name);
}

1;
