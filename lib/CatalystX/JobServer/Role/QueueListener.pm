package CatalystX::JobServer::Role::QueueListener;
use CatalystX::JobServer::Moose::Role;

sub BUILD {}
with 'Catalyst::Component::ApplicationAttribute';
after BUILD => sub {
    my ($self) = @_;
    my $mq = $self->_application->model('MQ')
};

1;
