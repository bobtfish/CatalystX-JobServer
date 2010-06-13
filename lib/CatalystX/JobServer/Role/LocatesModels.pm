package CatalystX::JobServer::Role::LocatesModels;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ CodeRef /;

has model_locator_callback => (
    isa => CodeRef,
    is => 'ro',
    required => 1,
);

sub locate_model {
    my ($self, $model_name) = @_;
    $self->model_locator_callback->($model_name);
}

1;
