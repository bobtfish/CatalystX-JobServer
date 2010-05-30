package CatalystX::JobServer::Web::ModelBase::Adaptor;
use Moose;
use Moose::Meta::Role::Composite;
use MooseX::Clone ();
use Log::Message::Structured ();
use Log::Message::Structured::Stringify::AsJSON ();
use namespace::autoclean;

extends 'Catalyst::Model::Adaptor::Base';
with 'CatalystX::Component::Traits' => { excludes => 'COMPONENT' };

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    my $self = $class->next::method($app, @rest);

    $self->_load_adapted_class;
    my $instance = $self->_create_instance($app);

    my @traits_from_config;
    if ($self->{traits}) {
        @traits_from_config = $self->_resolve_traits(@{$self->{traits}});
    }
    my $role = Moose::Meta::Role::Composite->new(
        roles => [
            @traits_from_config,
            map { $_->meta } qw/
                MooseX::Clone
                Log::Message::Structured
                Log::Message::Structured::Stringify::AsJSON
            /,
        ]
    );

    $role->apply($instance);

    return $instance;
};

__PACKAGE__->meta->make_immutable;
