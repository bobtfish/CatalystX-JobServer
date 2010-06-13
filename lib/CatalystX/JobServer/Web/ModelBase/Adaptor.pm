package CatalystX::JobServer::Web::ModelBase::Adaptor;
use CatalystX::JobServer::Moose;
use Moose::Util qw/ find_meta /;
use MooseX::Types::Moose qw/ HashRef /;
use MooseX::Types::LoadableClass qw/LoadableClass/;

extends 'Catalyst::Model';
with 'MooseX::Traits::Pluggable' => {
    -excludes => ['new_with_traits'],
    -alias => { _build_instance_with_traits => 'build_instance_with_traits' },
};

sub _trait_namespace {
    my $class = shift->{class};
    if ($class =~ s/^CatalystX::JobServer//) {
        return 'CatalystX::JobServer::TraitFor' . $class;
    }
    return $class . '::TraitFor';
}

has class => (
    isa => LoadableClass,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has args => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

sub COMPONENT {
    my ($class, @rest) = @_;
    my $self = $class->next::method(@rest);

    $self->build_instance_with_traits($self->class, $self->args);
};

__PACKAGE__->meta->make_immutable;
