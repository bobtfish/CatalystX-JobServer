package CatalystX::JobServer::Role::QueueListener;
use Moose::Role;
use namespace::autoclean;

sub BUILD {}
with 'Catalyst::Component::ApplicationAttribute';
after BUILD => {
    my ($self) = @_;
    my $mq = $self->_application->model('MQ')
}
